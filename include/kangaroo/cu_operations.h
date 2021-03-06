#pragma once

#include <kangaroo/platform.h>
#include <kangaroo/Image.h>

namespace roo
{

template<typename T>
KANGAROO_EXPORT
void Fill(Image<T> img, T val);

template<typename Tout, typename Tin, typename Tup>
KANGAROO_EXPORT
void ElementwiseScaleBias(Image<Tout> b, const Image<Tin> a, float s, Tup offset=0);

template<typename Tout, typename Tin1, typename Tin2, typename Tup>
KANGAROO_EXPORT
void ElementwiseAdd(Image<Tout> c, Image<Tin1> a, Image<Tin2> b, Tup sa=1, Tup sb=1, Tup offset=0 );

template<typename Tout, typename Tin1, typename Tin2, typename Tup>
KANGAROO_EXPORT
void ElementwiseMultiply(Image<Tout> c, Image<Tin1> a, Image<Tin2> b, Tup scalar=1, Tup offset=0 );

template<typename Tout, typename Tin1, typename Tin2, typename Tup>
KANGAROO_EXPORT
void ElementwiseDivision(Image<Tout> c, const Image<Tin1> a, const Image<Tin2> b, Tup sa=0, Tup sb=0, Tup scalar=1, Tup offset=0);

template<typename Tout, typename Tin, typename Tup>
KANGAROO_EXPORT
void ElementwiseSquare(Image<Tout> b, const Image<Tin> a, Tup scalar=1, Tup offset=0 );

template<typename Tout, typename Tin1, typename Tin2, typename Tin3, typename Tup>
KANGAROO_EXPORT
void ElementwiseMultiplyAdd(Image<Tout> d, const Image<Tin1> a, const Image<Tin2> b, const Image<Tin3> c, Tup sab=1, Tup sc=1, Tup offset=0);

template<typename Tout, typename T>
KANGAROO_EXPORT
Tout ImageL1(Image<T> img, Image<unsigned char> scratch);

}
