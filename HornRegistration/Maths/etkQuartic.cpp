//===========================================================================
/*
    This file is part of the ATRACSYS OPEN SOURCE LIBRARY.
    Copyright (C) 2003-2004 by Atracsys sàrl. All rights reserved.

    This library is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License("GPL") version 2
    as published by the Free Software Foundation.

    For using the HornRegistration libraries with software that can not be combined
    with the GNU GPL, and for taking advantage of the additional benefits
    of our support services, please contact Atracsys about acquiring a
    Professional Edition License.

    \author:    <http://atracsys.com>
    \author:    Gaëtan Marti
    \version    1.0
    \date       08/2004
*/
//===========================================================================

/*! \file etkQuartic.cpp
    \brief  Various quartic routines.
 */

#include <math.h>
#include <stdlib.h>

#include "etkQuartic.hpp"

#pragma warn -8004

// ----------------------------------------------------------------------------
// Prototypes

void setcns(void);
double acos3(double x);
double curoot(double x);
void errors(double a, double b, double c, double d, double rts[4], double rterr[4], int nrts);
int quadratic(double b, double c, double rts[4], double dis);
double cubic(double p, double q, double r);
int descartes(double a, double b, double c, double d, double rts[4]);
int ferrari(double a, double b, double c, double d, double rts[4]);
int neumark(double a, double b, double c, double d, double rts[4]);

// ----------------------------------------------------------------------------
// Global variables

int info = 0;
double doub0;
double doub1,doub2;
double doub3,doub4;
double doub6,doub12;
double doub24;
double doubmax;       /* approx square root of max double number */
double doubmin;       /* smallest double number */
double doubtol;       /* tolerance of double numbers */
double rt3;
double inv2,inv3,inv4;
double inv64;

// ----------------------------------------------------------------------------
// Set up constants

void setcns (void)
{
      int j;

      doub0 = (double)0;
      doub1 = (double)1;
      doub2 = (double)2;
      doub3 = (double)3;
      doub4 = (double)4;
      doub6 = (double)6;
      doub12 = (double)12;
      doub24 = (double)24;
      inv2 = doub1/doub2;
      inv3 = doub1/doub3;
      inv4 = doub1/doub4;
      rt3 = sqrt(doub3) ;

      doubtol = doub1;
      for (  j = 1 ; doub1+doubtol > doub1 ; ++ j )
      {
          doubtol *= inv2;
      }
      doubtol = sqrt(doubtol);

      doubmin = inv2 ;
      double dSqVal;
      for (  j = 1 ; j <= 100 ; ++ j )
      {
          doubmin=doubmin*doubmin;
          dSqVal = doubmin*doubmin;
          if ((dSqVal) <= (dSqVal*inv2))
              break;
      }
      doubmax=doub1/sqrt(doub2*doubmin) ;

}

// ----------------------------------------------------------------------------
// find cos(acos(x)/3)
// Don Herbison-Evans   16/7/81
// called by cubic .

double acos3(double x)
{
   double value;

   value = cos(acos(x)*inv3);
   return(value);
}

// ----------------------------------------------------------------------------
// find cube root of x.
// Don Herbison-Evans   30/1/89
// called by cubic .

double curoot(double x)
{
   double value;
   double absx;
   int neg;

   neg = 0;
   absx = x;
   if (x < doub0)
   {
      absx = -x;
      neg = 1;
   }
   if (absx != doub0) value = exp( log(absx)*inv3 );
      else value = doub0;
   if (neg == 1) value = -value;
   return(value);
}

// ----------------------------------------------------------------------------
// Solve quartic equation using either
// quadratic, Ferrari's or Neumark's algorithm.
// called by
// calls  quadratic, ferrari, neumark.
// 21 Jan 1989  Don Herbison-Evans

int etkQuartic (double a, double b, double c, double d, double rts[4])
{
   int j,k,nq,nr;
   double odd, even;
   double roots[4];

   setcns();

//   if (info < 0)
//      printf("\nQuartic %g %g %g %g\n",a,b,c,d);

   if (a < doub0) odd = -a; else odd = a;
   if (c < doub0) odd -= c; else odd += c;
   if (b < doub0) even = -b; else even = b;
   if (d < doub0) even -= d; else even += d;
   if (odd < even*doubtol)
   {
//      if (info < 0) printf("    quadratic\n");
      nq = quadratic (b,d,roots,b*b-doub4*d);
      j = 0;
      for (k = 0; k < nq; ++k)
      {
         if (roots[k] > doub0)
         {
            rts[j] = sqrt(roots[k]);
            rts[j+1] = -rts[j];
            ++j; ++j;
         }
      }
      nr = j;
   }
   else
   {
      if (a < doub0) k = 1; else k = 0;
      if (b < doub0) k += k+1; else k +=k; 
      if (c < doub0) k += k+1; else k +=k; 
      if (d < doub0) k += k+1; else k +=k; 
//      if (info < 0) printf("     case %d\n",k);
      switch (k)
      {
              case 0 : nr = ferrari(a,b,c,d,rts) ; break;
              case 1 : nr = neumark(a,b,c,d,rts) ; break;
              case 2 : nr = neumark(a,b,c,d,rts) ; break;
              case 3 : nr = ferrari(a,b,c,d,rts) ; break;
              case 4 : nr = ferrari(a,b,c,d,rts) ; break;
              case 5 : nr = neumark(a,b,c,d,rts) ; break;
              case 6 : nr = ferrari(a,b,c,d,rts) ; break;
              case 7 : nr = ferrari(a,b,c,d,rts) ; break;
              case 8 : nr = neumark(a,b,c,d,rts) ; break;
              case 9 : nr = ferrari(a,b,c,d,rts) ; break;
              case 10 : nr = ferrari(a,b,c,d,rts) ; break;
              case 11 : nr = neumark(a,b,c,d,rts) ; break;
              case 12 : nr = ferrari(a,b,c,d,rts) ; break;
              case 13 : nr = ferrari(a,b,c,d,rts) ; break;
              case 14 : nr = ferrari(a,b,c,d,rts) ; break;
              case 15 : nr = ferrari(a,b,c,d,rts) ; break;
      }
   }
   return(nr);
}

// ----------------------------------------------------------------------------
// find the errors
// called by quartic.

void errors(double a, double b, double c, double d, double rts[4], double rterr[4], int nrts)
{
   int k;
   double deriv,test;

   if (nrts > 0)
   {
      for (  k = 0 ; k < nrts ; ++ k )
      {
         test = (((rts[k]+a)*rts[k]+b)*rts[k]+c)*rts[k]+d ;
         if (test == doub0) rterr[k] = doub0;
         else
         {
            deriv =
               ((doub4*rts[k]+doub3*a)*rts[k]+doub2*b)*rts[k]+c ;
            if (deriv != doub0)
               rterr[k] = fabs(test/deriv);
            else
            {
               deriv = (doub12*rts[k]+doub6*a)*rts[k]+doub2*b ;
               if (deriv != doub0)
                   rterr[k] = sqrt(fabs(test/deriv)) ;
               else
               {
                  deriv = doub24*rts[k]+doub6*a ;
                  if (deriv != doub0)
                     rterr[k] = curoot(fabs(test/deriv));
                  else
                     rterr[k] = sqrt(sqrt(fabs(test)/doub24));
               }
            }
         }
         if (rts[k] != doub0) rterr[k] /= rts[k];
         if (rterr[k] < doub0) rterr[k] = -rterr[k];
      }
   }
//   if (info < 0)
//      for (k = 0; k < nrts; ++k)
//         printf("       %d  %g %g\n",nrts,rts[k],rterr[k]);
}

// ----------------------------------------------------------------------------
// solve the quadratic equation -
//  x**2+b*x+c = 0
// called by  quartic, descartes, ferrari, neumark.

int quadratic(double b, double c, double rts[4], double dis)
{
   int nquad;
   double rtdis ;

   if (dis > doub0)
   {
      nquad = 2 ;
      rtdis = sqrt(dis) ;
      if (b > doub0) rts[0] = ( -b - rtdis)*inv2 ;
         else rts[0] = ( -b + rtdis)*inv2 ;
      if (rts[0] == doub0) rts[1] =  -b ;
      else rts[1] = c/rts[0] ;
   }
   else
   {
      nquad = 0;
      rts[0] = doub0 ;
      rts[1] = doub0 ;
   }
   return(nquad);
}

// ----------------------------------------------------------------------------

double cubic(double p, double q, double r)
/* 
     find the lowest real root of the cubic - 
       x**3 + p*x**2 + q*x + r = 0 

   input parameters - 
     p,q,r - coeffs of cubic equation. 

   output- 
     cubic - a real root. 

   global constants -
     rt3 - sqrt(3) 
     inv3 - 1/3 
     doubmax - square root of largest number held by machine 

     method - 
     see D.E. Littlewood, "A University Algebra" pp.173 - 6 

     initial version: Charles Prineas   April 1981 

     called by  neumark, descartes, ferrari.
     calls  acos3 
*/
{
   double po3,po3sq,po3cu,qo3,po3q;
   double uo3,u2o3,uo3sq4,uo3cu4 ;
   double v,vsq,wsq ;
   double m,mcube,n;
   double muo3,s,scube,t,cosk,sinsqk ;
   double root;
   
   m = doub0;
   if ((p > doubmax) || (p <  -doubmax)) root = -p;
   else
   if ((q > doubmax) || (q <  -doubmax))
   {
       if (q > doub0) root =  -r/q ;
       else
       if (q < doub0) root =  -sqrt(-q);
       else root =  doub0 ;
   }
   else
   if ((r > doubmax)|| (r <  -doubmax)) root =  -curoot(r) ;
   else
   {
      po3 = p*inv3 ;
      po3q = po3*q ;
      po3sq = po3*po3 ;
      if (po3sq > doubmax) root =  -p ;
      else
      {
         po3cu = po3*po3sq ;
         v = r + po3*(po3sq + po3sq - q) ;
         if ((v > doubmax) || (v < -doubmax)) root = -p ;
         else
         {
            vsq = v*v ;
            qo3 = q*inv3 ;
            uo3 = qo3 - po3sq ;
            u2o3 = uo3 + uo3 ;
            if ((u2o3 > doubmax) || (u2o3 < -doubmax))
            {
               if (p == doub0)
               {
                  if (q > doub0) root =  -r/q ;
		  else
                  if (q < doub0) root =  -sqrt(-q);
                  else root =  doub0 ;
               }
               else root =  -q/p ;
            }
            uo3sq4 = u2o3*u2o3 ;
            if (uo3sq4 > doubmax)
            {
               if (p == doub0)
               {
                  if (q > doub0) root = -r/q ;
                  else
		  if (q < doub0) root = -sqrt(-q) ;
		  else root = doub0;
               }
               else root = -q/p ;
            }
            uo3cu4 = uo3sq4*uo3 ;
            wsq = uo3cu4 + vsq ;
            if (wsq > doub0)
            {
/* 
     cubic has one real root 
*/
               if (v <= doub0) mcube = ( -v + sqrt(wsq))*inv2 ;
               if (v  > doub0) mcube = ( -v - sqrt(wsq))*inv2 ;
               m = curoot(mcube) ;
               if (m != doub0) n = -uo3/m ;
                  else n = doub0;
               root = m + n - po3 ;
            }
            else
            {
/* 
     cubic has three real roots 
*/
               if (uo3 < doub0)
               {
                  muo3 = -uo3;
                  if (muo3 > doub0) s = sqrt(muo3) ;
		     else s = doub0;
                  scube = s*muo3;
		  if (scube == doub0)
		  {
//		     printf("scube = 0 in cubic,for %g %g %g\n",
//			p,q,r);
                     exit(1);
		  }
                  t =  -v/(scube+scube) ;
                  cosk = acos3(t) ;
                  if (po3 < doub0)
                     root = (s+s)*cosk - po3;
                  else
                  {
                     sinsqk = doub1 - cosk*cosk ;
                     if (sinsqk > doub0)
                        root = s*( -cosk - rt3*sqrt(sinsqk)) - po3 ;
                     else root = -s*cosk - po3;
                  }
               }
               else
/* 
     cubic has multiple root -  
*/
               root = curoot(v) - po3 ;
            }
         }
      }
   }
// if (info < 0)
//    printf("   cubic %g %g %g : %g\n",p,q,r,root);
   return(root);
}

// ----------------------------------------------------------------------------

int descartes(double a, double b, double c, double d, double rts[4])
/*
   Solve quartic equation using
   Descartes-Euler-Cardano algorithm

   Strong, T. "Elemementary and Higher Algebra"
      Pratt and Oakley, p. 469 (1859)

     29 Jun 1994  Don Herbison-Evans
*/
{
   int nrts;
   int r1,r2;
   double v1[4],v2[4];
   double y;
   double p,q,r;
   double A,B,C;
   double m,n1,n2;
   double d3o8,d3o256;
   double inv8,inv16;
   double asq;
   double Ainv4;
   double Binvm;

   d3o8 = (double)3/(double)8;
   inv8 = doub1/(double)8;
   inv16 = doub1/(double)16;
   d3o256 = (double)3/(double)256;

// if (info < 0) printf("\nDescartes %g %g %g %g\n",a,b,c,d);
   asq = a*a;

   A = b - asq*d3o8;
   B = c + a*(asq*inv8 - b*inv2);
   C = d + asq*(b*inv16 - asq*d3o256) - a*c*inv4;

   p = doub2*A;
   q = A*A - doub4*C;
   r = -B*B;

   /****************
      inv64 = doub1/(double)64;
      p = doub2*b - doub3*a*a*inv4 ;
      q = b*b - a*a*b - doub4*d + doub3*a*a*a*a*inv16 + a*c;
      r = a*b*c - c*c - a*a*a*a*a*a*inv64 - a*a*b*b*inv4
          -a*a*a*c*inv4 + a*a*a*a*b*inv8;
   *****************/

   y = cubic(p,q,r) ;
   if (y <= doub0) 
      nrts = 0;
   else
   {
      m = sqrt(y);
      Ainv4 = a*inv4;
      Binvm = B/m;
      n1 = (y + A + Binvm)*inv2;
      n2 = (y + A - Binvm)*inv2;
      r1 = quadratic(-m, n1, v1, y-doub4*n1);
      r2 = quadratic( m, n2, v2, y-doub4*n2);
      rts[0] = v1[0]-Ainv4;
      rts[1] = v1[1]-Ainv4;
      rts[r1] = v2[0]-Ainv4;
      rts[r1+1] = v2[1]-Ainv4;
      nrts = r1+r2;
   } 
   return(nrts);
}

// ----------------------------------------------------------------------------

int ferrari(double a, double b, double c, double d, double rts[4])
/* 
     solve the quartic equation - 

   x**4 + a*x**3 + b*x**2 + c*x + d = 0 

   called by quartic
   calls     cubic, quadratic.

     input - 
   a,b,c,e - coeffs of equation. 

     output - 
   nquar - number of real roots. 
   rts - array of root values. 

     method :  Ferrari - Lagrange
     Theory of Equations, H.W. Turnbull p. 140 (1947)

     calls  cubic, quadratic 
*/
{
   int nquar,n1,n2 ;
   double asqinv4;
   double ainv2;
   double d4;
   double yinv2;
   double v1[4],v2[4] ;
   double p,q,r ;
   double y;
   double e,f,esq,fsq,ef ;
   double g,gg,h,hh;

// if (info < 0) printf("\nFerrari %g %g %g %g\n",a,b,c,d);
   ainv2 = a*inv2;
   asqinv4 = ainv2*ainv2;
   d4 = d*doub4;

   p = b ;
   q = a*c-d4 ;
   r = (asqinv4 - b)*d4 + c*c ;
   y = cubic(p,q,r) ;

   yinv2 = y*inv2;
   esq = asqinv4 - b - y;
   fsq = yinv2*yinv2 - d;
   if ((esq < doub0) && (fsq < doub0)) nquar = 0;
   else
   {
      ef = -(inv4*a*y + inv2*c);
//    if (info < 0) printf("   esq %g,   fsq %g,    ef %g\n",
//       esq,fsq,ef);
      if ( ((a > doub0)&&(y > doub0)&&(c > doub0))
        || ((a > doub0)&&(y < doub0)&&(c < doub0))
        || ((a < doub0)&&(y > doub0)&&(c < doub0))
        || ((a < doub0)&&(y < doub0)&&(c > doub0))
        ||  (a == doub0)||(y == doub0)||(c == doub0)
         )
/* use ef - */
         {
            if ((b < doub0)&&(y < doub0))
            {
               e = sqrt(esq);
               f = ef/e;
            }
            else if (d < doub0)
            {
               f = sqrt(fsq);
               e = ef/f;
            }
            else
            {
               if (esq > doub0) e = sqrt(esq); else e = doub0;
               if (fsq > doub0) f = sqrt(fsq); else f = doub0;
               if (ef < doub0) f = -f;
            }
         }
         else
/* use esq and fsq - */
         {
            if (esq > doub0) e = sqrt(esq); else e = doub0;
            if (fsq > doub0) f = sqrt(fsq); else f = doub0;
            if (ef < doub0) f = -f;
         }
/* note that e >= doub0 */
         g = ainv2 - e;
         gg = ainv2 + e;
         if ( ((b > doub0)&&(y > doub0))
           || ((b < doub0)&&(y < doub0)) )
         {
            if ((a > doub0) && (e > doub0)
	     || (a < doub0) && (e < doub0) ) g = (b + y)/gg;
            else
	    if ((a > doub0) && (e < doub0)
	     || (a < doub0) && (e > doub0) ) gg = (b + y)/g;
         }

         h = -yinv2 - f;
         hh = -yinv2 + f;
         if ( ((f > doub0)&&(y < doub0))
           || ((f < doub0)&&(y > doub0)) ) h = d/hh;
         else if ( ((f < doub0)&&(y < doub0))
                || ((f > doub0)&&(y > doub0)) ) hh = d/h;
//       if (info < 0)
//         printf("   hh %g,   h %g,    gg %g,   g %g\n",
//                hh,h,gg,g);
         n1 = quadratic(gg,hh,v1, gg*gg - doub4*hh) ;
         n2 = quadratic(g,h,v2, g*g - doub4*h) ;
         nquar = n1+n2 ;
         rts[0] = v1[0] ;
         rts[1] = v1[1] ;
         rts[n1+0] = v2[0] ;
         rts[n1+1] = v2[1] ;
   }
   return(nquar);
} /* ferrari */

// ----------------------------------------------------------------------------

int neumark(double a, double b, double c, double d, double rts[4])
/* 
     solve the quartic equation - 

   x**4 + a*x**3 + b*x**2 + c*x + d = 0 

   called by quartic
   calls     cubic, quadratic.

     input parameters - 
   a,b,c,e - coeffs of equation. 

     output parameters - 
   nquar - number of real roots. 
   rts - array of root values. 

     method -  S. Neumark 

     Solution of Cubic and Quartic Equations - Pergamon 1965 
        translated to C with help of Shawn Neely

*/
{
   int nquar,n1,n2 ;
   double y,g,gg,h,hh,gdis,gdisrt,hdis,hdisrt,g1,g2,h1,h2 ;
   double bmy,gerr,herr,y4,bmysq ;
   double v1[4],v2[4] ;
   double asq ;
   double d4;
   double p,q,r ;
   double hmax,gmax ;

// if (info < 0) printf("\nNeumark %g %g %g %g\n",a,b,c,d);
   asq = a*a ;
   d4 = d*doub4;

   p =  -b*doub2 ;
   q = b*b + a*c - d4 ;
   r = (c - a*b)*c + asq*d ;
   y = cubic(p,q,r) ;

   bmy = b - y ;
   y4 = y*doub4 ;
   bmysq = bmy*bmy ;
   gdis = asq - y4 ;
   hdis = bmysq - d4 ;
   if ((gdis <= doub0) || (hdis <= doub0))
      nquar = 0;
   else
   {
      g1 = a*inv2 ;
      h1 = bmy*inv2 ;
      gerr = asq + y4 ;
      herr = hdis ;
      if (d > doub0) herr = bmysq + d4 ;
      if ((y < doub0) || (herr*gdis > gerr*hdis))
      {
         gdisrt = sqrt(gdis) ;
         g2 = gdisrt*inv2 ;
         if (gdisrt != doub0) h2 = (a*h1 - c)/gdisrt ;
            else h2 = doub0;
      }
      else
      {
         hdisrt = sqrt(hdis) ;
         h2 = hdisrt*inv2 ;
         if (hdisrt != doub0) g2 = (a*h1 - c)/hdisrt ;
            else g2 = doub0;
      }
/* 
     note that in the following, the tests ensure non-zero 
     denominators -  
*/
      h = h1 - h2 ;
      hh = h1 + h2 ;
      hmax = hh ;
      if (hmax < doub0) hmax =  -hmax ;
      if (hmax < h) hmax = h ;
      if (hmax <  -h) hmax =  -h ;
      if ((h1 > doub0)&&(h2 > doub0)) h = d/hh ;
      if ((h1 < doub0)&&(h2 < doub0)) h = d/hh ;
      if ((h1 > doub0)&&(h2 < doub0)) hh = d/h ;
      if ((h1 < doub0)&&(h2 > doub0)) hh = d/h ;
      if (h > hmax) h = hmax ;
      if (h <  -hmax) h =  -hmax ;
      if (hh > hmax) hh = hmax ;
      if (hh <  -hmax) hh =  -hmax ;

      g = g1 - g2 ;
      gg = g1 + g2 ;
      gmax = gg ;
      if (gmax < doub0) gmax =  -gmax ;
      if (gmax < g) gmax = g ;
      if (gmax <  -g) gmax =  -g ;
      if ((g1 > doub0)&&(g2 > doub0)) g = y/gg ;
      if ((g1 < doub0)&&(g2 < doub0)) g = y/gg ;
      if ((g1 > doub0)&&(g2 < doub0)) gg = y/g ;
      if ((g1 < doub0)&&(g2 > doub0)) gg = y/g ;
      if (g > gmax) g = gmax ;
      if (g <  -gmax) g =  -gmax ;
      if (gg > gmax) gg = gmax ;
      if (gg <  -gmax) gg =  -gmax ;
 
      n1 = quadratic(gg,hh,v1, gg*gg - doub4*hh) ;
      n2 = quadratic(g,h,v2, g*g - doub4*h) ;
      nquar = n1+n2 ;
      rts[0] = v1[0] ;
      rts[1] = v1[1] ;
      rts[n1+0] = v2[0] ;
      rts[n1+1] = v2[1] ;
   }
   return(nquar);
} /* neumark */

// ----------------------------------------------------------------------------

