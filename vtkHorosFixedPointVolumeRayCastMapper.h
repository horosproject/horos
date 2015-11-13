#ifndef __vtkHorosFixedPointVolumeRayCastMapper_h
#define __vtkHorosFixedPointVolumeRayCastMapper_h

#include "vtkFixedPointVolumeRayCastMapper.h"

class  VTKRENDERINGVOLUME_EXPORT vtkHorosFixedPointVolumeRayCastMapper : public vtkFixedPointVolumeRayCastMapper {
    
public:
    
    static vtkHorosFixedPointVolumeRayCastMapper *New();
    void Render( vtkRenderer *, vtkVolume * );
    
protected:
    
    vtkHorosFixedPointVolumeRayCastMapper();
    void DisplayRenderedImage( vtkRenderer *ren, vtkVolume   *vol );
    
private:
    
    vtkHorosFixedPointVolumeRayCastMapper(const vtkHorosFixedPointVolumeRayCastMapper&);  // Not implemented.
    void operator=(const vtkHorosFixedPointVolumeRayCastMapper&);  // Not implemented.
    
};

#endif
