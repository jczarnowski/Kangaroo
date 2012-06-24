#include <Eigen/Eigen>
#include <pangolin/pangolin.h>
#include <pangolin/glcuda.h>

#include <cuda.h>
#include <cuda_runtime.h>
#include <cuda_gl_interop.h>

#include "RpgCameraOpen.h"
#include "kernel.h"

using namespace std;
using namespace pangolin;
using namespace Gpu;

int main( int /*argc*/, char* argv[] )
{
    // Open video device
    const std::string cam_uri =
            "AlliedVision:[NumChannels=2,CamUUID0=5004955,CamUUID1=5004954,ImageBinningX=2,ImageBinningY=2,ImageWidth=694,ImageHeight=518]//";
//            "FileReader:[DataSourceDir=/home/slovegrove/data/CityBlock-Noisy,Channel-0=left.*pgm,Channel-1=right.*pgm,StartFrame=0]//";
//            "Dvi2Pci:[NumImages=2,ImageWidth=640,ImageHeight=480,BufferCount=60]//";

    CameraDevice camera = OpenRpgCamera(cam_uri);

    // Capture first image
    std::vector<rpg::ImageWrapper> img;
    camera.Capture(img);

    // Check we received one or more images
    if(img.empty()) {
        std::cerr << "Failed to capture first image from camera" << std::endl;
        return -1;
    }

    // N cameras, each w*h in dimension, greyscale
    const int w = img[0].width();
    const int h = img[0].height();

    // Setup OpenGL Display (based on GLUT)
    pangolin::CreateGlutWindowAndBind("Main",2*w,2*h);

    // Initialise CUDA, allowing it to use OpenGL context
    cudaGLSetGLDevice(0);

    // Setup default OpenGL parameters
    glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable (GL_BLEND);
    glEnable (GL_LINE_SMOOTH);
    glPixelStorei(GL_PACK_ALIGNMENT,1);
    glPixelStorei(GL_UNPACK_ALIGNMENT,1);

    // Tell the base view to arrange its children equally
    View& screen = DisplayBase();
    screen.SetLayout(LayoutEqual);

    const int N = 4;
    for(int i=0; i<N; ++i ) {
        CreateDisplay().SetAspect((double)w/h);
    }

    // Texture we will use to display camera images
    GlTextureCudaArray tex(w,h,GL_LUMINANCE8);
    GlTextureCudaArray texrgb(w,h,GL_RGBA8);

    // Allocate Camera Images on device for processing
    Image<uchar1, TargetDevice, Manage> dCamImg[] = {{w,h},{w,h}};
    Image<uchar4, TargetDevice, Manage> d3d(w,h);

    for(unsigned long frame=0; !pangolin::ShouldQuit(); ++frame)
    {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glColor3f(1,1,1);

        camera.Capture(img);
        // Perform Processing
        {
            // Upload images to device
            for(int i=0; i<2; ++i ) {
                cudaMemcpy2D(
                    dCamImg[i].ptr, dCamImg[i].pitch,
                    img[i].Image.data, w*sizeof(uchar1), w*sizeof(uchar1),h, cudaMemcpyHostToDevice
                );
            }
//            MakeAnaglyth(d3d, dCamImg[0], dCamImg[1]);
        }

        // Perform drawing
        {
            // Draw Stereo images
            for(int i=0; i<2; ++i ) {
                screen[i].Activate();
                tex.Upload(img[i].Image.data,GL_LUMINANCE, GL_UNSIGNED_BYTE);
                tex.RenderToViewportFlipY();
            }

//            // Draw Anaglyph
//            screen[2].Activate();
//            CopyDevMemtoTex(d3d.ptr, d3d.pitch, texrgb );
//            texrgb.RenderToViewportFlipY();
        }

        pangolin::FinishGlutFrame();
    }
}