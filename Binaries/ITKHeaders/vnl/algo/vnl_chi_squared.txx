// This is core/vnl/algo/vnl_chi_squared.txx
#ifndef vnl_chi_squared_txx_
#define vnl_chi_squared_txx_
//:
// \file
// \verbatim
//  Modifications
//   24 Mar 2010  Peter Vanroose  renamed from .cxx to .txx and moved out template instantiations
// \endverbatim

#include "vnl_chi_squared.h"

//------------------------------------------------------------

// FORTRAN routine
#include <vnl/algo/vnl_netlib.h> // for dchscdf_()

template <class T>
double vnl_chi_squared_cumulative(T chisq, long dof)
{
  double cdf, chisqr = chisq;
  v3p_netlib_dchscdf_(&chisqr,&dof,&cdf);
  return cdf;
}

//------------------------------------------------------------

template <class T>
double vnl_chi_squared_statistic_1 (T const *A, T const *B, int n, bool normalize)
{
  double sum = 0;

  if (normalize)
  {
    T sumA = 0;
    T sumB = 0;
    for (int i=0; i<n; ++i) {
      sumA += A[i];
      sumB += B[i];
    }

    for (int i=0; i<n; ++i)
      if (A[i]) {
        double a = double(A[i])/sumA;
        double b = double(B[i])/sumB;
        double tmp = a - b;
        sum += tmp*tmp/a;
      }
  }
  else
  {
    for (int i=0; i<n; ++i)
      if (A[i]) {
        double tmp = A[i] - B[i];
        sum += tmp*tmp/A[i];
      }
  }

  return sum;
}

template <class T>
double vnl_chi_squared_statistic_2 (T const *A, T const *B, int n, bool normalize)
{
  return vnl_chi_squared_statistic_1(B, A, n, normalize);
}

template <class T>
double vnl_chi_squared_statistic_12(T const *A, T const *B, int n, bool normalize)
{
  double sum = 0;

  if (normalize)
  {
    T sumA = 0;
    T sumB = 0;
    for (int i=0; i<n; ++i) {
      sumA += A[i];
      sumB += B[i];
    }

    for (int i=0; i<n; ++i)
      if (A[i] || B[i]) {
        double a = double(A[i])/sumA;
        double b = double(B[i])/sumB;
        double tmp = a - b;
        sum += tmp*tmp/(a + b);
      }
  }
  else
  {
    for (int i=0; i<n; ++i)
      if (A[i] || B[i]) {
        double tmp = A[i] - B[i];
        sum += tmp*tmp/(A[i] + B[i]);
      }
  }

  return sum;
}

#undef VNL_CHI_SQUARED_INSTANTIATE
#define VNL_CHI_SQUARED_INSTANTIATE(T) \
template double vnl_chi_squared_cumulative  (T chisq, long dof); \
template double vnl_chi_squared_statistic_1 (T const *, T const *, int, bool); \
template double vnl_chi_squared_statistic_2 (T const *, T const *, int, bool); \
template double vnl_chi_squared_statistic_12(T const *, T const *, int, bool)

#endif // vnl_chi_squared_txx_
