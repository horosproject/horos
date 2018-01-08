/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/
//
//  FlyAssistant.m
/*=========================================================================
 Author: Chunliang Wang (chunliang.wang@liu.se)
 
 
 Program:  FLy Through Assistant And Centerline tracking for CT endoscopy
 
 This file is part of FLy Through Assistant And Centerline tracking for CT endoscopy.
 
 Copyright (c) 2010,
 Center for Medical Image Science and Visualization (CMIV),
 Linköping University, Sweden, http://www.cmiv.liu.se/
 
 FLy Through Assistant And Centerline tracking for CT endoscopy is free software;
 you can redistribute it and/or modify it under the terms of the
 GNU General Public License as published by the Free Software 
 Foundation, either version 3 of the License, or (at your option)
 any later version.
 
 FLy Through Assistant And Centerline tracking for CT endoscopy  is distributed in
 the hope that it will be useful, but WITHOUT ANY WARRANTY; 
 without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 =========================================================================*/

#import "FlyAssistant.h"
#import "FlyAssistant+Histo.h"
#import "Quaternion.h"
#import <algorithm>
#import <functional>
#import <queue>
#import <cstdlib>
#import "Spline3D.h"

#import <dispatch/dispatch.h> //need OSX 10.6 sdk

#define SLICES1BLOCK 32
#define CROSSECTIONIMSIZE 64
#define	OPTIMIZED 0x80
#define LABELOFPOINTA	0x20
#define LABELOFPOINTB   0x40
#define LABELBITSMASK   0x60
#define DIRECTIONBITSMASK   0x1f
#define DIRECTIONTOSELF 13 //0-26 represent the 26 neighbor's direction. 13 is the one in the middle

@implementation FlyAssistant

@synthesize centerlineResampleStepLength;

- (id) initWithVolume:(float*)data WidthDimension:(int*)dim Spacing:(float*)spacing ResampleVoxelSize:(float)vsize
{
	self = [super init];
	input = data;
	inputWidth = dim[0];
	inputHeight = dim[1];
	inputDepth = dim[2];

    inputImageSize = inputWidth * inputHeight;
    inputVolumeSize = inputWidth * inputHeight * inputDepth;
	
	inputSpacing_x = spacing[0];
	inputSpacing_y = spacing[1];
	inputSpacing_z = spacing[2];

    /**
     * Get input image range and compute histogram.
     */
    [self determineImageRange];
    [self computeHistogram];
    [self smoothHistogramWith:5]; // \todo{Trouver une meilleure définition ?}
	
	int err = [self setResampleVoxelSize:vsize];
	if (err) {
		[self autorelease];
		return nil;
	}
	csmap=(float*)malloc(CROSSECTIONIMSIZE*CROSSECTIONIMSIZE*sizeof(float));
	if (csmap == nil) {
		[self autorelease];
		return nil;
	}
    
	return self;
}
- (void) dealloc {
	if(distmap)
		free(distmap);
	if( csmap)
		free(csmap);
    if (inputHisto)
        free(inputHisto);
	[super dealloc];
}
- (int) setResampleVoxelSize:(float)vsize
{
	resampleVoxelSize =  vsize;
	if (distmap) {
		free(distmap);
		distmap=0;
	}
	distmapWidth = (float)inputWidth*inputSpacing_x/vsize;
	distmapHeight = (float)inputHeight*inputSpacing_y/vsize;
	distmapDepth = (float)inputDepth*inputSpacing_z/vsize;
	
	resampleScale_x = (float)distmapWidth/(float)inputWidth;
	resampleScale_y = (float)distmapHeight/(float)inputHeight;
	resampleScale_z = (float)distmapDepth/(float)inputDepth;
	
	distmapImageSize=distmapWidth*distmapHeight;
	distmapVolumeSize=distmapWidth*distmapHeight*distmapDepth;
	distmap=(float*)malloc(distmapVolumeSize*sizeof(float));
	if(!distmap)
	{
		NSLog( @"no enough memory for distance map");
		return ERROR_NOENOUGHMEM;
	}
	return 0;
}
- (void) setThreshold:(float)thres Asynchronous:(BOOL)async
{
	threshold = thres;
	if (async) {
		[NSThread detachNewThreadSelector: @selector(distanceTransformWithThreshold:) toTarget: self withObject: nil];
	}
	else {
		[self distanceTransformWithThreshold:nil];
	}

	
	
}
- (void) converPoint2ResampleCoordinate:(Point3D*)pt
{
	pt.x *= resampleScale_x;
	pt.y *= resampleScale_y;
	pt.z *= resampleScale_z;
}
- (void) converPoint2InputCoordinate:(Point3D*)pt
{
	pt.x /= resampleScale_x;
	pt.y /= resampleScale_y;
	pt.z /= resampleScale_z;
}
- (void) thresholdImage
{
	int inputx,inputy,inputz;
	
    vImage_Buffer buffer;
    buffer.data = distmap;
    buffer.width = distmapImageSize;
    buffer.height = distmapDepth;
    buffer.rowBytes = distmapImageSize * sizeof(float);
    
	for (unsigned int z=0; z<distmapDepth; z++) {
		for (unsigned int y=0; y<distmapHeight; y++) {
			for (unsigned int x=0; x<distmapWidth; x++) {
				inputx = x/resampleScale_x;
				inputy = y/resampleScale_y;
				inputz = z/resampleScale_z;
                float inValue = -MAXFLOAT;
                for (unsigned int i = inputx; i <= inputx+1; ++i) {
                    for (unsigned int j = inputy; j <= inputy+1; ++j) {
                        for (unsigned int k = inputz; k <= inputz+1; ++k)
                        {
                            if( k < inputDepth && j < inputHeight && i < inputWidth)
                            {
                                if (inValue < input[k*inputImageSize+j*inputWidth+i])
                                    inValue = input[k*inputImageSize+j*inputWidth+i];
                            }
                        }
                    }
                }
//                float inValue = resizedInput[z*distmapImageSize+y*distmapWidth+x];
//                float inValue = input[inputz*inputImageSize+inputy*inputWidth+inputx];
                if (inValue > thresholdB || inValue < thresholdA) {
					distmap[z*distmapImageSize+y*distmapWidth+x]=0;
				}
				else {
					distmap[z*distmapImageSize+y*distmapWidth+x]=3.4e+38;
				}
			}
		}
	}
    
    // Close thresholded image:
    // - small areas of value 0 become 3.4e+38 (i.e. background becomes object)
    // Close on each slice
    buffer.height = distmapHeight;
    buffer.width = distmapWidth;
    buffer.rowBytes = distmapWidth * sizeof(float);
    for (unsigned int i = 0; i < distmapDepth; ++i) {
        buffer.data = &distmap[i*distmapImageSize];
        [self mmClosing:&buffer:3:3];
        memcpy(&distmap[i*distmapImageSize], buffer.data, buffer.rowBytes*distmapHeight);
    }

    // Close along the depth axis
    buffer.data = distmap;
    buffer.height = distmapImageSize;
    buffer.width = distmapDepth;
    buffer.rowBytes = distmapDepth * sizeof(float);
    [self mmClosing:&buffer:1:3];
    distmap = (float *)buffer.data;
}

- (void) distanceTransformWithThreshold: (id) sender
{
	
	if(	!distmap )
		return; // todo{l'allouer à la place ?}    

    [self thresholdImage];
//    CFAbsoluteTime time = CFAbsoluteTimeGetCurrent ();
	int its=0;
	
//need OSX 10.6 sdk
    /**
      Multithreaded distance transform.
     \todo{Improve the structuring element.
            Pour la passe aller :
            for (z = -1; z <= 0; ++z)
                for (y = -1; y <= -z; ++y)
                    for (x = -1; x <= -min(y,z); ++x)
            Pour la passe retour :
                for (z = 0; z <= 1; ++z)
                    for (y = -z; y <= 1; ++y)
                        for (x = -max(y,z); x <= 1; ++x)
     }
     */
	__block int changedpoints=1;
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	
	while (changedpoints>0) {
		its++;
		changedpoints=0;
		dispatch_apply(distmapDepth/SLICES1BLOCK, queue, ^(size_t j) {
            float deltamt[4]={0,1,1.414213,1.73205};
			int starti,endi;
			starti=j*SLICES1BLOCK;
			endi=starti+SLICES1BLOCK;
			if (starti==0) {
				starti=1;
			}
			if (endi>=distmapDepth-1) {
				endi=distmapDepth-1;
			}
			int x,y,z;
			int dx,dy,dz;
			for (z=starti; z<endi; z++) {
				for (y=1; y<distmapHeight-1; y++) {
					for (x=1; x<distmapWidth-1; x++) {
						int changed=0;
						float currentdist= distmap[z*distmapImageSize+y*distmapWidth+x];
						if (currentdist>0) {
							float newdist;
							for (dz=-1; dz<=1; dz++) {
								for (dy=-1; dy<=1; dy++) {
									for (dx=-1; dx<=1; dx++) {
										//int di=abs(dx)+abs(dy)+abs(dz);
										newdist=distmap[(z+dz)*distmapImageSize+(y+dy)*distmapWidth+x+dx]+deltamt[abs(dx)+abs(dy)+abs(dz)];
										if(newdist<currentdist)
										{
											currentdist=newdist;
											changed=1;
										}
									}
								}
                                if (changed) {
                                    distmap[z*distmapImageSize+y*distmapWidth+x]=currentdist;
                                    changedpoints++;
                                }
                            }
                        }
                    }
                }
            }
        });
//		printf("changed pionts: %d",changedpoints);
		if (changedpoints==0) {
			break;
		}
		dispatch_apply(distmapDepth/SLICES1BLOCK, queue, ^(size_t j) {
            float deltamt[4]={0,1,1.414213,1.73205};
			int starti,endi;
			starti=j*SLICES1BLOCK;
			endi=starti+SLICES1BLOCK;
			
			if (endi>=distmapDepth-1) {
				endi=distmapDepth-2;
			}
			
			int x,y,z;
			int dx,dy,dz;
			for (z=endi; z>starti; z--) {
				for (y=distmapHeight-2; y>0; y--) {
					for (x=distmapWidth-2; x>0; x--) {
						int changed=0;
						float currentdist= distmap[z*distmapImageSize+y*distmapWidth+x];
						if (currentdist>0) {
							float newdist;
							for (dz=-1; dz<=1; dz++) {
								for (dy=-1; dy<=1; dy++) {
									for (dx=-1; dx<=1; dx++) {
										newdist=distmap[(z+dz)*distmapImageSize+(y+dy)*distmapWidth+x+dx]+deltamt[abs(dx)+abs(dy)+abs(dz)];
										if(newdist<currentdist)
										{
											currentdist=newdist;
											changed=1;
										}
									}
								}
							}
							if (changed) {
								distmap[z*distmapImageSize+y*distmapWidth+x]=currentdist;
								changedpoints++;
                            }
                        }
					}
				}
			}			
		});
//		printf("changed pionts: %d\n",changedpoints);
		
	}
//    unsigned int nbdiff = 0;
//    float diff = 0;
//    std::ofstream file;
//    file.open("/Users/bd/diff.txt");
//    for (unsigned int i = 0; i < distmapVolumeSize; ++i) {
//        if (distmap2[i] != distmap[i]) {
//            ++nbdiff;
//            file << (i%distmapImageSize)%distmapWidth << " " << (i%distmapImageSize)/distmapWidth << " " << i / distmapImageSize << " " << distmap[i] << " " << distmap2[i] << std::endl;
//        }
//    }
//    file.close();
//    NSLog(@"NbDiffs = %d", nbdiff);
//    NSLog(@"NbDiffs = %f", diff / nbdiff);
    
    
//		//single thread
//		int changedpoints=1;
//
//		int dx,dy,dz;
////		while (changedpoints>0) {
//			its++;
//			changedpoints=0;
//			for (z=1; z<distmapDepth-1; z++) {
//				for (y=1; y<distmapHeight-1; y++) {
//					for (x=1; x<distmapWidth-1; x++) {
//						int changed=0;
//						float currentdist= distmap[z*distmapImageSize+y*distmapWidth+x];
//						if (currentdist>0) {
//							float newdist;
//							for (dz=-1; dz<=1; dz++) {
//								for (dy=-1; dy<=1; dy++) {
//									for (dx=-1; dx<=1; dx++) {
//										//int di=abs(dx)+abs(dy)+abs(dz);
//										newdist=distmap[(z+dz)*distmapImageSize+(y+dy)*distmapWidth+x+dx]+delta[abs(dx)+abs(dy)+abs(dz)];
//										if(newdist<currentdist)
//										{
//											currentdist=newdist;
//											changed=1;
//										}
//									}
//								}
//							}
//							//if (changed) {
//								distmap[z*distmapImageSize+y*distmapWidth+x]=currentdist;
//							//	changedpoints++;
//							//}
//							
//						}
//											
//						
//					}
//				}
//			}
//			if (changedpoints==0) {
//				break;
//			}
//			for (z=distmapDepth-2; z>0; z--) {
//				for (y=distmapHeight-2; y>0; y--) {
//					for (x=distmapWidth-2; x>0; x--) {
//						int changed=0;
//						float currentdist= distmap[z*distmapImageSize+y*distmapWidth+x];
//						if (currentdist>0) {
//							float newdist;
//							for (dz=-1; dz<=1; dz++) {
//								for (dy=-1; dy<=1; dy++) {
//									for (dx=-1; dx<=1; dx++) {
//										newdist=distmap[(z+dz)*distmapImageSize+(y+dy)*distmapWidth+x+dx]+delta[abs(dx)+abs(dy)+abs(dz)];
//										if(newdist<currentdist)
//										{
//											currentdist=newdist;
//											changed=1;
//										}
//									}
//								}
//							}
//							//if (changed) {
//								distmap[z*distmapImageSize+y*distmapWidth+x]=currentdist;
//							//	changedpoints++;
//							//}
//							
//						}
//						
//						
//					}
//				}
//			}
//			printf("changed pionts: %d\n",changedpoints);
//		}
	
//	printf("interation: %d\n",its);

    isDistanceTransformFinished = YES;
}
- (int) calculateSampleMetric:(float) a :(float) b :(float) c
{
	int err=0;
	if (a*b*c==0) {
		if (a==0&&b==0&&c==0) {
			err=1;
		}
		else if (a==0 && b==0){
			sampleMetric[0][0]=1;
			sampleMetric[0][1]=0;
			sampleMetric[0][2]=0;
			
			sampleMetric[1][0]=0;
			sampleMetric[1][1]=1;
			sampleMetric[1][2]=0;
		}
		else if (b==0 && c==0) {
			sampleMetric[0][0]=0;
			sampleMetric[0][1]=1;
			sampleMetric[0][2]=0;
			
			sampleMetric[1][0]=0;
			sampleMetric[1][1]=0;
			sampleMetric[1][2]=1;
		}
		else if (a==0 && c==0) {
			sampleMetric[0][0]=1;
			sampleMetric[0][1]=0;
			sampleMetric[0][2]=0;
			
			sampleMetric[1][0]=0;
			sampleMetric[1][1]=0;
			sampleMetric[1][2]=1;
		}
		else if (a==0) {
			sampleMetric[0][0]=1;
			sampleMetric[0][1]=0;
			sampleMetric[0][2]=0;
			
			sampleMetric[1][0]=0;
			sampleMetric[1][1]=c/sqrt(b*b+c*c);
			sampleMetric[1][2]=-b/sqrt(b*b+c*c);
		}
		else if (b==0) {
			sampleMetric[0][0]=0;
			sampleMetric[0][1]=1;
			sampleMetric[0][2]=0;
			
			sampleMetric[1][0]=c/sqrt(a*a+c*c);
			sampleMetric[1][1]=0;
			sampleMetric[1][2]=-a/sqrt(a*a+c*c);
		}
		else if (c==0) {
			sampleMetric[0][0]=0;
			sampleMetric[0][1]=0;
			sampleMetric[0][2]=1;
			
			sampleMetric[1][0]=b/sqrt(b*b+a*a);
			sampleMetric[1][1]=-a/sqrt(b*b+a*a);
			sampleMetric[1][2]=0;
		}
		
		
	}
	else {
		float x,y,z;
		//a*x+b*y+c*z=0
		z=0;
		y=1;
		x=-b*y/a;
		sampleMetric[0][0]=x/sqrt(x*x+y*y);
		sampleMetric[0][1]=y/sqrt(x*x+y*y);
		sampleMetric[0][2]=z;
		
		float e,f,g;
		e=x;f=y;g=z;
		
		//a*x+b*y+c*z=0 and e*x+f*y+g*z=0
		z=-1;
		x=(c*f-g*b)/(f*a-b*e);
		y=(c*e-a*g)/(b*e-f*a);
		
		sampleMetric[1][0]=x/sqrt(x*x+y*y+1);
		sampleMetric[1][1]=y/sqrt(x*x+y*y+1);
		sampleMetric[1][2]=z/sqrt(x*x+y*y+1);
		
	}
	
	return err;
	
}

-(int) resamplecrosssection:(Point3D*) pt : (Point3D*) dir :(float) steplength
{
	int err=[self calculateSampleMetric:dir.x :dir.y :dir.z];
	if (err) {
		return err;
	}
	int i,j;
	float a=dir.x,b=dir.y,c=dir.z;
	float centerx,centery,centerz;
	centerx = pt.x + steplength * a / sqrt( a*a + b*b + c*c );
	centery = pt.y + steplength * b / sqrt( a*a + b*b + c*c );
	centerz = pt.z + steplength * c / sqrt( a*a + b*b + c*c );
	
	for (i = 0; i < CROSSECTIONIMSIZE; i++) {
		for (j = 0; j < CROSSECTIONIMSIZE; j++) {
			
			float x, y, z;
			x = centerx + (i - CROSSECTIONIMSIZE/2) *  sampleMetric[0][0] + (j - CROSSECTIONIMSIZE/2) * sampleMetric[1][0];
			y = centery + (i - CROSSECTIONIMSIZE/2) *  sampleMetric[0][1] + (j - CROSSECTIONIMSIZE/2) * sampleMetric[1][1];
			z = centerz + (i - CROSSECTIONIMSIZE/2) *  sampleMetric[0][2] + (j - CROSSECTIONIMSIZE/2) * sampleMetric[1][2];
			
			if(x>=0 && x<distmapWidth && y>=0 && y<distmapHeight && z>=0 && z<distmapDepth)
				csmap[i*CROSSECTIONIMSIZE+j]=distmap[(int)z*distmapImageSize+(int)y*distmapWidth+(int)x];
			else {
				csmap[i*CROSSECTIONIMSIZE+j]=0;
			}
			
			
		}
	}
	return 0;
}

- (int) caculateNextPositionFrom: (Point3D*) pt Towards:(Point3D*)dir;

{	

	if(	!distmap )
		return ERROR_NOENOUGHMEM;
	//convert to resampled coordinate
	[self converPoint2ResampleCoordinate:pt];
	[self converPoint2ResampleCoordinate:dir];
	if (!isDistanceTransformFinished) {
        //		return ERROR_DISTTRANSNOTFINISH;
        float pixVal = 0;
        long maxData = inputWidth*inputHeight*inputDepth;
        long pos = (int)pt.z*inputWidth*inputHeight+(int)pt.y*inputWidth+(int)pt.x;
        
        for (int i = -1; i < 2; ++i) {
            for (int j = -1; j < 2; ++j) {
                for (int k = -1; k < 2; ++k) {
                    pos += (k * inputWidth * inputHeight + j * inputWidth + i);
                    
                    if( pos >= 0 && pos < maxData)
                        pixVal += input[pos];
                }
            }
        }
        pixVal /= 27;
        [self computeIntervalThresholdsFrom:pixVal];
        [self distanceTransformWithThreshold:nil];        
	}
	
	//cacluate next step
	Point3D* newpos;
	Point3D* newdir = [Point3D point];
	float steplen;
	Point3D* currentcenter = [self caculateNextCenterPointFrom:pt Towards:dir WithStepLength:0];
	if (!currentcenter) {
		currentcenter=pt;
	}
	steplen = distmap[(int)currentcenter.z*distmapImageSize+(int)currentcenter.y*distmapWidth+(int)currentcenter.x];

	float x,y,z;
	x = 0; y = 0; z = 0;
	
	int i;
	for(i=0;i<20;i++)
	{
		Point3D* nextcenter = [self caculateNextCenterPointFrom:pt Towards:dir WithStepLength:steplen+steplen*0.1*i];
		if (!nextcenter) {
			break;
		}
		newdir.x = nextcenter.x - currentcenter.x; 
		newdir.y = nextcenter.y - currentcenter.y;
		newdir.z = nextcenter.z - currentcenter.z;
		float len = sqrt(newdir.x*newdir.x + newdir.y*newdir.y + newdir.z*newdir.z);
		if (len < 1.0e-5) {
			continue;
		}
		x += newdir.x/len;
		y += newdir.y/len;
		z += newdir.z/len;

		
	}
	if (i<10) {
//		printf("turning \n");
		i=0;
		newpos = [Point3D point];
		newpos.x = pt.x;
		newpos.y = pt.y;
		newpos.z = pt.z;
		newdir.x = dir.x;
		newdir.y = dir.y;
		newdir.z = dir.z;
		x = 0;
		y = 0;
		z = 0;
	}


	for (; i<10; i++) {

		Point3D* nextcenter = [self caculateNextCenterPointFrom:newpos Towards:newdir WithStepLength:steplen];
		if (!nextcenter) {
			break;
		}
		newdir.x = nextcenter.x - newpos.x; 
		newdir.y = nextcenter.y - newpos.y;
		newdir.z = nextcenter.z - newpos.z;
		newpos.x = newpos.x + (nextcenter.x-newpos.x)*0.1;
		newpos.y = newpos.y + (nextcenter.y-newpos.y)*0.1;
		newpos.z = newpos.z + (nextcenter.z-newpos.z)*0.1;
		float len = sqrt(newdir.x*newdir.x + newdir.y*newdir.y + newdir.z*newdir.z);
		if (len < 1.0e-5) {
			continue;
		}
		x += newdir.x/len;
		y += newdir.y/len;
		z += newdir.z/len;
		
	}
//	x = x/i + dir.x*0.5;
//	y = y/i + dir.y*0.5;
//	z = z/i + dir.z*0.5;



	

	newpos = [self caculateNextCenterPointFrom:pt Towards:dir WithStepLength:steplen];
	if (!newpos) {
		return ERROR_CANNOTFINDPATH;
	}
	pt.x = pt.x + (newpos.x-pt.x)*0.5;
	pt.y = pt.y + (newpos.y-pt.y)*0.5;
	pt.z = pt.z + (newpos.z-pt.z)*0.5;	

	float len = sqrt(x*x + y*y + z*z);
	dir.x = x/len;
	dir.y = y/len;
	dir.z = z/len;
	

	[self converPoint2InputCoordinate:pt];
	[self converPoint2InputCoordinate:dir];
	
	
	return 0;
	
//	newdir.x = newpos.x - pt.x; newdir.y = newpos.y - pt.y; newdir.z = newpos.z - pt.z;
//	//[newpos release];
//	
//	int i;
//	float x=0,y=0,z=0;
//	float steplen=sqrt((newpos.x-pt.x)*(newpos.x-pt.x) + (newpos.y-pt.y)*(newpos.y-pt.y) + (newpos.z-pt.z)*(newpos.z-pt.z));
//	steplen=steplen*4;
//	
//	if (steplen < 1.0e-6)
//		return;
//	for(i=0;i<5;i++)
//	{
//		
//		float len = sqrt(newdir.x*newdir.x + newdir.y*newdir.y + newdir.z*newdir.z);
//		if (len < 1.0e-6)
//			continue;
//		x += newdir.x/len;
//		y += newdir.y/len;
//		z += newdir.z/len;
//		
//		pt.x = newpos.x; pt.y = newpos.y; pt.z = newpos.z; 
//		
//		newpos = [assistant caculateNextPositionFrom:pt Towards:newdir];
//		//[newpos retain];
//		newdir.x = newpos.x - pt.x; newdir.y = newpos.y - pt.y; newdir.z = newpos.z - pt.z;
//		//[newpos release];
//	}
//	
//	
//	newdir.x = cpos.x + x*6;
//	newdir.y = cpos.y + y*6;
//	newdir.z = cpos.z + z*6;
	
	
}
- (Point3D*) caculateNextCenterPointFrom: (Point3D*) pt Towards:(Point3D*)dir WithStepLength:(float)steplen
{
	if(	!distmap )
		return nil;
	
	int err=[self resamplecrosssection:pt :dir :steplen];
	if (err) {
		return nil;
	}
	int localmax=0;
	int centerx=CROSSECTIONIMSIZE/2,centery=CROSSECTIONIMSIZE/2;
	int dx,dy,max_x,max_y;
	float max_v;
	while (localmax==0) {
		max_v=csmap[centery*CROSSECTIONIMSIZE+centerx];
		max_x=centerx;
		max_y=centery;
		for (dx=-1; dx<2; dx++) {
			for (dy=-1; dy<2; dy++) {
				if(dx+centerx>=0&&dx+centerx<CROSSECTIONIMSIZE&&dy+centery>=0&&dy+centery<CROSSECTIONIMSIZE)
				{
					if (max_v<csmap[(centery+dy)*CROSSECTIONIMSIZE+centerx+dx]) {
						max_v=csmap[(centery+dy)*CROSSECTIONIMSIZE+centerx+dx];
						max_x = centerx + dx;
						max_y = centery + dy;
					}
				}
			}
		}
		if(centerx==max_x&&centery==max_y)
		{
			localmax=1;
		}
		else {
			centerx=max_x;
			centery=max_y;
		}
		
	}
	float x,y,z;
	x = pt.x + steplen * dir.x / sqrt( dir.x*dir.x + dir.y*dir.y + dir.z*dir.z );
	y = pt.y + steplen * dir.y / sqrt( dir.x*dir.x + dir.y*dir.y + dir.z*dir.z );
	z = pt.z + steplen * dir.z / sqrt( dir.x*dir.x + dir.y*dir.y + dir.z*dir.z );
	
	x = x + (centery - CROSSECTIONIMSIZE/2) *  sampleMetric[0][0] + (centerx - CROSSECTIONIMSIZE/2) * sampleMetric[1][0];
	y = y + (centery - CROSSECTIONIMSIZE/2) *  sampleMetric[0][1] + (centerx - CROSSECTIONIMSIZE/2) * sampleMetric[1][1];
	z = z + (centery - CROSSECTIONIMSIZE/2) *  sampleMetric[0][2] + (centerx - CROSSECTIONIMSIZE/2) * sampleMetric[1][2]; 
	
	if (max_v<1.0) {
		//printf("out of border!\n");
		err=ERROR_CANNOTFINDPATH;
		return nil;
	}

	
	
//	distmap[(int)pt.z*distmapImageSize+(int)pt.y*distmapWidth+(int)pt.x]=255;
//	
//	distmap[(int)z*distmapImageSize+(int)y*distmapWidth+(int)x]=255;
//	csmap[centery*CROSSECTIONIMSIZE+centerx]=0;
	
//	printf("next point: %f %f %f",x,y,z);
	Point3D* newpt = [Point3D point];
//	newpt.x = pt.x + (x-pt.x)/4;
//	newpt.y = pt.y + (y-pt.y)/4;
//	newpt.z = pt.z + (z-pt.z)/4;
//	dir.x = x-pt.x;
//	dir.y = y-pt.y;
//	dir.z = z-pt.z;
	newpt.x = x;
	newpt.y = y;
	newpt.z = z;
	return newpt;
}
struct PathNode
{
	int index;
	float cost;
};

class GreaterPathNodeOnF
{
public:
	
	bool operator()(const PathNode& node1, const PathNode& node2)
	{
		return node1.cost > node2.cost;
	}
	
};

typedef std::vector<PathNode> PathContainer;
typedef GreaterPathNodeOnF NodeCompare;

- (int) createCenterline:(NSMutableArray*)centerline FromPointA:(Point3D*)pta ToPointB:(Point3D*)ptb withSmoothing:(BOOL)smoothFlag;
{
	float* costmap=(float*)malloc(distmapVolumeSize*sizeof(float));
	if(!costmap)
	{
		NSLog( @"no enough memory");
		return ERROR_NOENOUGHMEM;
	}
    
    if( pta.z < 0)
        pta.z = 0;
    if( pta.y < 0)
        pta.y = 0;
    if( pta.x < 0)
        pta.x = 0;
    
    if( pta.z >= inputDepth)
        pta.z = inputDepth-1;
    if( pta.y >= inputHeight)
        pta.y = inputHeight-1;
    if( pta.x >= inputWidth)
        pta.x = inputWidth-1;
    
    if( ptb.z < 0)
        ptb.z = 0;
    if( ptb.y < 0)
        ptb.y = 0;
    if( ptb.x < 0)
        ptb.x = 0;
    
    if( ptb.z >= inputDepth)
        ptb.z = inputDepth-1;
    if( ptb.y >= inputHeight)
        ptb.y = inputHeight-1;
    if( ptb.x >= inputWidth)
        ptb.x = inputWidth-1;
    
    // check that origin != destination
    if (pta.x == ptb.x &&
        pta.y == ptb.y &&
        pta.z == ptb.z )
    {
        NSLog(@"Can not define path from point to itself.");
        return ERROR_CANNOTFINDPATH;
    }
    
    std::cout   << "x= " << pta.x << " y= " << pta.y <<  " z= " << pta.z << std::endl
                << "x= " << ptb.x << " y= " << ptb.y <<  " z= " << ptb.z << std::endl;

    // get the boundaries for threshold
    int posA = (int)pta.z*inputWidth*inputHeight+(int)pta.y*inputWidth+(int)pta.x,
        posB = (int)ptb.z*inputWidth*inputHeight+(int)ptb.y*inputWidth+(int)ptb.x;
    float pixVal = 0;
    for (int i = -1; i < 2; ++i) {
        for (int j = -1; j < 2; ++j) {
            for (int k = -1; k < 2; ++k) {
                posA += (k * inputWidth * inputHeight + j * inputWidth + i);
                posB += (k * inputWidth * inputHeight + j * inputWidth + i);
                pixVal += input[posA]; 
                pixVal += input[posB];
            }
        }
    }
    pixVal /= 54;
    [self computeIntervalThresholdsFrom:pixVal];
    NSLog(@"Opt. thresholds from %f : Min = %f / Max = %f", pixVal, thresholdA, thresholdB);
    [self distanceTransformWithThreshold:nil];
	
	unsigned char* labelmap=(unsigned char*)malloc(distmapVolumeSize*sizeof(char));
	if(!labelmap)
	{
		free(costmap);
		return ERROR_NOENOUGHMEM;
	}
	if (!isDistanceTransformFinished) {
		free(costmap);
		free(labelmap);
		return ERROR_DISTTRANSNOTFINISH;
	}
	[self converPoint2ResampleCoordinate:pta];
	[self converPoint2ResampleCoordinate:ptb];
	int i;
	//initializing
	for (i=0; i<distmapVolumeSize; i++) {
		costmap[i]=3.4e+38;
	}
	for (i=0; i<distmapVolumeSize; i++) {
		if (distmap[i]>0) {
			labelmap[i]=0;
		}
		else {
			labelmap[i]=OPTIMIZED;
		}

	}
	memset(labelmap,0,distmapVolumeSize*sizeof(char));
	std::priority_queue<PathNode, PathContainer, NodeCompare> priorityQ;
	//plant seed
	int x,y,z,dx,dy,dz;
	int currentindex,neighborindex;
	BOOL ifThe2PointsMeet=NO;
	float currentcost,newcost;
	char currentlabel;
	unsigned char currentdirection;	
	for (i=0; i<2; i++) {
		if(i==0){
			x=pta.x; y=pta.y; z=pta.z;
			currentlabel=LABELOFPOINTA;
		}
		else {
			x=ptb.x; y=ptb.y; z=ptb.z;
			currentlabel=LABELOFPOINTB;
		}
        
		currentindex = z*distmapImageSize + y*distmapWidth + x;
        
        if( currentindex >= distmapVolumeSize)
        {
            NSLog( @"***** currentindex >= distmapVolumeSize");
            free(costmap);
            free(labelmap);
            
            return ERROR_DISTTRANSNOTFINISH;
        }
        
		currentcost=0;
		costmap[currentindex]=0;
		labelmap[currentindex]=OPTIMIZED|currentlabel|DIRECTIONTOSELF;//13 is the direction that pointing to itself
		for (dz=-1; dz<=1; dz++) {
			for (dy=-1; dy<=1; dy++) {
				for (dx=-1; dx<=1; dx++) {
					neighborindex = (z+dz)*distmapImageSize + (y+dy)*distmapWidth + (x+dx);
					
                    if( neighborindex < distmapVolumeSize && neighborindex >= 0)
                    {
                        if (!(labelmap[neighborindex]&OPTIMIZED))
                        {
                            newcost = currentcost + [self stepCostFrom:currentindex To:neighborindex];
                            if (newcost < costmap[neighborindex]) {
                                costmap[neighborindex] = newcost;
                                currentdirection=(-dz+1)*9+(-dy+1)*3-dx+1;
                                labelmap[neighborindex] = currentlabel|currentdirection;
                                PathNode aneighbor;
                                aneighbor.index = neighborindex;
                                aneighbor.cost = newcost;
                                priorityQ.push(aneighbor);
                            }
                        }
					}
				}
			}
		}
		
	}
	int jointPointA,jointPointB;
	while (!priorityQ.empty() && ifThe2PointsMeet==NO) {
		currentindex = priorityQ.top().index;
		priorityQ.pop();
		
		//because our piority queue can not be modified, there will be multiple copies of one point in the queue, just ignore the rest when the point is already optimized
//		* Possible Improvements:
//		* In the current implemenation, std::priority_queue only allows 
//		* taking nodes out from the front and putting nodes in from the back.
//		* To update a value already on the heap, a new node is added to the heap.
//		* The defunct old node is left on the heap. When it is removed from the
//		* top, it will be recognized as invalid and not used.
//		* Future implementations can implement the heap in a different way
//		* allowing the values to be updated. This will generally require 
//		* some sift-up and sift-down functions and  
//		* an image of back-pointers going from the image to heap in order
//		* to locate the node which is to be updated.
		if(labelmap[currentindex]&OPTIMIZED)
			continue;
		
		z = currentindex/distmapImageSize;
		y = (currentindex - z*distmapImageSize)/distmapWidth;
		x = currentindex - z*distmapImageSize - y*distmapWidth;
		currentlabel = labelmap[currentindex]&LABELBITSMASK;
		//set this point has been optimized.
		labelmap[currentindex] = labelmap[currentindex]|OPTIMIZED;
		currentcost = costmap[currentindex];
		
		for (dz=-1; dz<=1; dz++) {
			for (dy=-1; dy<=1; dy++) {
				for (dx=-1; dx<=1; dx++) {
					if((x+dx)<0 || (x+dx)>=distmapWidth || (y+dy)<0 ||(y+dy)>=distmapHeight || (z+dz)<0 || (z+dz)>=distmapDepth ||ifThe2PointsMeet)
						continue;
					neighborindex = (z+dz)*distmapImageSize + (y+dy)*distmapWidth + (x+dx);
					if ((labelmap[neighborindex]&LABELBITSMASK) && (labelmap[neighborindex]&LABELBITSMASK)!=currentlabel) {
						ifThe2PointsMeet=YES;
						jointPointA=currentindex;
						jointPointB=neighborindex;
						break;
					}
					//if the neighbor is not optimized
					if (!(labelmap[neighborindex]&OPTIMIZED)) {
						newcost = currentcost + [self stepCostFrom:currentindex To:neighborindex];
						if (newcost < costmap[neighborindex]) {
							costmap[neighborindex] = newcost;
							currentdirection=(-dz+1)*9+(-dy+1)*3-dx+1;
							labelmap[neighborindex] = currentlabel|currentdirection;
							PathNode aneighbor;
							aneighbor.index = neighborindex;
							aneighbor.cost = newcost;
							priorityQ.push(aneighbor);
						}
					}
					
					
				}
			}
		}
		
		
	}
	free(costmap);
	if(ifThe2PointsMeet)
	{
		NSMutableArray* line2A = [NSMutableArray arrayWithCapacity:0];
		NSMutableArray* line2B = [NSMutableArray arrayWithCapacity:0];

		if(currentlabel==LABELOFPOINTA)
		{
			[self trackCenterline: line2A From:jointPointA WithLabel:labelmap];
			[self trackCenterline: line2B From:jointPointB WithLabel:labelmap];
		}
		else {
			[self trackCenterline: line2A From:jointPointB WithLabel:labelmap];
			[self trackCenterline: line2B From:jointPointA WithLabel:labelmap];	
		}
		int ptnumber=[line2A count];
		for (i=0; i<ptnumber; i++) {
			[centerline addObject:[line2A objectAtIndex:ptnumber-1-i]];
		}
		ptnumber=[line2B count];
		for (i=0; i<ptnumber; i++) {
			[centerline addObject:[line2B objectAtIndex:i]];
		}
		
		ptnumber=[centerline count];
		for (i=0; i<ptnumber; i++) {
			OSIVoxel* pt = [centerline objectAtIndex:i];
			pt.x /= resampleScale_x;
			pt.y /= resampleScale_y;
			pt.z /= resampleScale_z;
		}
		[self downSampleCenterlineWithLocalRadius:centerline];
        if (smoothFlag) {
            [self createSmoothedCenterlin:centerline withStepLength:centerlineResampleStepLength];
        }
		
		free(labelmap);
		return	0;
	}
	else {
		free(labelmap);
		return ERROR_CANNOTFINDPATH;
	}
	
}
- (void) downSampleCenterlineWithLocalRadius:(NSMutableArray*)centerline //using the input scale
{
	if( centerline.count <= 2)
		return;
	unsigned int i;

	float radius_prept,radius_nextpt;
	float x,y,z;
	OSIVoxel* pt = [centerline objectAtIndex:0];
	x = pt.x*resampleScale_x; y = pt.y*resampleScale_y; z = pt.z*resampleScale_z;
	radius_prept = distmap[(int)z*distmapImageSize+(int)y*distmapWidth+(int)x];
	float prex,prey,prez;
	prex = pt.x*resampleScale_x; prey = pt.y*resampleScale_y; prez = pt.z*resampleScale_z;
	for (i=1; i<[centerline count]; i++) {
		pt = [centerline objectAtIndex:i];
		x = pt.x*resampleScale_x; y = pt.y*resampleScale_y; z = pt.z*resampleScale_z;
		radius_nextpt = distmap[(int)z*distmapImageSize+(int)y*distmapWidth+(int)x];
		if (sqrt((x-prex)*(x-prex) + (y-prey)*(y-prey) + (z-prez)*(z-prez)) < (radius_prept+radius_nextpt)/2) {
			[centerline removeObjectAtIndex:i];
			i--;
		}
		else {
			radius_prept = radius_nextpt;
			prex = x; prey = y; prez = z;
		}
	}
}
- (void) createSmoothedCenterlin:(NSMutableArray*)centerline withStepLength:(float)len
{
    if( centerline.count <= 2)
        return;
    
	Spline3D* function = [[[Spline3D alloc] init] autorelease];
	Point3D* pt = [Point3D point];
	float delta_t= 1.0/(float)((long)[centerline count]-1);
	int i;
	float prex,prey,prez, totallength=0;
	OSIVoxel* pos = [centerline objectAtIndex:0];
	prex = pos.x; prey = pos.y; prez = pos.z;
	for (i=0 ; i<[centerline count]; i++) {
		pos = [centerline objectAtIndex:i];
		pt.x = pos.x; pt.y = pos.y; pt.z = pos.z;
		[function addPoint:delta_t*i :pt];
		totallength += sqrt((pt.x-prex)*(pt.x-prex) + (pt.y-prey)*(pt.y-prey) + (pt.z-prez)*(pt.z-prez));
		prex = pt.x; prey = pt.y; prez = pt.z;
	}
	[centerline removeAllObjects];
	int ptnumber = totallength/len;
	delta_t=1.0/(float)(ptnumber-1);
	for( i = 0 ; i < ptnumber ; i++ )
	{
		Point3D *tempPoint = [function evaluateAt: delta_t*i];
		pos = [OSIVoxel pointWithPoint3D:tempPoint];
		[centerline addObject:pos];
	}
}
- (float) stepCostFrom:(int)index1 To:(int)index2
{
	float cost;
	cost =expf(-distmap[index2]);
	return cost;
//
//	cost = 1.0/distmap[index2];
//	

//	return cost*cost*cost;
}
- (void) trackCenterline:(NSMutableArray*)line From:(int)currentindex WithLabel:(unsigned char*)labelmap
{
	int currentdirection;
	int x,y,z;
	int dx,dy,dz;
	z = currentindex/distmapImageSize;
	y = (currentindex - z*distmapImageSize)/distmapWidth;
	x = currentindex - z*distmapImageSize - y*distmapWidth;
	OSIVoxel* pt = [OSIVoxel pointWithX:x y:y z:z value:nil];
	[line addObject:pt];
	while ( (labelmap[currentindex] & DIRECTIONBITSMASK)!=DIRECTIONTOSELF) {
		currentdirection = labelmap[currentindex] & DIRECTIONBITSMASK;
		dz = currentdirection/9;
		dy = (currentdirection - dz*9)/3;
		dx = currentdirection - dz*9 - dy*3;
		dx--; dy--; dz--;
		x += dx;
		y += dy;
		z += dz;
		pt = [OSIVoxel pointWithX:x y:y z:z value:nil];
		[line addObject:pt];
		currentindex = z*distmapImageSize + y*distmapWidth + x;
		
	}
	
}
- (float) radiusAtPoint:(OSIVoxel *)pt
{
	int x,y,z;
	x = pt.x*resampleScale_x; y = pt.y*resampleScale_y; z = pt.z*resampleScale_z;
	if (x>=0 && x<distmapWidth && y>=0 && y<distmapHeight && z>=0 && z<distmapDepth) {
		return distmap[z*distmapImageSize + y*distmapWidth +x]*resampleVoxelSize;
	}
	
	return 0.0;
}
- (float) averageRadiusAt:(int)index On:(NSMutableArray*)centerline InRange:(int) nrange
{
	float averageradius = 0.0;
	int counter=0;
	int i;
	for (i=-nrange; i<nrange; i++) {
		if (index+i>=0 && index+i<[centerline count]) {
			averageradius += [self radiusAtPoint:[centerline objectAtIndex:index+i]];
			counter++;
		}
	}
	
	if (counter) {
		averageradius = averageradius/(float)counter;
	}
	return averageradius;
	
	
}

- (OSIVoxel*) computeMaximizingViewDirectionFrom:(OSIVoxel*) center LookingAt:(OSIVoxel*) direction
{
    OSIVoxel * bestView = [[[OSIVoxel alloc] init] autorelease];
    // calcul de la direction maximisant la vue. Mise de côté pour le moment, en attendant que les quaternions fonctionnent correctement
    int window = 45;
    
    unsigned int maxView = 0;
    short i = 1;
    
    Point3D * origin = [[[Point3D alloc] initWithValues:center.x :center.y :center.z] autorelease];
    [self converPoint2ResampleCoordinate:origin];
    Quaternion currentDir(direction.x-center.x, direction.y-center.y, direction.z-center.z, 0);
    N3Vector cdir, vxAxis, vyAxis;
    cdir.x = direction.x-center.x;
    cdir.y = direction.y-center.y;
    cdir.z = direction.z-center.z;
    
    // compute xAxis and yAxis so (xAxis, yAxis) is a base for the plan normal to currentDir
    // http://fr.wikipedia.org/wiki/Plan_%28math%C3%A9matiques%29#Approche_analytique_en_dimension_3
    if (currentDir.getX() != 0) {
        vxAxis.x = -currentDir.getY()/currentDir.getX();
        vxAxis.y = 1;
        vxAxis.z = 0;
        
        vyAxis.x = -currentDir.getZ()/currentDir.getX();
        vyAxis.y = 0;
        vyAxis.z = 1;
    } else if (currentDir.getY() != 0) {
        vxAxis.x = 1;
        vxAxis.y = -currentDir.getX()/currentDir.getY();
        vxAxis.z = 0;
        
        vyAxis.x = 0;
        vyAxis.y = -currentDir.getZ()/currentDir.getY();
        vyAxis.z = 1;
    } else {
        vxAxis.x = 1;
        vxAxis.y = 0;
        vxAxis.z = -currentDir.getX()/currentDir.getZ();
        
        vyAxis.x = 0;
        vyAxis.y = 1;
        vyAxis.z = -currentDir.getY()/currentDir.getZ();
    }
    
    Quaternion xAxisRot( vxAxis, -window );
    Quaternion yAxisRot( vyAxis, -window );

    // Put the currentDir to the first angle for "raytracing"
    cdir = yAxisRot * xAxisRot * cdir;
    
    Point3D * newDirection = [[[Point3D alloc] initWithValues:cdir.x :cdir.y :cdir.z] autorelease];

    // get the unit vector that maximizes the view
    for (int x = -window; x <= window; x+=3) {
        for (int y = -window; y <= window; y+=3) {
            [newDirection setX:cdir.x];
            [newDirection setY:cdir.y];
            [newDirection setZ:cdir.z];
            unsigned int viewDistance = [self traceLineFrom:origin
                                                accordingTo:newDirection];
            if (viewDistance > maxView) {
                maxView = viewDistance;
                [newDirection add:origin];  
                bestView.x = newDirection.x;
                bestView.y = newDirection.y;
                bestView.z = newDirection.z;
            }
            yAxisRot.fromAxis(vyAxis, i);
            cdir = yAxisRot * cdir;
        }
        i *= -1;
        yAxisRot.fromAxis(vyAxis, i);
        xAxisRot.fromAxis(vxAxis, 1);
        cdir = yAxisRot * xAxisRot * cdir;
    }
    
    return bestView;
}

- (void) computeHistogram;
{
    vImage_Buffer buffer;
    buffer.data = input;
    buffer.height = 1;
    buffer.width = inputVolumeSize;
    buffer.rowBytes = inputVolumeSize * sizeof(float);
    
    histoSize = inputMaxValue - inputMinValue;
    if (inputHisto) {
        free(inputHisto);
    }
    inputHisto = (vImagePixelCount *)malloc(histoSize * sizeof(vImagePixelCount));
    if (inputHisto && buffer.data) {
        vImageHistogramCalculation_PlanarF( &buffer, inputHisto, histoSize, inputMinValue, inputMaxValue, kvImageNoFlags);
    }
}

- (void) determineImageRange;
{
    inputMinValue = MAXFLOAT;
    inputMaxValue = - MAXFLOAT;
    
    for (unsigned int i = 0; i < inputVolumeSize; ++i) {
        if (input[ i ] < inputMinValue)
            inputMinValue = input[ i ];
        if (input[ i ] > inputMaxValue)
            inputMaxValue = input[ i ];
    }
}

- (unsigned int) traceLineFrom:(Point3D *) center accordingTo:(Point3D *) direction
{
    std::vector<unsigned int> line;
    unsigned int viewDistance = 0;
    
    Point3D * current = center;
    
    do {
        [current add:direction];
        ++viewDistance;
    } while ( [self point:current InVolumeX:distmapWidth Y:distmapHeight Z:distmapDepth]
             && distmap[(int)current.x + distmapWidth*(int)current.y + distmapImageSize*(int)current.z] != 0);
    
    return viewDistance;
}

- (BOOL) point:(Point3D *)p InVolumeX:(int)x Y:(int)y Z:(int)z
{
    return (p.x > 0 && p.x < x && p.y > 0 && p.y < y && p.z > 0 && p.z < z);
}

- (int) input3DCoords2LineCoords:(const int)x :(const int)y :(const int)z;
{ return x + y * inputWidth + z * inputImageSize; }

- (int) distMap3DCoords2LineCoords:(const int)x :(const int)y :(const int)z;
{ return x + y * distmapWidth + z * distmapImageSize; }

@end
