/*
 * predictor.c --
 * 
 * Code for predictor calculation. Its macro version, predictor.h,
 * is used in non-debugging compilation.
 *
 * Copyright (c) 1994 Kongji Huang and Brian C. Smith.
 * Cornell University
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CORNELL UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF CORNELL
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * CORNELL UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND CORNELL UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

#include <stdio.h>
#include "mcu.h"

#ifdef DEBUG
/*
 *--------------------------------------------------------------
 *
 * Predict --
 *
 *      Calculate the predictor for pixel[row][col][curComp],
 *	i.e. curRowBuf[col][curComp]. It handles the all special 
 *	cases at image edges, such as first row and first column
 *	of a scan.
 *
 * Results:
 *      predictor is passed out.
 *
 * Side effects:
 *      None.
 *
 *--------------------------------------------------------------
 */
void
Predict(int row,int col,int curComp,MCU *curRowBuf,MCU *prevRowBuf,
	int Pr,int Pt,int psv,int *predictor)
    /*int row,col;		/* position of the pixel to be predicted */
    /*int curComp;		/* the pixel's component that is predicting */
    /*MCU *curRowBuf,*prevRowBuf;	/* current and previous row of image */
    /*int Pr;			/* data precision */
    /*int Pt;		 	/* point transformation */
    /*int psv;			/* predictor selection value */
    /*int *predictor;		/* preditor value (output) */
{
    register int left,upper,diag,leftcol;

    leftcol=col-1;
    if (row==0) {      

       /* 
        * The predictor of first pixel is (1<<(Pr-Pt-1), and the
        * predictors for rest of first row are left neighbors. 
        */
       if (col==0) {
          *predictor = (1<<(Pr-Pt-1));
       }
       else {
          *predictor = curRowBuf[leftcol][curComp];
       }
    }
    else {

       /*
        * The predictors of first column are upper neighbors. 
        * All other preditors are calculated according to psv. 
        */
       upper=prevRowBuf[col][curComp];
       if (col==0)
          *predictor = upper;
       else {
          left=curRowBuf[leftcol][curComp];
          diag=prevRowBuf[leftcol][curComp];
          switch (psv) {
             case 0:
                     *predictor = 0;
                     break;
             case 1:
                     *predictor = left;
                     break;
             case 2:
                     *predictor = upper;
                     break;
             case 3:
                     *predictor = diag;
                     break;
             case 4:
                     *predictor = left+upper-diag;
                     break;
             case 5:
                     *predictor = left+((upper-diag)>>1);
                     break;
             case 6:
                     *predictor = upper+((left-diag)>>1);
                     break;
             case 7:
                     *predictor = (left+upper)>>1;
                     break;
             default:
                     fprintf(stderr,"Warning: Undefined PSV\n");
                     *predictor = 0;
           }
        }
      }
}

/*
 *--------------------------------------------------------------
 *
 * QuickPredict --
 *
 *      Calculate the predictor for sample curRowBuf[col][curComp].
 *	It does not handle the special cases at image edges, such 
 *      as first row and first column of a scan. We put the special 
 *	case checkings outside so that the computations in main
 *	loop can be simpler. This has enhenced the performance
 *	significantly.
 *
 * Results:
 *      predictor is passed out.
 *
 * Side effects:
 *      None.
 *
 *--------------------------------------------------------------
 */
void
QuickPredict(int col,int curComp,MCU *curRowBuf,MCU *prevRowBuf,int psv,int *predictor)
    /*int col;			/* column # of the pixel to be predicted */
    /*int curComp;		/* the pixel's component that is predicting */
    /*MCU *curRowBuf,*prevRowBuf;	/* current and previous row of image */
    /*int psv;			/* predictor selection value */
    /*int *predictor;		/* preditor value (output) */
{
    register int left,upper,diag,leftcol;

    /* 
     * All predictor are calculated according to psv.
     */ 
    switch (psv) {
      case 0:
              *predictor = 0;
              break;
      case 1:
    	      leftcol = col-1;
    	      left    = curRowBuf[leftcol][curComp];
              *predictor = left;
              break;
      case 2:
    	      upper = prevRowBuf[col][curComp];
              *predictor = upper;
              break;
      case 3:
    	      leftcol = col-1;
    	      diag    = prevRowBuf[leftcol][curComp];
              *predictor = diag;
              break;
      case 4:
    	      leftcol = col-1;
    	      upper   = prevRowBuf[col][curComp];
    	      left    = curRowBuf[leftcol][curComp];
    	      diag    = prevRowBuf[leftcol][curComp];
              *predictor = left + upper - diag;
              break;
      case 5:
    	      leftcol = col-1;
    	      upper   = prevRowBuf[col][curComp];
    	      left    = curRowBuf[leftcol][curComp];
    	      diag    = prevRowBuf[leftcol][curComp];
              *predictor = left+((upper-diag)>>1);
              break;
      case 6:
    	      leftcol = col-1;
    	      upper   = prevRowBuf[col][curComp];
    	      left    = curRowBuf[leftcol][curComp];
    	      diag    = prevRowBuf[leftcol][curComp];
              *predictor = upper+((left-diag)>>1);
              break;
      case 7:
    	      leftcol = col-1;
    	      upper   = prevRowBuf[col][curComp];
    	      left    = curRowBuf[leftcol][curComp];
              *predictor = (left+upper)>>1;
              break;
      default:
              fprintf(stderr,"Warning: Undefined PSV\n");
              *predictor = 0;
     }
}
#endif /*DEBUG*/
