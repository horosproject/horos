StringValues="BeamLimitingDeviceRotationDirection" {
	CW = clockwise,
	CC = counter-clockwise,
	NONE = no rotation
}

StringValues="SignalDomainColumns" {
    FREQUENCY,
	TIME
}

StringValues="FilterMaterial" {
	MOLYBDENUM,
	ALUMINUM,
    COPPER,
    RHODIUM,
    NIOBIUM,
    EUROPIUM,
    LEAD,
    MIXED
}

StringValues="RangeModulatorType" {
    FIXED,
    WHL_FIXEDWEIGHTS,
    WHL_MODWEIGHTS
}

StringValues="VerticalPrismBase" {
    UP,
    DOWN
}

StringValues="ACR_NEMA_2C_DCTLabel" {
}

StringValues="RETIRED_CoordinatesSetGeometricTypeTrial" {
}

StringValues="ShadowStyle" {
    NORMAL,
    OUTLINED,
    OFF
}

StringValues="GeneralPurposeScheduledProcedureStepStatus" {
    SCHEDULED,
    IN PROGRESS,
    SUSPENDED,
    COMPLETED,
    DISCONTINUED
}

StringValues="De-coupledNucleus" {
    1H,
    3HE,
    7LI,
    13C,
    19F,
    23NA,
    31P,
    129XE
}

StringValues="DoseUnits" {
    GY = Gray,
    RELATIVE = relative to implicit reference value
}

StringValues="NominalBeamEnergyUnit" {
    MV = Megavolt,
    MEV = Mega electron-Volt
}

StringValues="CompensatorDivergence" {
    PRESENT,
    ABSENT
}

StringValues="PhotometricInterpretation" {
    MONOCHROME1,
    MONOCHROME2,
    PALETTE COLOR,
    RGB,
    HSV,
    ARGB,
    CMYK,
    YBR_FULL,
    YBR_FULL_422,
    YBR_PARTIAL_422,
    YBR_PARTIAL_420,
    YBR_ICT,
    YBR_RCT,
}

StringValues="PixelIntensityRelationship" {
    LIN,
    LOG,
    DISP
}

StringValues="SmoothingType" {
}

StringValues="InternationalRouteSegment" {
}

StringValues="RETIRED_ReferencedObservationClassTrial" {
}

StringValues="ImageSetSelectorUsageFlag" {
    MATCH,
    NO_MATCH
}

StringValues="TIPType" {
}

StringValues="InversionRecovery" {
    YES,
    NO
}

StringValues="AttenuationCorrectionSource" {
    CT,
    MR,
    POSITRON SOURCE,
    SINGLE PHOTON,
    CALCULATED
}

StringValues="ACR_NEMA_2C_TransformLabel" {
}

StringValues="ShutterShape" {
    RECTANGULAR,
    CIRCULAR,
    POLYGONAL
}

StringValues="TypeOfPatientID" {
    TEXT,
    RFID,
    BARCODE
}

StringValues="PreserveCompositeInstancesAfterMediaCreation" {
    YES,
    NO
}

StringValues="DataPathID" {
    PRIMARY,
    SECONDARY
}

StringValues="MaskSelectionMode" {
    SYSTEM,
    USER
}

StringValues="ShortTermFluctuationProbabilityCalculated" {
    YES,
    NO
}

StringValues="MappingResource" {
    DCMR = DICOM Content Mapping Resource,
    SDM = SNOMED DICOM Microglossary
}

StringValues="TransformedAxisUnits" {
}

StringValues="SegmentAlgorithmType" {
    AUTOMATIC = calculated segment,
    SEMIAUTOMATIC = calculated segment with user assistance,
    MANUAL = user-entered segment
}

StringValues="ModalitiesinStudy" {
}

StringValues="MRSpectroscopyAcquisitionType" {
    SINGLE_VOXEL,
    ROW,
    PLANE,
    VOLUME
}

StringValues="ASLBolusCutoffFlag" {
    YES,
    NO
}

StringValues="FrameofInterestType" {
    HIGHMI,
    RWAVE,
    TRIGGER,
    ENDSYSTOLE
}

StringValues="IntensifierActiveShape" {
    RECTANGLE,
    ROUND,
    HEXAGONAL
}

StringValues="LabelStyleSelection" {
}

StringValues="RTPlanGeometry" {
    PATIENT = RT Structure Set exists,
    TREATMENT_DEVICE = RT Structure Set does not exist
}

StringValues="DoseSummationType" {
    PLAN = dose calculated for entire RT Plan,
    MULTI_PLAN = dose calculated for 2 or more RT Plans,
    FRACTION = dose calculated for a single Fraction Group within RT Plan,
    BEAM = dose calculated for one or more Beams within RT Plan,
    BRACHY = dose calculated for one or more Brachy Application Setups within RT Plan,
    CONTROL_POINT = dose calculated for one or more Control Points within a Beam
}

StringValues="OtherSmoothingTypesAvailable" {
    STANDARD\*,
    ROW\*,
    COL\*
}

StringValues="PhaseDescription" {
    FLOW,
    WASHOUT,
    UPTAKE,
    EMPTYING,
    EXCRETION
}

StringValues="LateralSpreadingDeviceType" {
    SCATTERER = metal placed into the beam path to scatter charged particles laterally,
    MAGNET = nozzle configuration of magnet devices to expand beam laterally
}

StringValues="TemporalRangeType" {
    POINT = a single temporal point,
    MULTIPOINT = multiple temporal points,
    SEGMENT = a range between two temporal points,
    MULTISEGMENT = multiple segments, each denoted by two temporal points,
    BEGIN = a range beginning at one temporal point, and extending beyond the end of the acquired data,
    END = a range beginning before the start of the acquired data, and extending to (and including) the identified temporal point
}

StringValues="ShowImageTrueSizeFlag" {
    YES,
    NO
}

StringValues="PreliminaryFlag" {
    PRELIMINARY,
    FINAL
}

StringValues="ACR_NEMA_2C_DataBlockDescription" {
}

StringValues="LossyImageCompression" {
    00 = Image has NOT been subjected to lossy compression,
    01 = Image has been subjected to lossy compression
}

StringValues="PartialDataDisplayHandling" {
    MAINTAIN_LAYOUT,
    ADAPT_LAYOUT
}

StringValues="GeneralPurposePerformedProcedureStepStatus" {
    IN PROGRESS = Started but not complete,
    DISCONTINUED = Canceled or unsuccessfully terminated,
    COMPLETED = Successfully completed
}

StringValues="CoordinateSystemAxisUnits" {
}

StringValues="DegreeOfFreedomType" {
    TRANSLATION,
    ROTATION
}

StringValues="PatientOrientation" {
    A = anterior,
    P = posterior,
    R = right,
    L = left,
    H = head,
    F = foot,
    LE = Le or Left,
    RT = Rt or Right,
    D = Dorsal,
    V = Ventral,
    CR = Cr or Cranial,
    CD = Cd or Caudal,
    R = Rostral,
    M = Medial,
    L = Lateral,
    PR = Pr or Proximal,
    DI = Di or Distal,
    PA = Pa or Palmar,
    PL = Pl or Plantar
}

StringValues="ContourGeometricType" {
    POINT = single point,
    OPEN_PLANAR = open contour containing coplanar points,
    OPEN_NONPLANAR = open contour containing non-coplanar points,
    CLOSED_PLANAR = closed contour (polygon) containing coplanar points
}

StringValues="CompensatorMountingPosition" {
    PATIENT_SIDE = the compensator is mounted on the side of the Compensator Tray which is towards the patient,
    SOURCE_SIDE = the compensator is mounted on the side of the Compensator Tray which is towards the radiation source,
    DOUBLE_SIDED = the compensator has a shaped (i.e. non-flat) surface on both sides of the Compensator Tray
}

StringValues="IndicationType" {
}

StringValues="TissueHeterogeneityCorrection" {
    IMAGE = image data,
    ROI_OVERRIDE = one or more ROI densities override image or water values where they exist,
    WATER = entire volume treated as water equivalent
}

StringValues="ContainerComponentMaterial" {
    GLASS,
    PLASTIC,
    METAL
}

StringValues="ShowTickLabel" {
    Y = yes,
    N = no
}

StringValues="RETIRED_ReferencedObjectObservationClassTrial" {
}

StringValues="SortingDirection" {
    INCREASING,
    DECREASING
}

StringValues="RETIRED_TransducerPosition" {
}

StringValues="PatientEyeMovementCommanded" {
    YES,
    NO
}

StringValues="RETIRED_ProcedureContextFlagTrial" {
}

StringValues="FilmDestination" {
}

StringValues="ShieldingDeviceType" {
    GUM,
    EYE,
    GONAD
}

StringValues="Coverageofk-Space" {
    FULL,
    CYLINDRICAL,
    ELLIPSOIDAL,
    WEIGHTED
}

StringValues="CatchTrialsDataFlag" {
    YES,
    NO
}

StringValues="ACR_NEMA_2C_TransformVersionNumber" {
}

StringValues="GeometricalProperties" {
    UNIFORM,
    NON_UNIFORM
}

StringValues="ColorImagePrintingFlag" {
}

StringValues="RETIRED_UrgencyOrPriorityAlertsTrial" {
}

StringValues="RGBLUTTransferFunction" {
    EQUAL_RGB = Output is R=G=B=input value,
    TABLE = Output is RGB LUT values
}

StringValues="PatientIdentityRemoved" {
    YES,
    NO
}

StringValues="ACR_NEMA_2C_CoefficientCoding" {
}

StringValues="GeneralAccessoryType" {
    GRATICULE = Accessory tray with a radio-opaque grid,
    IMAGE_DETECTOR = Image acquisition device positioned in the beam line,
    RETICLE = Accessory tray with radio-transparent markers or grid
}

StringValues="PerformedProtocolType" {
    STAGED,
    NON_STAGED
}

StringValues="SpatialLocationsPreserved" {
    YES,
    NO,
    REORIENTED_ONLY
}

StringValues="TypeOfData12" {
}

StringValues="StudyStatusID" {
}

StringValues="DistributionType" {
    NAMED_PROTOCOL,
    RESTRICTED_REUSE,
    PUBLIC_RELEASE
}

StringValues="InterpretationStatusID" {
}

StringValues="SOPClassesInStudy" {
}

StringValues="OverlayType" {
}

StringValues="ImageBoxLayoutType" {
    STACK = a single rectangle containing a steppable single frame, intended for user-controlled stepping through the image set, usually via continuous device interaction (e.g., mouse scrolling) or by single stepping (mouse or button click),
    CINE = a single rectangle, intended for video type play back where the user controls are play sequence, rate of play, and direction,
    SINGLE = a single rectangle, intended for images and objects with no defined methods of interaction
}

StringValues="SkipFrameRangeFlag" {
    DISPLAY,
    SKIP
}

StringValues="LowEnergyDetectors" {
}

StringValues="GantryPitchRotationDirection" {
    CW = clockwise,
    CC = counter-clockwise,
    NONE = no rotation
}

StringValues="RTBeamLimitingDeviceType" {
    Y = symmetric jaw pair in IEC Y direction,
    ASYMX = asymmetric jaw pair in IEC X direction,
    ASYMY = asymmetric pair in IEC Y direction,
    MLCX = multileaf (multi-element) jaw pair in IEC X direction,
    MLCY = multileaf (multi-element) jaw pair in IEC Y direction
}

StringValues="DisplayShadingFlag" {
    NONE = no shading,
    BASELINE = shading between the waveform and the channel display baseline (sample value 0 equivalent location),
    ABSOLUTE = shading between the waveform and the channel real world actual value 0 (i.e., taking into account the Channel Baseline (003A,0213) value),
    DIFFERENCE = shading between the waveform and a second waveform in the Presentation Group at the same Channel Position that also has Display Shading Flag (003A,0246) value DIFFERENCE
}

StringValues="WholeBodyTechnique" {
    1PS = one pass,
    2PS = two pass,
    PCN = patient contour following employed,
    MSP = multiple static frames collected into a whole body frame
}

StringValues="PatientSupportRotationDirection" {
    CW = clockwise,
    CC = counter-clockwise,
    NONE = no rotation
}

StringValues="StartingRespiratoryPhase" {
    INSPIRATION,
    MAXIMUM,
    EXPIRATION,
    MINIMUM
}

StringValues="DisplaySetPatientOrientation" {
}

StringValues="In-planePhaseEncodingDirection" {
    ROW = phase encoded in rows,
    COL = phase encoded in columns
}

StringValues="PupilDilated" {
    YES,
    NO
}

StringValues="LensSegmentType" {
    PROGRESSIVE,
    NONPROGRESSIVE
}

StringValues="GeneralPurposeScheduledProcedureStepPriority" {
    HIGH = used to indicate an urgent or emergent work item, equivalent to a STAT request,
    MEDIUM = used to indicate a work item that has a priority less than HIGH and higher than LOW. It can be used to further stratify work items,
    LOW = used to indicate a routine or non-urgent work item
}

StringValues="TransmitCoilType" {
    BODY,
    VOLUME = head, extremity, etc.,
    SURFACE
}

StringValues="MagnificationType" {
    REPLICATE,
    BILINEAR,
    CUBIC,
    NONE
}

StringValues="GantryType" {
}

StringValues="ImageHorizontalFlip" {
    Y = yes,
    N = no
}

StringValues="VisualFieldShape" {
    RECTANGLE,
    CIRCLE,
    ELLIPSE
}

StringValues="ImageBoxPresentationLUTFlag" {
}

StringValues="FillMode" {
    SOLID,
    STIPPELED
}

StringValues="De-couplingMethod" {
    MLEV,
    WALTZ,
    NARROWBAND
}

StringValues="DoseType" {
    PHYSICAL = physical dose,
    EFFECTIVE = physical dose after correction for biological effect using user-defined modeling technique,
    ERROR = difference between desired and planned dose
}

StringValues="ACR_NEMA_2C_BlockedPixels" {
}

StringValues="RotationDirection" {
    CW = clockwise,
    CC = counter clockwise
}

StringValues="PrinterStatusInfo" {
    NORMAL,
    BAD RECEIVE MGZ = There is a problem with the film receive magazine. Films from the printer cannot be transported into the magazine,
    BAD SUPPLY MGZ = There is a problem with a film supply magazine. Films from this magazine cannot be transported into the printer,
    CALIBRATING = Printer is performing self calibration, it is expected to be available for normal operation shortly,
    CALIBRATION ERR = An error in the printer calibration has been detected, quality of processed films may not be optimal,
    CHECK CHEMISTRY = A problem with the processor chemicals has been detected, quality of processed films may not be optimal,
    CHECK SORTER = There is an error in the film sorter,
    CHEMICALS EMPTY = There are no processing chemicals in the processor, films will not be printed and processed until the processor is back to normal,
    CHEMICALS LOW = The chemical level in the processor is low, if not corrected, it will probably shut down soon,
    COVER OPEN = One or more printer or processor covers, drawers, doors are open,
    ELEC CONFIG ERR = Printer configured improperly for this job,
    ELEC DOWN = Printer is not operating due to some unspecified electrical hardware problem,
    ELEC SW ERROR = Printer not operating for some unspecified software error,
    EMPTY 8X10 = The 8x10 inch film supply magazine is empty,
    EMPTY 8X10 BLUE = The 8x10 inch blue film supply magazine is empty,
    EMPTY 8X10 CLR = The 8x10 inch clear film supply magazine is empty,
    EMPTY 8X10 PAPR = The 8x10 inch paper supply magazine is empty,
    EMPTY 10X12 = The 10x12 inch film supply magazine is empty,
    EMPTY 10X12 BLUE = The 10x12 inch blue film supply magazine is empty,
    EMPTY 10X12 CLR = The 10x12 inch clear film supply magazine is empty,
    EMPTY 10X12 PAPR = The 10x12 inch paper supply magazine is empty,
    EMPTY 10X14 = The 10x14 inch film supply magazine is empty,
    EMPTY 10X14 BLUE = The 10x14 inch blue film supply magazine is empty,
    EMPTY 10X14 CLR = The 10x14 inch clear film supply magazine is empty,
    EMPTY 10X14 PAPR = The 10x14 inch paper supply magazine is empty,
    EMPTY 11X14 = The 11x14 inch film supply magazine is empty,
    EMPTY 11X14 BLUE = The 11x14 inch blue film supply magazine is empty,
    EMPTY 11X14 CLR = The 11x14 inch clear film supply magazine is empty,
    EMPTY 11X14 PAPR = The 11x14 inch paper supply magazine is empty,
    EMPTY 14X14 = The 14x14 inch film supply magazine is empty,
    EMPTY 14X14 BLUE = The 14x14 inch blue film supply magazine is empty,
    EMPTY 14X14 CLR = The 14x14 inch clear film supply magazine is empty,
    EMPTY 14X14 PAPR = The 14x14 inch paper supply magazine is empty,
    EMPTY 14X17 = The 14x17 inch film supply magazine is empty,
    EMPTY 14X17 BLUE = The 14x17 inch blue film supply magazine is empty,
    EMPTY 14X17 CLR = The 14x17 inch clear film supply magazine is empty,
    EMPTY 14X17 PAPR = The 14x17 inch paper supply magazine is empty,
    EMPTY 24X24 = The 24x24 cm film supply magazine is empty,
    EMPTY 24X24 BLUE = The 24x24 cm blue film supply magazine is empty,
    EMPTY 24X24 CLR = The 24x24 cm clear film supply magazine is empty,
    EMPTY 24X24 PAPR = The 24x24 cm paper supply magazine is empty,
    EMPTY 24X30 = The 24x30 cm film supply magazine is empty,
    EMPTY 24X30 BLUE = The 24x30 cm blue film supply magazine is empty,
    EMPTY 24X30 CLR = The 24x30 cm clear film supply magazine is empty,
    EMPTY 24X30 PAPR = The 24x30 cm paper supply magazine is empty,
    EMPTY A4 PAPR = The A4 paper supply magazine is empty,
    EMPTY A4 TRANS = The A4 transparency supply magazine is empty,
    EXPOSURE FAILURE = The exposure device has failed due to some unspecified reason,
    FILM JAM = A film transport error has occurred and a film is jammed in the printer or processor,
    FILM TRANSP ERR = There is a malfunction with the film transport, there may or may not be a film jam,
    FINISHER EMPTY = The finisher is empty,
    FINISHER ERROR = The finisher is not operating due to some unspecified reason,
    FINISHER LOW = The finisher is low on supplies,
    LOW 8X10 = The 8x10 inch film supply magazine is low,
    LOW 8X10 BLUE = The 8x10 inch blue film supply magazine is low,
    LOW 8X10 CLR = The 8x10 inch clear film supply magazine is low,
    LOW 8X10 PAPR = The 8x10 inch paper supply magazine is low,
    LOW 10X12 = The 10x12 inch film supply magazine is low,
    LOW 10X12 BLUE = The 10x12 inch blue film supply magazine is low,
    LOW 10X12 CLR = The 10x12 inch clear film supply magazine is low,
    LOW 10X12 PAPR = The 10x12 inch paper supply magazine is low,
    LOW 10X14 = The 10x14 inch film supply magazine is low,
    LOW 10X14 BLUE = The 10x14 inch blue film supply magazine is low,
    LOW 10X14 CLR = The 10x14 inch clear film supply magazine is low,
    LOW 10X14 PAPR = The 10x14 inch paper supply magazine is low,
    LOW 11X14 = The 11x14 inch film supply magazine is low,
    LOW 11X14 BLUE = The 11x14 inch blue film supply magazine is low,
    LOW 11X14 CLR = The 11x14 inch clear film supply magazine is low,
    LOW 11X14 PAPR = The 11x14 inch paper supply magazine is low,
    LOW 14X14 = The 14x14 inch film supply magazine is low,
    LOW 14X14 BLUE = The 14x14 inch blue film supply magazine is low,
    LOW 14X14 CLR = The 14x14 inch clear film supply magazine is low,
    LOW 14X14 PAPR = The 14x14 inch paper supply magazine is low,
    LOW 14X17 = The 14x17 inch film supply magazine is low,
    LOW 14X17 BLUE = The 14x17 inch blue film supply magazine is low,
    LOW 14X17 CLR = The 14x17 inch clear film supply magazine is low,
    LOW 14X17 PAPR = The 14x17 inch paper supply magazine is low,
    LOW 24X24 = The 24x24 cm film supply magazine is low,
    LOW 24X24 BLUE = The 24x24 cm blue film supply magazine is low,
    LOW 24X24 CLR = The 24x24 cm clear film supply magazine is low,
    LOW 24X24 PAPR = The 24x24 cm paper supply magazine is low,
    LOW 24X30 = The 24x30 cm film supply magazine is low,
    LOW 24X30 BLUE = The 24x30 cm blue film supply magazine is low,
    LOW 24X30 CLR = The 24x30 cm clear film supply magazine is low,
    LOW 24X30 PAPR = The 24x30 cm paper supply magazine is low,
    LOW A4 PAPR = The A4 paper supply magazine is low,
    LOW A4 TRANS = The A4 transparency supply magazine is low,
    NO RECEIVE MGZ = The film receive magazine not available,
    NO RIBBON = ￼￼￼￼￼￼￼￼￼￼The ribbon cartridge needs to be replaced,
    NO SUPPLY MGZ = The film supply magazine specified for this job is not available,
    CHECK PRINTER = The printer is not ready at this time, operator intervention is required to make the printer available,
    CHECK PROC = The processor is not ready at this time, operator intervention is required to make the printer available,
    PRINTER DOWN = The printer is not operating due to some unspecified reason,
    PRINTER BUSY = Printer is not available at this time, but should become ready without user intervention. This is to handle non-initialization instances,
    PRINT BUFF FULL = The Printer's buffer capacity is full. The printer is unable to accept new images in this state. The printer will correct this without user intervention. The SCU should retry later,
    PRINTER INIT = The printer is not ready at this time, it is expected to become available without intervention. For example, it may be in a normal warm-up state,
    PRINTER OFFLINE = The printer has been disabled by an operator or service person,
    PROC DOWN = The processor is not operating due to some unspecified reason,
    PROC INIT = The processor is not ready at this time, it is expected to become available without intervention. For example, it may be in a normal warm-up state,
    PROC OVERFLOW FL = Processor chemicals are approaching the overflow full mark,
    PROC OVERFLOW HI = Processor chemicals have reached the overflow full mark,
    QUEUED = Print Job in Queue,
    RECEIVER FULL = The Film receive magazine is full,
    REQ MED NOT INST = The requested film, paper, or other media supply magazine is installed in the printer, but may be available with operator intervention,
    REQ MED NOT AVAI = The requested film, paper, or other media requested is not available on this printer,
    RIBBON ERROR = There is an unspecified problem with the print ribbon,
    SUPPLY EMPTY = The printer is out of film,
    SUPPLY LOW = The film supply is low,
    UNKNOWN = There is an unspecified problem
}

StringValues="MediumType" {
    PAPER,
    CLEAR FILM,
    BLUE FILM,
    MAMMO CLEAR FILM,
    MAMMO BLUE FILM
}

StringValues="TickLabelAlignment" {
    BOTTOM,
    TOP
}

StringValues="FalseNegativesEstimateFlag" {
    YES,
    NO
}

StringValues="AcquisitionTerminationCondition" {
    CNTS = counts,
    DENS = density,
    MANU = manual,
    OVFL = data overflow,
    TIME = time,
    TRIG = physiological trigger
}

StringValues="FileSetID" {
}

StringValues="SeriesType" {
    STATIC,
    DYNAMIC,
    GATED,
    WHOLE,
    BODY,
    IMAGE,
    REPROJECTION
}

StringValues="CoordinateSystemDataSetMapping" {
}

StringValues="CollationFlag" {
}

StringValues="CatheterDirectionOfRotation" {
    CW = clockwise,
    CC = counter-clockwise
}

StringValues="FileSetDescriptorFileID" {
}

StringValues="OphthalmicImageOrientation" {
    LINEAR,
    NONLINEAR,
    TRANSVERSE
}

StringValues="ROIPhysicalProperty" {
    REL_MASS_DENSITY = mass density relative to water,
    REL_ELEC_DENSITY = electron density relative to water,
    EFFECTIVE_Z = effective atomic number,
    EFF_Z_PER_A = ratio of effective atomic number to mass (AMU-1),
    REL_STOP_RATIO = linear stopping power ratio relative to water,
    ELEM_FRACTION = elemental composition of the material
}

StringValues="CorrectedLocalizedDeviationFromNormalCalculated" {
    YES,
    NO
}

StringValues="Query/RetrieveLevel" {
}

StringValues="CurrentTreatmentStatus" {
    NOT_STARTED,
    ON_TREATMENT,
    ON_BREAK,
    SUSPENDED,
    STOPPED,
    COMPLETED
}

StringValues="ConsentForDistributionFlag" {
    NO,
    YES,
    WITHDRAWN
}

StringValues="ElementShape" {
}

StringValues="HighEnergyDetectors" {
}

StringValues="ImageBoxLargeScrollType" {
    PAGE = in a TILED image box, replace all image slots with the next N x M images in the set,
    ROW_COLUMN = in a TILED image box, move each row or column of images to the next row or column, depending on Image Box Scroll Direction (0072,0310),
    IMAGE = in a TILED image box, move each image to the next slot, either horizontally or vertically, depending on Image Box Scroll Direction (0072,0310)
}

StringValues="GradientOutputType" {
    DB_DT = in T/s,
    ELECTRIC_FIELD = in V/m,
    PER_NERVE_STIM = percentage of peripheral nerve stimulation
}

StringValues="ShowGraphicAnnotationFlag" {
    YES,
    NO
}

StringValues="PixelPresentation" {
}

StringValues="AttenuationCorrectionTemporalRelationship" {
    CONCURRENT,
    SEPARATE,
    SIMULTANEOUS
}

StringValues="ASLContext" {
    LABEL,
    CONTROL,
    M_ZERO_SCAN
}

StringValues="FilmSizeID" {
    8INX10IN,
    8_5INX11IN,
    10INX12IN,
    10INX14IN,
    11INX14IN,
    11INX17IN,
    14INX14IN,
    14INX17IN,
    24CMX24CM,
    24CMX30CM,
    A4,
    A3
}

StringValues="ExposureStatus" {
    NORMAL,
    ABORTED
}

StringValues="ApplicationSetupCheck" {
    PASSED = Passed check,
    FAILED = Failed check,
    UNKNOWN = Unknown status
}

StringValues="TableTopRollRotationDirection" {
    CW = clockwise,
    CC = counter-clockwise,
    NONE = no rotation
}

StringValues="OphthalmicAxialLengthMeasurementsType" {
    TOTAL LENGTH = the total axial length was taken with one measurement,
    LENGTH SUMMATION = a summation of segmental lengths that determine the total axial length,
    SEGMENTAL LENGTH = a segmental axial length
}

StringValues="OOIOwnerType" {
}

StringValues="RTROIRelationship" {
    SAME = ROIs represent the same entity,
    ENCLOSED = referenced ROI completely encloses referencing ROI,
    ENCLOSING = referencing ROI completely encloses referenced ROI
}

StringValues="PrinterStatus" {
    NORMAL,
    WARNING,
    FAILURE
}

StringValues="PrintPriority" {
    HIGH,
    MED,
    LOW
}

StringValues="ContextIdentifier" {
}

StringValues="IndicationDisposition" {
}

StringValues="AmplifierType" {
}

StringValues="CardiacSignalSource" {
    ECG = electrocardiogram,
    VCG = vector cardiogram,
    PP = peripheral pulse,
    MR = magnetic resonance, i.e. M-mode or cardiac navigator
}

StringValues="DimensionOrganizationType" {
    3D = Spatial Multi-frame image of parallel planes (3D volume set),
    3D_TEMPORAL = Temporal loop of parallel-plane 3D volume sets
}

StringValues="TestPointNormalsDataFlag" {
    YES,
    NO
}

StringValues="Units" {
    CNTS,
    NONE,
    CM2,
    CM2ML,
    PCNT,
    CPS,
    BQML,
    MGMINML,
    UMOLMINML,
    MLMING,
    MLG,
    1CM,
    UMOLML,
    PROPCNTS,
    PROPCPS,
    MLMINML,
    MLML,
    GML,
    STDDEV
}

StringValues="ImageProcessingApplied" {
    DIGITAL_SUBTR,
    HIGH_PASS_FILTER,
    LOW_PASS_FILTER,
    MULTI_BAND_FLTR,
    FRAME_AVERAGING,
    NONE
}

StringValues="ACR_NEMA_2C_SequenceOfCompressedData" {
}

StringValues="PerformedProcedureStepStatus" {
    IN PROGRESS = Started but not complete,
    DISCONTINUED = Canceled or unsuccessfully terminated,
    COMPLETED = Successfully completed
}

StringValues="SpecificCharacterSetOfFileSetDescriptorFile" {
    ISO_IR 100 = Latin alphabet No. 1,
    ISO_IR 101 = Latin alphabet No. 2,
    ISO_IR 109 = Latin alphabet No. 3,
    ISO_IR 110 = ￼Latin alphabet No. 4,
    ISO_IR 144 = Cyrillic,
    ISO_IR 127 = Arabic,
    ISO_IR 126 = Greek,
    ISO_IR 138 = Hebrew,
    ISO_IR 148 = Latin alphabet No. 5,
    ISO_IR 13 = Japanese,
    ISO_IR 166 = Thai,
    ISO 2022 IR 6 = Default repertoire,
    ISO 2022 IR 100 = Latin alphabet No. 1,
    ISO 2022 IR 101 = Latin alphabet No. 2,
    ISO 2022 IR 109 = Latin alphabet No. 3,
    ISO 2022 IR 110 = Latin alphabet No. 4,
    ISO 2022 IR 144 = Cyrillic,
    ISO 2022 IR 127 = Arabic,
    ISO 2022 IR 126 = Greek,
    ISO 2022 IR 138 = Hebrew,
    ISO 2022 IR 148 = Latin alphabet No. 5,
    ISO 2022 IR 13 = Japanese,
    ISO 2022 IR 166 = Thai,
    ISO 2022 IR 87 = Japanese,
    ISO 2022 IR 159 = Japanese,
    ISO 2022 IR 149 = Korean
}

StringValues="SpecimenLabelInImage" {
    YES,
    NO
}

StringValues="OrganExposed" {
    BREAST,
    GONADS,
    BONE MARROW,
    FETUS,
    LENS
}

StringValues="CalibrationImage" {
    YES,
    NO
}

StringValues="AliasedDataType" {
    YES = data are aliased values,
    NO = data are not aliased values
}

StringValues="RETIRED_NuclearMedicineSeriesType" {
}

StringValues="ImplantPresent" {
    YES,
    NO
}

StringValues="SliceProgressionDirection" {
    APEX_TO_BASE,
    BASE_TO_APEX
}

StringValues="TypeOfSynchronization" {
    FRAME,
    POSITION,
    TIME,
    PHASE
}

StringValues="FrameofReferenceTransformationType" {
    HOMOGENEOUS
}

StringValues="Contrast_BolusAgentAdministered" {
    YES,
    NO
}

StringValues="StudyPriorityID" {
}

StringValues="ConversionType" {
    DV = Digitized Video,
    DI = Digital Interface,
    DF = Digitized Film,
    WSD = Workstation,
    SD = Scanned Document SI = Scanned Image DRW = Drawing,
    SYN = Synthetic Image
}

StringValues="TypeOfData4" {
}

StringValues="ScanMode" {
    NONE = No beam scanning is performed,
    UNIFORM = The beam is scanned between control points to create a uniform lateral fluence distribution across the field,
    MODULATED = The beam is scanned between control points to create a modulated lateral fluence distribution across the field
}

StringValues="RespiratoryCyclePosition" {
    START_RESPIR,
    END_RESPIR,
    UNDETERMINED
}

StringValues="BarcodeSymbology" {
    CODE128,
    CODE39,
    INTER_2_5,
    HIBC
}

StringValues="PositionerType" {
    CARM,
    COLUMN,
    MAMMOGRAPHIC,
    PANORAMIC,
    CEPHALOSTAT,
    RIGID,
    NONE
}

StringValues="ScreeningBaselineMeasured" {
    YES,
    NO
}

StringValues="DACType" {
}

StringValues="SCPStatus" {
}

StringValues="BrachyAccessoryDeviceType" {
    SHIELD,
    DILATATION,
    MOLD,
    PLAQUE,
    FLAB
}

StringValues="RespiratoryMotionCompensationTechnique" {
    NONE,
    BREATH_HOLD,
    REALTIME = image acquisition shorter than respiratory cycle,
    GATING = Prospective gating,
    TRACKING = prospective through-plane or in-plane motion tracking,
    PHASE_ORDERING = prospective phase ordering,
    PHASE_RESCANNING = prospective techniques, such as real-time averaging, diminishing variance and motion adaptive gating,
    RETROSPECTIVE = retrospective gating,
    CORRECTION = retrospective image correction
}

StringValues="MagnetizationTransfer" {
    ON_RESONANCE,
    OFF_RESONANCE,
    NONE
}

StringValues="CardiacCyclePosition" {
    END_SYSTOLE,
    END_DIASTOLE,
    UNDETERMINED
}

StringValues="VOIType" {
    LUNG,
    MEDIASTINUM,
    ABDO_PELVIS,
    LIVER,
    SOFT_TISSUE,
    BONE,
    BRAIN,
    POST_FOSSA
}

StringValues="EndingRespiratoryPhase" {
    INSPIRATION,
    MAXIMUM,
    EXPIRATION,
    MINIMUM
}

StringValues="RadiationMode" {
    CONTINUOUS,
    PULSED
}

StringValues="ScatterCorrected" {
    YES,
    NO
}

StringValues="FilmOrientation" {
    PORTRAIT = vertical film position,
    LANDSCAPE = horizontal film position
}

StringValues="VolumetricProperties" {
    VOLUME,
    SAMPLED,
    DISTORTED,
    MIXED
}

StringValues="Underlined" {
    Y = yes,
    N = no
}

StringValues="Manifold" {
    YES = Manifold in every point,
    NO = Does contain non-manifold points,
    UNKNOWN = Might or might not contain non-manifold points
}

StringValues="FluenceMode" {
    STANDARD = Uses standard fluence-shaping,
    NON_STANDARD = Uses a non-standard fluence-shaping mode
}

StringValues="CertificateType" {
    X509_1993_SIG
}

StringValues="HangingProtocolLevel" {
    MANUFACTURER,
    SITE,
    USER_GROUP,
    SINGLE_USER
}

StringValues="RefractiveIndexApplied" {
    YES,
    NO
}

StringValues="k-spaceFiltering" {
    COSINE,
    COSINE_SQUARED,
    FERMI,
    GAUSSIAN,
    HAMMING,
    HANNING,
    LORENTZIAN,
    LRNTZ_GSS_TRNSFM,
    RIESZ,
    TUKEY,
    NONE
}

StringValues="DiffusionDirectionality" {
    DIRECTIONAL,
    BMATRIX,
    ISOTROPIC,
    NONE
}

StringValues="RecognitionCode" {
}

StringValues="FilterByCategory" {
    IMAGE_PLANE
}

StringValues="SetupDeviceType" {
    LASER_POINTER,
    DISTANCE_METER,
    TABLE_HEIGHT,
    MECHANICAL_PTR,
    ARC
}

StringValues="AcquisitionStartCondition" {
    DENS = preset count density (counts/sec) was reached,
    RDD = preset relative count density difference (change in counts/sec) was reached,
    MANU = acquisition was started manually,
    TIME = preset time limit was reached,
    AUTO = start automatically, when ready,
    TRIG = preset number of physiological triggers was reached
}

StringValues="CountsSource" {
    EMISSION,
    TRANSMISSION
}

StringValues="AnnotationFlag" {
}

StringValues="MACAlgorithm" {
    RIPEMD160,
    MD5,
    SHA1,
    SHA256,
    SHA384,
    SHA512
}

StringValues="FocusMethod" {
    AUTO = autofocus,
    MANUAL = includes any human adjustment or verification of autofocus
}

StringValues="ChannelStatus" {
    OK,
    TEST DATA,
    DISCONNECTED,
    QUESTIONABLE,
    INVALID,
    UNCALIBRATED,
    UNZEROED
}

StringValues="PositionMeasuringDeviceUsed" {
    RIGID = The image was acquired with a position measuring device,
    FREEHAND = The image was acquired without a position measuring device
}

StringValues="ViewingDistanceType" {
    DISTANCE,
    NEAR,
    INTERMEDIATE,
    OTHER
}

StringValues="SmokingStatus" {
    YES,
    NO,
    UNKNOWN
}

StringValues="Contrast_BolusAgentDetected" {
    YES,
    NO
}

StringValues="PulserType" {
}

StringValues="ApplicationSetupType" {
    FLETCHER_SUIT,
    DELCLOS,
    BLOEDORN,
    JOSLIN_FLYNN,
    CHANDIGARH,
    MANCHESTER,
    HENSCHKE,
    NASOPHARYNGEAL,
    OESOPHAGEAL,
    ENDOBRONCHIAL,
    SYED_NEBLETT,
    ENDORECTAL,
    PERINEAL
}

StringValues="DetectorConditionsNominalFlag" {
    YES,
    NO
}

StringValues="ACR_NEMA_2C_CodeLabel" {
}

StringValues="ModulationType" {
}

StringValues="BackgroundColor" {
    RED,
    GREEN,
    WHITE
}

StringValues="FractionGroupType" {
    EXTERNAL_BEAM,
    BRACHY
}

StringValues="AllowMediaSplitting" {
    YES,
    NO
}

StringValues="FlowCompensation" {
    ACCELERATION,
    VELOCITY,
    OTHER,
    NONE
}

StringValues="DirectoryRecordType" {
    PATIENT,
    STUDY,
    SERIES,
    IMAGE,
    RT DOSE,
    RT STRUCTURE SET,
    RT PLAN,
    RT TREAT RECORD,
    PRESENTATION,
    WAVEFORM,
    SR DOCUMENT,
    KEY OBJECT DOC,
    SPECTROSCOPY,
    RAW DATA,
    REGISTRATION,
    FIDUCIAL,
    HANGING PROTOCOL,
    ENCAP DOC,
    HL7 STRUC DOC,
    VALUE MAP,
    STEREOMETRIC,
    PALETTE,
    IMPLANT,
    IMPLANT GROUP,
    IMPLANT ASSY,
    MEASUREMENT,
    SURFACE,
    PRIVATE
}

StringValues="RespiratorySignalSource" {
    NONE,
    BELT = includes various devices that detect or track expansion of the chest,
    NASAL_PROBE,
    CO2_SENSOR,
    NAVIGATOR = MR navigator and organ edge detection,
    MR_PHASE = phase (of center k-space line),
    ECG = baseline demodulation of the ECG,
    SPIROMETER = Signal derived from flow sensor,
    EXTERNAL_MARKER = Signal determined from external motion surrogate,
    INTERNAL_MARKER = Signal determined from internal motion surrogate,
    IMAGE = Signal derived from an image,
    UNKNOWN = Signal source not known
}

StringValues="T2Preparation" {
    YES,
    NO
}

StringValues="AnnotationDisplayFormatID" {
}

StringValues="TableTopEccentricRotationDirection" {
    CW = clockwise,
    CC = counter-clockwise,
    NONE = no rotation
}

StringValues="OphthalmicAxialLengthMeasurementModified" {
    YES,
    NO
}

StringValues="VariableFlipAngleFlag" {
    Y = yes,
    N = no
}

StringValues="DeadTimeCorrected" {
    YES,
    NO
}

StringValues="Geometryofk-SpaceTraversal" {
    RECTILINEAR,
    RADIAL,
    SPIRAL
}

StringValues="ACR_NEMA_CompressionCode" {
}

StringValues="ShowPatientDemographicsFlag" {
    YES,
    NO
}

StringValues="CertifiedTimestampType" {
    CMS_TSP = Internet X.509 Public Key Infrastructure Time Stamp Protocol
}

StringValues="PixelOriginInterpretation" {
    FRAME = relative to individual frame,
    VOLUME = relative to Total Image Matrix
}

StringValues="PresentationLUTShape" {
    IDENTITY = output is in P-Values
    INVERSE = output after inversion is in P-Values
}

StringValues="FluenceDataSource" {
    CALCULATED = Calculated by a workstation,
    MEASURED = Measured by exposure to a film or detector
}

StringValues="ReceiveCoilType" {
    BODY,
    VOLUME = head, extremity, etc,
    SURFACE,
    MULTICOIL
}

StringValues="VolumeBasedCalculationTechnique" {
    MAX_IP = Maximum Intensity Projection,
    MIN_IP = Minimum Intensity Projection,
    VOLUME_RENDER = Volume Rendering Projection,
    SURFACE_RENDER = Surface Rendering Projection,
    MPR = Multi-Planar Reformat,
    CURVED_MPR = Curved Multi-Planar Reformat,
    NONE = Pixels not derived geometrically,
    MIXED
}

StringValues="ASLCrusherFlag" {
    YES,
    NO
}

StringValues="PrinterResolutionID" {
    STANDARD = approximately 4k x 5k printable pixels on a 14 x 17 inch film,
    HIGH = Approximately twice the resolution of STANDARD
}

StringValues="LossyImageCompressionMethod" {
    ISO_10918_1 = JPEG Lossy Compression,
    ISO_14495_1 = JPEG-LS Near-lossless Compression,
    ISO_15444_1 = JPEG 2000 Irreversible Compression,
    ISO_13818_2 = MPEG2 Compression
}

StringValues="Bold" {
    Y = yes,
    N = no
}

StringValues="MultipleCopiesFlag" {
    Y = yes,
    N = no
}

StringValues="CollimatorShape" {
    RECTANGULAR,
    CIRCULAR,
    POLYGONAL
}

StringValues="VolumeLocalizationTechnique" {
    ILOPS,
    ISIS,
    PRIME,
    PRESS,
    SLIM,
    SLOOP,
    STEAM,
    NONE
}

StringValues="ThreeDRenderingType" {
    MIP\*,
    SURFACE\*,
    VOLUME\*
}

StringValues="TimeDomainFiltering" {
    COSINE,
    COSINE_SQUARED,
    EXPONENTIAL,
    GAUSSIAN,
    HAMMING,
    HANNING,
    LORENTZIAN,
    LRNTZ_GSS_TRNSFM,
    NONE
}

StringValues="MaskOperation" {
    NONE,
    AVG_SUB,
    TID,
    REV_TID
}

StringValues="PresentedVisualStimuliDataFlag" {
    YES,
    NO
}

StringValues="RETIRED_TransducerOrientation" {
}

StringValues="VOILUTFunction" {
    LINEAR,
    SIGMOID
}

StringValues="PixelSpacingCalibrationType" {
    GEOMETRY,
    FIDUCIAL
}

StringValues="GlobalDeviationProbabilityNormalsFlag" {
    YES,
    NO
}

StringValues="AlgorithmType" {
    FILTER_BACK_PROJ,
    ITERATIVE
}

StringValues="PatientSupportType" {
    TABLE = Treatment delivery system table,
    CHAIR = Treatment delivery system chair
}

StringValues="BrachyTreatmentTechnique" {
    INTRALUMENARY,
    INTRACAVITARY,
    INTERSTITIAL,
    CONTACT,
    INTRAVASCULAR,
    PERMANENT
}

StringValues="TemplateIdentifier" {
}

StringValues="RTROIInterpretedType" {
    EXTERNAL = external patient contour,
    PTV = Planning Target Volume (as defined in ICRU50),
    CTV = Clinical Target Volume (as defined in ICRU50),
    GTV = Gross Tumor Volume (as defined in ICRU50),
    TREATED_VOLUME = Treated Volume (as defined in ICRU50),
    IRRAD_VOLUME = Irradiated Volume (as defined in ICRU50),
    BOLUS = patient bolus to be used for external beam therapy,
    AVOIDANCE = region in which dose is to be minimized,
    ORGAN = patient organ,
    MARKER = patient marker or marker on a localizer,
    REGISTRATION = registration ROI,
    ISOCENTER = treatment isocenter to be used for external beam therapy,
    CONTRAST_AGENT = volume into which a contrast agent has been injected,
    CAVITY = patient anatomical cavity,
    BRACHY_CHANNEL = brachytherapy channel,
    BRACHY_ACCESSORY = brachytherapy accessory device,
    BRACHY_SRC_APP = brachytherapy source applicator,
    BRACHY_CHNL_SHLD = brachytherapy channel shield,
    SUPPORT = external patient support device,
    FIXATION = external patient fixation or immobilisation device,
    DOSE_REGION = ROI to be used as a dose reference,
    CONTROL = ROI to be used in control of dose optimization and calculation
}

StringValues="AllowLossyCompression" {
    YES,
    NO
}

StringValues="ExtendedDepthOfField" {
    YES,
    NO
}

StringValues="ConstantVolumeFlag" {
    YES,
    NO
}

StringValues="ScheduledProcedureStepPriority" {
    HIGH = used to indicate an urgent or emergent work item, equivalent to a STAT request,
    MEDIUM = used to indicate a work item that has a priority less than HIGH and higher than LOW. It can be used to further stratify work items,
    LOW = used to indicate a routine or non-urgent work item
}

StringValues="Contrast/BolusIngredient" {
    IODINE,
    GADOLINIUM,
    CARBON,
    DIOXIDE,
    BARIUM
}

StringValues="DeviceDiameterUnits" {
    FR = French,
    GA = Gauge,
    IN = Inch,
    MM = Millimeter
}

StringValues="Contrast_BolusAgentPhase" {
    PRE_CONTRAST,
    POST_CONTRAST,
    IMMEDIATE,
    DYNAMIC,
    STEADY_STATE,
    DELAYED,
    ARTERIAL,
    CAPILLARY,
    VENOUS,
    PORTAL_VENOUS
}

StringValues="TypeOfData" {
}

StringValues="RequestedResolutionID" {
    STANDARD = approximately 4k x 5k printable pixels on a 14 x 17 inch film,
    HIGH = Approximately twice the resolution of STANDARD
}

StringValues="IncludeNon-DICOMObjects" {
    NO,
    FOR_PHYSICIAN,
    FOR_PATIENT,
    FOR_TEACHING,
    FOR_RESEARCH
}

StringValues="TableType" {
    FIXED,
    TILTING,
    NONE
}

StringValues="MultipleSpinEcho" {
    YES,
    NO
}

StringValues="IndexNormalsFlag" {
    YES,
    NO
}

StringValues="SubscriptionListStatus" {
}

StringValues="FieldofViewHorizontalFlip" {
    NO,
    YES
}

StringValues="BulkMotionCompensationTechnique" {
    NONE,
    REALTIME = image acquisition shorter than motion cycle,
    GATING = prospective gating,
    TRACKING = prospective through and/or in-plane motion tracking,
    RETROSPECTIVE = retrospective gating,
    CORRECTION = retrospective image correction
}

StringValues="BloodSignalNulling" {
    YES,
    NO
}

StringValues="BoundingBoxTextHorizontalJustification" {
    LEFT = closest to left edge,
    RIGHT = closest to right edge,
    CENTER = centered
}

StringValues="FontNameType" {
    ISO_32000
}

StringValues="PseudoColorType" {
    HOT_IRON,
    PET,
    HOT_METAL_BLUE,
    PET_20_STEP
}

StringValues="FlowCompensationDirection" {
    PHASE,
    FREQUENCY,
    SLICE_SELECT,
    SLICE_AND_FREQ,
    SLICE_FREQ_PHASE,
    PHASE_AND_FREQ,
    SLICE_AND_PHASE,
    OTHER
}

StringValues="GantryMotionCorrected" {
    YES,
    NO
}

StringValues="Segmentedk-SpaceTraversal" {
    SINGLE = successive single echo coverage,
    PARTIAL = segmented coverage,
    FULL = single shot full coverage
}

StringValues="TypeofDetectorMotion" {
    NONE = stationary gantry,
    STATIONARY = No motion,
    STEP AND SHOOT = Interrupted motion, acquire only while stationary,
    CONTINUOUS = Gantry motion and acquisition are simultaneous and continuous,
    ACQ DURING STEP = Interrupted motion, acquisition is continuous,
    WOBBLE = wobble motion,
    CLAMSHELL = clamshell motion
}

StringValues="GraphicType" {
    POINT,
    POLYLINE,
    INTERPOLATED,
    CIRCLE,
    ELLIPSE
}

StringValues="SourceMovementType" {
    STEPWISE,
    FIXED,
    OSCILLATING,
    UNIDIRECTIONAL
}

StringValues="SegmentationFractionalType" {
    PROBABILITY,
    OCCUPANCY
}

StringValues="QuadratureReceiveCoil" {
    YES = quadrature or circularly polarized,
    NO = linear
}

StringValues="ComplexImageComponent" {
    MAGNITUDE = The magnitude component of the complex spectroscopy data,
    PHASE = The phase component of the complex spectroscopy data,
    REAL = The real component of the complex spectroscopy data,
    IMAGINARY = The imaginary component of the complex spectroscopy data,
    COMPLEX = The real and imaginary components of the complex spectroscopy data,
    MIXED
}

StringValues="ParticipationType" {
    SOURCE = Equipment that contributed to the content,
    ENT = Data enterer (e.g., transcriptionist),
    ATTEST = Attestor
}

StringValues="ScanningSequence" {
    SE = Spin Echo,
    IR = Inversion Recovery,
    GR = Gradient Recalled,
    EP = Echo Planar,
    RM = Research Mode
}

StringValues="ReformattingOperationType" {
    MPR,
    3D_RENDERING,
    SLAB
}

StringValues="ChannelMode" {
    MONO = 1 signal,
    STEREO = 2 simultaneously acquired (left and right) signals
}

StringValues="ROIGenerationAlgorithm" {
    AUTOMATIC = calculated ROI,
    SEMIAUTOMATIC = ROI calculated with user assistance,
    MANUAL = user-entered ROI
}

StringValues="RETIRED_FindingsFlagTrial" {
}

StringValues="InitialCineRunState" {
    STOPPED,
    RUNNING
}

StringValues="ParallelAcquisition" {
    YES,
    NO
}

StringValues="RadiationSetting" {
    SC = low dose exposure generally corresponding to fluoroscopic settings (e.g. preparation for diagnostic quality image acquisition),
    GR = high dose for diagnostic quality image acquisition (also called digital spot or cine)
}

StringValues="TypeOfData14" {
}

StringValues="FilterByAttributePresence" {
    PRESENT: Include the image if the attribute is present,
    NOT_PRESENT: Include the image if the attribute is not present
}

StringValues="Grid" {
    IN = A Grid is positioned,
    NONE = No Grid is used
}

StringValues="RETIRED_ObservationSubjectClassTrial" {
}

StringValues="ReprojectionMethod" {
    SUM,
    MAX PIXEL
}

StringValues="ImageOverlayFlag" {
}

StringValues="ExposureModulationType" {
    NONE
}

StringValues="FluoroscopyFlag" {
    YES,
    NO
}

StringValues="RouteSegmentLocationIDType" {
}

StringValues="InstanceAvailability" {
    ONLINE,
    NEARLINE,
    OFFLINE,
    UNAVAILABLE
}

StringValues="RequestedDecimate/CropBehavior" {
    DECIMATE = image will be decimated to fit,
    CROP = image will be cropped to fit,
    FAIL = N-SET of the Image Box will fail
}

StringValues="CountsIncluded" {
}

StringValues="AlarmDecision" {
}

StringValues="OOIType" {
}

StringValues="Optotype" {
    LETTERS,
    NUMBERS,
    PICTURES,
    TUMBLING E,
    LANDOLT C
}

StringValues="DetectorActiveShape" {
    RECTANGLE,
    ROUND,
    HEXAGONAL
}

StringValues="IncludeDisplayApplication" {
    NO,
    YES
}

StringValues="Multi-planarExcitation" {
    YES,
    NO
}

StringValues="GraphicLayer" {
}

StringValues="ACR_NEMA_ImageFormat" {
}

StringValues="BulkMotionSignalSource" {
    JOINT = joint motion detection,
    NAVIGATOR = MR navigator and organ edge detection,
    MR_PHASE = phase (of center k-space line)
}

StringValues="CorrectedImage" {
    UNIF = flood corrected,
    COR = center of rotation corrected,
    NCO = non-circular orbit corrected,
    DECY = decay corrected,
    ATTN = attenuation corrected,
    SCAT = scatter corrected,
    DTIM = dead time corrected,
    NRGY = energy corrected,
    LIN = linearity corrected,
    MOTN = motion corrected,
    CLN = count loss normalization,
    DECY = decay corrected,
    ATTN = attenuation corrected,
    SCAT = scatter corrected,
    DTIM = dead time corrected,
    MOTN = gantry motion corrected, (e.g. wobble, clamshell),
    PMOT = patient motion corrected,
    CLN = count loss normalization (correction for count loss in gated Time Slots),
    RAN = randoms corrected,
    RADL = non-uniform radial sampling corrected,
    DCAL = sensitivity calibrated using dose calibrator,
    NORM = detector normalization
}

StringValues="RETIRED_ReportStatusIDTrial" {
}

StringValues="RectilinearPhaseEncodeReordering" {
    LINEAR,
    CENTRIC,
    SEGMENTED,
    REVERSE_LINEAR,
    REVERSE_CENTRIC
}

StringValues="PatientMotionCorrected" {
    YES,
    NO
}

StringValues="GraphicFilled" {
    Y = yes,
    N = no
}

StringValues="BlendingOperationType" {
    COLOR = apply a pseudo-color to the superimposed image while blending
}

StringValues="ShowAcquisitionTechniquesFlag" {
    YES,
    NO
}

StringValues="BlockDivergence" {
    PRESENT = block edges are shaped for beam divergence,
    ABSENT = block edges are not shaped for beam divergence
}

StringValues="StudyComponentStatusID" {
}

StringValues="AcquisitionContrast" {
    DIFFUSION = Diffusion weighted contrast,
    FLOW_ENCODED = Flow Encoded contrast,
    FLUID_ATTENUATED = Fluid Attenuated T2 weighted contrast,
    PERFUSION = ￼￼Perfusion weighted contrast,
    PROTON_DENSITY = Proton Density weighted contrast,
    STIR = ￼￼Short Tau Inversion Recovery,
    TAGGING = ￼￼Superposition of thin saturation bands onto image,
    T1 = ￼￼T1 weighted contrast,
    T2 = ￼￼T2 weighted contrast,
    T2_STAR = ￼￼T2* weighted contrast,
    TOF = ￼￼Time Of Flight weighted contrast,
    UNKNOWN = Value should be UNKNOWN if acquisition contrasts were combined resulting in an unknown contrast. Also this value should be used when the contrast is not known,
    MIXED
}

StringValues="DefaultPrinterResolutionID" {
    STANDARD\*,
    ROW\*,
    COL\*
}

StringValues="IVUSAcquisition" {
    MOTOR_PULLBACK,
    MOTORIZED,
    MANUAL_PULLBACK,
    MANUAL,
    SELECTIVE,
    MEASURED,
    GATED_PULLBACK
}

StringValues="SequenceVariant" {
    SK = segmented k-space,
    MTC = magnetization transfer contrast,
    SS = steady state,
    TRSS = time reversed steady state,
    SP = spoiled,
    MP = MAG prepared,
    OSP = oversampling phase,
    NONE = no sequence variant
}

StringValues="RandomsCorrectionMethod" {
    NONE = no randoms correction,
    DLYD = delayed event subtraction,
    SING = singles estimation,
    PDDL = Processed Delays
}

StringValues="TableMotion" {
    STATIC = Table is stationary during data acquisition,
    DYNAMIC = Table is moving during data acquisition
}

StringValues="DigitizingDeviceTransportDirection" {
    ROW,
    COLUMN
}

StringValues="BaselineCorrection" {
    LINEAR_TILT,
    LOCAL_LINEAR_FIT,
    POLYNOMIAL_FIT,
    SINC_DECONVOLUTN,
    TIME_DOMAIN_FIT,
    SPLINE,
    NONE
}

StringValues="RETIRED_ReportProductionStatusTrial" {
}

StringValues="ParallelAcquisitionTechnique" {
    PILS,
    SENSE,
    SMASH,
    OTHER
}

StringValues="AlphaLUTTransferFunction" {
    NONE,
    IDENTITY,
    TABLE
}

StringValues="ExcessiveFixationLossesDataFlag" {
    YES,
    NO
}

StringValues="RectificationType" {
    SINGLE PHASE,
    THREE PHASE,
    CONST POTENTIAL
}

StringValues="AcquisitionType" {
    SEQUENCED,
    SPIRAL,
    CONSTANT_ANGLE,
    STATIONARY,
    FREE
}

StringValues="BrachyTreatmentType" {
    MANUAL = manually positioned,
    HDR = High dose rate,
    MDR = Medium dose rate,
    LDR = Low dose rate,
    PDR = Pulsed dose rate
}

StringValues="CArmPositionerTabletopRelationship" {
    YES,
    NO
}

StringValues="CassetteOrientation" {
    LANDSCAPE,
    PORTRAIT
}

StringValues="GantryRotationDirection" {
    CW = clockwise,
    CC = counter-clockwise,
    NONE = no rotation
}

StringValues="AbortReason" {
}

StringValues="DeadTimeCorrectionFlag" {
}

StringValues="PresentationIntentType" {
    FOR PRESENTATION,
    FOR PROCESSING
}

StringValues="GeneralizedDefectCorrectedSensitivityDeviationFlag" {
    YES,
    NO
}

StringValues="MeasurementLaterality" {
    R = right,
    L = left,
    B = both left and right together
}

StringValues="OptotypePresentation" {
    SINGLE,
    MULTIPLE
}

StringValues="SelectorAttributeVR" {
}

StringValues="ScreeningBaselineType" {
    CENTRAL,
    PERIPHERAL
}

StringValues="BoundingBoxAnnotationUnits" {
    PIXEL,
    DISPLAY,
    MATRIX
}

StringValues="UnifiedProcedureStepListStatus" {
}

StringValues="DataType" {
}

StringValues="WedgePosition" {
    IN,
    OUT
}

StringValues="ApplicableSafetyStandardAgency" {
    IEC,
    FDA,
    MHW
}

StringValues="SaturationRecovery" {
    YES,
    NO
}

StringValues="ShowGrayscaleInverted" {
    YES = The maximum output value after the display pipeline has been applied shall be displayed with the minimum available luminance,
    NO = The maximum output value after the display pipeline has been applied shall be displayed with the maximum available luminance
}

StringValues="SegmentationType" {
    BINARY,
    FRACTIONAL
}

StringValues="CorrectedLocalizedDeviationFromNormalProbabilityCalculated" {
    YES,
    NO
}

StringValues="PatientFrameOfReferenceSource" {
    TABLE = A positioning device, such as a gantry, was used to generate these values.
    ESTIMATED = Estimated patient position/orientation (eg, estimated by the user), or if reliable information is not available,
    REGISTRATION = Acquisition has been spatially registered to a prior image set
}

StringValues="CountLossNormalizationCorrected" {
    YES,
    NO
}

StringValues="DisplaySetHorizontalJustification" {
    LEFT,
    CENTER,
    RIGHT
}

StringValues="BlockMountingPosition" {
    PATIENT_SIDE = the block is mounted on the side of the Block Tray which is towards the patient,
    SOURCE_SIDE = the block is mounted on the side of the Block Tray which is towards the radiation source
}

StringValues="ScanOptions" {
    PER = Phase Encode Reordering,
    RG = Respiratory Gating,
    CG = Cardiac Gating,
    PPG = Peripheral Pulse Gating,
    FC = Flow Compensation,
    PFF = Partial Fourier - Frequency,
    PFP = Partial Fourier - Phase,
    SP = Spatial Presaturation,
    FS = Fat Saturation,
    TOMO = Tomography,
    CHASE = Bolus Chasing,
    STEP = Stepping,
    ROTA = Rotation
}

StringValues="ComponentShape" {
}

StringValues="XRayReceptorType" {
    IMG_INTENSIFIER,
    DIGITAL_DETECTOR
}

StringValues="PatientPosition" {
    HFP = Head First-Prone,
    HFDR = Head First-Decubitus Right,
    FFDR = Feet First-Decubitus Right,
    FFP = Feet First-Prone,
    HFS = Head First-Supine,
    HFDL = Head First-Decubitus Left,
    FFDL = Feet First-Decubitus Left,
    FFS = Feet First-Supine,
    SITTING
}

StringValues="BeatRejectionFlag" {
    Y = yes,
    N = no
}

StringValues="RangeShifterType" {
    ANALOG = Device is variable thickness and is composed of opposing sliding wedges, water column or similar mechanism,
    INARY = Device is composed of different thickness materials that can be moved in or out of the beam in various stepped combinations
}

StringValues="TypeOfData10" {
}

StringValues="RespiratoryTriggerType" {
    TIME,
    AMPLITUDE,
    BOTH
}

StringValues="DICOSVersion" {
}

StringValues="FilterByOperator" {
    PRESENT = Include the image if the attribute is present
    NOT_PRESENT = Include the image if the attribute is not present
}

StringValues="SubstanceAdministrationApproval" {
    APPROVED = Use of the substance for the patient is approved, with related notes (e.g., appropriate dose for age/weight) in Approval Status Further Description (0044,0003),
    WARNING = The substance may be used for the patient subject to warnings described in Approval Status Further Description (0044,0003),
    CONTRA_INDICATED = The substance should not be used for the patient for the reasons described in Approval Status Further Description (0044,0003)
}

StringValues="OCTZOffsetApplied" {
    YES,
    NO
}

StringValues="SUVType" {
    BSA = body surface area,
    BW = body weight,
    LBM = lean body mass
}

StringValues="TypeOfData6" {
}

StringValues="SignalDomainRows" {
    FREQUENCY,
    TIME
}

StringValues="PresentationLUTFlag" {
}

StringValues="SourceType" {
    POINT,
    LINE,
    CYLINDER,
    SPHERE
}

StringValues="Polarity" {
    NORMAL = pixels shall be printed as specified by the Photometric Interpretation (0028,0004),
    REVERSE = pixels shall be printed with the opposite polarity as specified by the Photometric Interpretation (0028,0004)
}

StringValues="TreatmentTerminationStatus" {
    NORMAL = treatment terminated normally,
    OPERATOR = operator terminated treatment,
    MACHINE = machine terminated treatment,
    UNKNOWN = status at termination unknown
}

StringValues="CassetteSize" {
    18CMX24CM,
    8INX10IN,
    24CMX30CM,
    10INX12IN,
    30CMX35CM,
    30CMX40CM,
    11INX14IN,
    35CMX35CM,
    14INX14IN,
    35CMX43CM,
    14INX17IN
}

StringValues="WaveformOriginality" {
    ORIGINAL,
    DERIVED
}

StringValues="Trim" {
    YES,
    NO
}

StringValues="DoseReferenceType" {
    TARGET = treatment target (corresponding to GTV, PTV, or CTV in ICRU50),
    ORGAN_AT_RISK = Organ at Risk (as defined in ICRU50)
}

StringValues="DetectorType" {
    DIRECT = X-Ray photoconductor,
    SCINTILLATOR = Phosphor used,
    STORAGE = Storage phosphor,
    FILM = Scanned film/screen,
    CCD = Charge Coupled Devices,
    CMOS = Complementary Metal Oxide Semiconductor,
    PHOTO = Photodetector,
    INT = Interferometer
}

StringValues="RegisteredLocalizerUnits" {
}

StringValues="CompoundGraphicUnits" {
    PIXEL,
    DISPLAY
}

StringValues="QueueStatus" {
}

StringValues="ReasonForTheAttributeModification" {
    COERCE = Replace values of attributes such as Patient Name, ID, Accession Number, for example, during import of media from an external institution, or reconciliation against a master patient index,
    CORRECT = Replace incorrect values, such as Patient Name or ID, for example, when incorrect worklist item was chosen or operator input error
}

StringValues="AcquisitionStatus" {
}

StringValues="FixationDeviceType" {
    BITEBLOCK,
    HEADFRAME,
    MASK,
    MOLD,
    CAST,
    HEADREST,
    BREAST_BOARD,
    BODY_FRAME,
    VACUUM_MOLD,
    WHOLE_BODY_POD,
    RECTAL_BALLOON
}

StringValues="PhaseContrast" {
    YES,
    NO
}

StringValues="ContinuityOfContent" {
    SEPARATE,
    CONTINUOUS
}

StringValues="AnchorPointAnnotationUnits" {
    PIXEL,
    DISPLAY,
    MATRIX
}

StringValues="RETIRED_ThresholdDensity" {
}

StringValues="ComponentTypeCodeSequence" {
}

StringValues="RequestedImageSizeFlag" {
    NO = not supported,
    YES = supported
}

StringValues="SelectorCSValue" {
}

StringValues="SpectrallySelectedSuppression" {
    FAT,
    WATER,
    FAT_AND_WATER,
    SILICON_GEL,
    NONE
}

StringValues="AnchorPointVisibility" {
    Y = yes,
    N = no
}

StringValues="DVHROIContributionType" {
    INCLUDED,
    EXCLUDED
}

StringValues="PartialFourierDirection" {
    PHASE,
    FREQUENCY,
    SLICE_SELECT,
    COMBINATION
}

StringValues="RandomsCorrected" {
    YES,
    NO
}

StringValues="DisplaySetVerticalJustification" {
    TOP,
    CENTER,
    BOTTOM
}

StringValues="PlanesInAcquisition" {
    SINGLE PLANE = Image is a single plane acquisition,
    BIPLANE = Image is part of a Bi-plane acquisition,
    UNDEFINED
}

StringValues="MRAcquisitionType" {
    2D = frequency x phase,
    3D = frequency x phase x phase
}

StringValues="DecayCorrection" {
    NONE = no decay correction,
    START= acquisition start time,
    ADMIN = radiopharmaceutical administration time
}

StringValues="FrameofReferenceTransformationMatrixType" {
    RIGID,
    RIGID_SCALE,
    AFFINE
}

StringValues="RETIRED_TemplateExtensionFlag" {
}

StringValues="ViewPosition" {
    AP = Anterior/Posterior,
    PA = Posterior/Anterior,
    LL = Left Lateral,
    RL = Right Lateral,
    RLD = Right Lateral Decubitus,
    LLD = Left Lateral Decubitus,
    RLO = Right Lateral Oblique,
    LLO = Left Lateral Oblique
}

StringValues="ImplantType" {
    ORIGINAL,
    DERIVED
}

StringValues="WedgeType" {
    STANDARD = standard (static) wedge,
    DYNAMIC = moving beam limiting device (collimator) jaw simulating wedge,
    MOTORIZED = single wedge which can be removed from beam remotely,
    PARTIAL_STANDARD = wedge does not extend across the whole field and is operated manually,
    PARTIAL_MOTORIZ = wedge does not extend across the whole field and can be removed from beam remotely
}

StringValues="FieldofViewShape" {
    RECTANGLE,
    ROUND,
    HEXAGONAL,
    CYLINDRICAL RING,
    MULTIPLE PLANAR
}

StringValues="RETIRED_AnatomicStructure" {
}

StringValues="ScheduledProcedureStepStatus" {
    SCHEDULED = Procedure Step scheduled,
    ARRIVED = patient is available for the Scheduled Procedure Step,
    READY = all patient and other necessary preparation for this step has been completed,
    STARTED = at least one Performed Procedure Step has been created that references this Scheduled Procedure Step,
    DEPARTED = patient is no longer available for the Scheduled Procedure Step
}

StringValues="ReconstructionAlgorithm" {
    FILTER_BACK_PROJ,
    ITERATIVE,
    REPROJECTION,
    RAMLA,
    MLEM
}

StringValues="TransducerType" {
    SECTOR_PHASED,
    SECTOR_MECH,
    SECTOR_ANNULAR,
    LINEAR,
    CURVED LINEAR,
    SINGLE CRYSTAL,
    SPLIT XTAL CWD,
    IV_PHASED,
    IV_ROT XTAL,
    IV_ROT MIRROR,
    ENDOCAV_PA,
    ENDOCAV_MECH,
    ENDOCAV_CLA,
    ENDOCAV_AA,
    ENDOCAV_LINEAR,
    VECTOR_PHASED
}

StringValues="Italic" {
    Y = yes,
    N = no
}

StringValues="PresentationSizeMode" {
    SCALE TO FIT,
    TRUE SIZE,
    MAGNIFY
}

StringValues="ThreatCategory" {
}

StringValues="DataRepresentation" {
    COMPLEX = Data is complex pair,
    REAL = Data contains only real component,
    IMAGINARY = Data contains only imaginary component,
    MAGNITUDE = Magnitude data
}

StringValues="WaveformSampleInterpretation" {
    SB = signed 8 bit linear,
    UB = unsigned 8 bit linear,
    MB = 8 bit mu-law (in accordance with ITU-T Recommendation G.711),
    AB = 8 bit A-law (in accordance with ITU-T Recommendation G.711),
    SS = signed 16 bit linear,
    US = unsigned 16 bit linear
}

StringValues="DetectorConfiguration" {
    AREA = single or tiled detector,
    SLOT = scanned slot, slit or spot
}

StringValues="RawDataHandling" {
}

StringValues="AcquisitionTimeSynchronized" {
    Y,
    N
}

StringValues="CompoundGraphicType" {
    MULTILINE,
    INFINITELINE,
    CUTLINE,
    RANGELINE,
    RULER,
    AXIS,
    CROSSHAIR,
    ARROW,
    ECTANGLE,
    ELLIPSE
}

StringValues="ContentQualification" {
    PRODUCT,
    RESEARCH,
    SERVICE
}

StringValues="ValueType" {
    TEXT,
    CODE,
    NUM,
    NUMERIC,
    DATETIME,
    DATE,
    TIME,
    UIDREF,
    PNAME,
    SCOORD,
    TCOORD,
    COMPOSITE,
    IMAGE,
    WAVEFORM
    CONTAINER
}

StringValues="VisitStatusID" {
    CREATED = Created but not yet scheduled,
    SCHEDULED = Scheduled but not yet admitted,
    ADMITTED = Patient admitted to institution,
    DISCHARGED = Patient Discharged
}

StringValues="AnatomicalOrientationType" {
    BIPED,
    QUADRUPED
}

StringValues="ApplicatorType" {
    ELECTRON_SQUARE = square electron applicator,
    ELECTRON_RECT = rectangular electron applicator,
    ELECTRON_CIRC = circular electron applicator,
    ELECTRON_SHORT = short electron applicator,
    ELECTRON_OPEN = open (dummy) electron applicator,
    PHOTON_SQUARE = square photon applicator,
    PHOTON _RECT = rectangular photon applicator,
    PHOTON _CIRC = circular photon applicator,
    INTRAOPERATIVE = intraoperative (custom) applicator,
    STEREOTACTIC = stereotactic applicator (deprecated)
}

StringValues="InboundArrivalType" {

}

StringValues="TimeofFlightContrast" {
	YES,
	NO
}

StringValues="VerificationImageTiming" {
	BEFORE_BEAM,
	DURING_BEAM,
	AFTER_BEAM
}

StringValues="SecondaryCountsType" {
	DLYD=delayed events,
	SCAT=scattered events in secondary window,
	SING=singles,
	DTIM=events lost due to deadtime
}

StringValues="GraphicAnnotationUnits" {
    LEFT = closest to left edge,
    RIGHT = closest to right edge,
    CENTER = centered
}

StringValues="TransportClassification" {
}

StringValues="SpectrallySelectedExcitation" {
	WATER = water excitation,
	FAT = fat excitation,
	NONE
}

StringValues="TimeOfFlightInformationUsed" {
	TRUE,
	FALSE
}

StringValues="RecommendedViewingMode" {
	SUB = for subtraction with mask images,
	NAT = native viewing of image as stored
}

StringValues="CardiacSynchronizationTechnique" {
	NONE,
	REALTIME = total time for the acquisition is shorter than cardiac cycle, no gating is applied,
	PROSPECTIVE = certain thresholds have been set for a gating window that defines the acceptance of measurement data during the acquisition,
	RETROSPECTIVE =	certain thresholds have been set for a gating window that defines the acceptance of measurement data after the acquisition,
	PACED = there is a constant RR interval (e.g., Pacemaker), which makes thresholding not required
}

StringValues="NonUniformRadialSamplingCorrected" {
	YES,
	NO
}

StringValues="ACR_NEMA_2C_CompressionSequence" {
}

StringValues="StimulusResults" {
	SEEN = stimulus seen at a luminance value less than maximum,
	NOT SEEN = stimulus not seen,
	SEEN AT MAX = stimulus seen at the maximum luminance possible for the instrument
}

StringValues="EquipmentCoordinateSystemIdentification" {
	ISOCENTER
}

StringValues="FirstOrderPhaseCorrection" {
	YES,
	NO
}

StringValues="Multi-CoilElementUsed" {
	YES,
	NO
}

StringValues="ObserverType" {
	PSN = Person (manually selected),
	DEV = Device (automatically selected)
}

StringValues="RETIRED_LossyImageCompressionRetired" {
}

StringValues="CurvatureType" {
}

StringValues="FrameType" {
	ORIGINAL\?\* = pixel values are based on original or source data,
	DERIVED\?\* = pixel values have been derived in some manner from the pixel value of one or more other images,
	?\PRIMARY\* = image created as a direct result of the Patient examination,
	?\SECONDARY\* = image created after the initial Patient examination
}

StringValues="De-coupling" {
	YES,
	NO
}

StringValues="QualityControlImage" {
	YES,
	NO
}

StringValues="PositionerMotion" {
	DYNAMIC = the imaging table moves during a multi-frame acquisition, but the X-Ray positioner do not move,
	STATIC
}

StringValues="DataPathAssignment" {
	PRIMARY_PVALUES = Data Frame values are passed through the Presentation LUT to produce grayscale P-values. No blending is performed,
	PRIMARY_SINGLE = Data Frame values are inputs to the Primary Palette Color Lookup Table,
	SECONDARY_SINGLE = Data Frame values are inputs to the Secondary Palette Color Lookup Table,
	SECONDARY_HIGH = Data Frame values having Data Path Assignment (0028,1402) of SECONDARY_LOW are concatenated as the least significant bits with Data Frame values having Data Path Assignment of SECONDARY_HIGH to form inputs to the Secondary Palette Color Lookup Table,
	SECONDARY_LOW = Data Frame values having Data Path Assignment (0028,1402) of SECONDARY_LOW are concatenated as the least significant bits with Data Frame values having Data Path Assignment of SECONDARY_HIGH to form inputs to the Secondary Palette Color Lookup Table
}

StringValues="RETIRED_OverlayMode" {
}

StringValues="RefractiveProcedureOccurred" {
	YES,
	NO
}

StringValues="SpecificCharacterSet" {
	none = Default repertoire,
	ISO_IR 100 = Latin alphabet No. 1,
	ISO_IR 101 = Latin alphabet No. 2,
	ISO_IR 109 = Latin alphabet No. 3,
	ISO_IR 110 = Latin alphabet No. 4,
	ISO_IR 144 = Cyrillic,
	ISO_IR 127 = Arabic,
	ISO-IR 126 = Greek,
￼￼￼￼￼￼￼	￼ISO_IR 138 = Hebrew,
	ISO-IR 148 = Latin alphabet No. 5,
	ISO_IR 13 = Japanese,
	ISO-IR 166 = Thai,
	ISO 2022 IR 6 = Default repertoire,
	ISO 2022 IR 100 = Latin alphabet No. 1,
	ISO 2022 IR 101 = Latin alphabet No. 2,
	ISO 2022 IR 109 = Latin alphabet No. 3,
	ISO 2022 IR 110 = Latin alphabet No. 4,
	ISO 2022 IR 144 = Cyrillic,
	ISO 2022 IR 127 = Arabic,
	ISO 2022 IR 126 = Greek,
	ISO 2022 IR 138 = Hebrew,
	ISO 2022 IR 148 = Latin alphabet No. 5,
	ISO 2022 IR 13 = Japanese,
	ISO 2022 IR 166 = Thai,
	ISO 2022 IR 87 = Japanese,
	ISO 2022 IR 159 = Japanese,
	ISO 2022 IR 149 = Korean,
	ISO_IR 192 = Unicode in UTF-8,
	GB18030 = GB18030
}

StringValues="OCTAcquisitionDomain" {
	TIME,
	FREQUENCY,
	SPECTRAL
}

StringValues="RequestPriority" {
	HIGH,
	MED,
	SLOW
}

StringValues="UltrasoundAcquisitionGeometry" {
	APEX = there exists an apex of the scan lines from which the volume data was acquired
}

StringValues="CompletionFlag" {
	PARTIAL = Partial content,
	COMPLETE = Complete content
}

StringValues="ImplantAssemblyTemplateType" {
	ORIGINAL,
	DERIVED
}

StringValues="HorizontalPrismBase" {
	IN,
	OUT
}

StringValues="ResponsiblePersonRole" {
	OWNER,
	PARENT,
	CHILD,
	SPOUSE,
	SIBLING,
	RELATIVE,
	GUARDIAN,
	CUSTODIAN,
	AGENT
}

StringValues="ArterialSpinLabelingContrast" {
	CONTINUOUS = a single long low powered RF pulse,
	PSEUDOCONTINUOUS = multiple short low powered RF pulses,
	PULSED = a single short high powered RF pulse
}

StringValues="TypeOfData2" {
}

StringValues="ResonantNucleus" {
	1H,
	3HE,
	7LI,
	13C,
	19F,
	23NA,
	31P,
	129XE
}

StringValues="ConvolutionKernelGroup" {
	BRAIN,
	SOFT_TISSUE,
	LUNG,
	BONE,
	CONSTANT_ANGLE
}

StringValues="ShapeType" {
	POINT = a single point designating a single fiducial point,
	LINE = two points that specify a line or axis such as the inter-orbital line,
	PLANE = three points that identify a plane such as the laterality plane,
	SURFACE = three or more points (usually many) that reside on, or near, a region of a curved surface. The surface may be flat or curved, closed or open. The point order has no significance,
	RULER = two or more evenly spaced collinear points ordered sequentially along the line, such as a physical ruler placed in the imaging field,
	L_SHAPE = three points of two perpendicular line segments, AB and BC, having a common end point B. The order of the points is: ABC. May represent an L-shaped marker placed in the imaging field,
	T_SHAPE = three points of two perpendicular line segments AB and CD, such that C bisects AB. The order is ABD,
	SHAPE = three or more points that specify the shape of a well-known fiducial type. The term in the Fiducial Identifier Code Sequence (0070,0311) defines the shape and the order of the points that represent it
}

StringValues="ReportedValuesOrigin" {
	OPERATOR = manually entered by operator,
	PLAN = planned parameter values,
	ACTUAL = electronically recorded
}

StringValues="InterpolationType" {
	REPLICATE,
	BILINEAR,
	CUBIC
}

StringValues="TreatmentVerificationStatus" {
	VERIFIED = treatment verified
	VERIFIED_OVR = treatment verified with at least one out-of-range value overridden,
	NOT_VERIFIED = treatment verified manually
}

StringValues="ApprovalStatus" {
	APPROVED = Reviewer recorded that object met an implied criterion,
	UNAPPROVED = No review of object has been recorded,
	REJECTED = Reviewer recorded that object failed to meet an implied criterion
}

StringValues="AbortFlag" {
}

StringValues="ProcedureStepState" {
	SCHEDULED,
	IN PROGRESS,
	CANCELED,
	COMPLETED
}

StringValues="RecommendedPresentationType" {
	SURFACE = Render the surface as a solid, applying the opacity as specified in the Recommended Presentation Opacity (0066,000C) attribute,
	WIREFRAME = Represent the surface as a series of lines connecting the vertices to form the defined primitive faces,
	POINTS Represent the surface as a cloud of points.
}

StringValues="InputReadinessState" {
}

StringValues="PhantomType" {
}

StringValues="MeasuredDoseType" {
	DIODE = semiconductor diode
	TLD = thermoluminescent dosimeter,
	ION_CHAMBER = ion chamber,
	GEL = dose sensitive gel
	EPID = electronic portal imaging device,
	FILM = dose sensitive film
}

StringValues="BeamTaskType" {
	VERIFY = Beam verification only,
	TREAT = Beam treatment only,
	VERIFY_AND_TREAT = Beam verification and treatment
}

StringValues="ExcessiveFalsePositivesDataFlag" {
	YES,
	NO
}

StringValues="BulkMotionStatus" {
}

StringValues="Spoiling" {
	RF = RF spoiled,
	GRADIENT = gradient spoiled,
	RF_AND_GRADIENT
	NONE
}

StringValues="RTPlanRelationship" {
	PRIOR = plan delivered prior to current treatment,
	ALTERNATIVE = alternative plan prepared for current treatment,
	PREDECESSOR = plan used in derivation of current plan,
	VERIFIED_PLAN = plan which is verified using the current plan. This value shall only be used if Plan Intent (300A,000A) is present and has a value of VERIFICATION,
	CONCURRENT = plan that forms part of a set of two or more RT Plan instances representing a single conceptual 'plan', applied in parallel in one treatment phase
}

StringValues="ACR_NEMA_GrayScale" {
}

StringValues="ExclusiveComponentType" {
	YES,
	NO
}

StringValues="LocalDeviationProbabilityNormalsFlag" {
	YES,
	NO
}

StringValues="Decimate/CropResult" {
	DECIMATE = image will be decimated to fit,
	CROP = image will be cropped to fit,
	FAIL = N-SET of the Image Box will fail,
	DEF DECIMATE = image will be decimated to fit,
	DEF CROP = image will be cropped to fit,
	DEF FAIL = N-SET of the Image Box will fail
}

StringValues="OperatingModeType" {
	STATIC FIELD,
	RF,
	GRADIENT
}

StringValues="SpatialPre-saturation" {
	SLAB,
	NONE
}

StringValues="ReconstructionType" {
	2D,
	3D,
	3D_REBINNED
}

StringValues="PatientsSex" {
	M = male,
	F = female,
	O = other
}

StringValues="SensitivityCalibrated" {
	YES,
	NO
}

StringValues="WaterReferencedPhaseCorrection" {
	YES,
	NO
}

StringValues="AngioFlag" {
	Y = Image is Angio,
	N = Image is not Angio
}

StringValues="PrimaryDosimeterUnit" {
	MU = Monitor Unit,
	MINUTE = minute,
	NP = number of particles
}

StringValues="OverlayForegroundDensity" {
}

StringValues="ImageBoxScrollDirection" {
	VERTICAL = scroll images by row,
	HORIZONTAL = scroll images by column
}

StringValues="BeamType" {
	STATIC = All Control Point Sequence (300A,0111) attributes remain unchanged between consecutive pairs of control points with changing Cumulative Meterset Weight (300A,0134),
	DYNAMIC = One or more Control Point Sequence (300A,0111) attributes change between one or more consecutive pairs of control points with changing Cumulative Meterset Weight (300A,0134)
}

StringValues="BurnedInAnnotation" {
	YES,
	NO
}

StringValues="FrequencyCorrection" {
	YES,
	NO
}

StringValues="UniversalEntityIDType" {
	DNS = An Internet dotted name. Either in ASCII or as integers,
	EUI64 = An IEEE Extended Unique Identifier,
	ISO = An International Standards Organization Object Identifier,
	URI = Uniform Resource Identifier,
	UUID = The DCE Universal Unique Identifier,
	X400 = An X.400 MHS identifier X500 An X.500 directory name
}

StringValues="EmptyImageDensity" {
	BLACK,
	WHITE,
	i = where i represents the desired density in hundredths of OD (e.g. 150 corresponds with 1.5 OD)
}

StringValues="TomoType" {
	LINEAR,
	SPIRAL,
	POLYCYCLOIDAL,
	CIRCULAR
}

StringValues="ATDAbilityAssessment" {
}

StringValues="InputAvailabilityFlag" {
	PARTIAL = the list of Composite SOP Instances may not yet be complete, and additional ones may be added at a later time,
	COMPLETE = all Composite SOP Instances are available and listed
}

StringValues="TickAlignment" {
	BOTTOM = ticks are aligned to the lower part of the line, where the first point of the line is on the left and the line extends horizontally to the right,
	CENTER = ticks are centered on the line,
	TOP = ticks are aligned to the upper part of the line, where the first point of the line is on the left and the line extends horizontally to the right
}

StringValues="ExcessiveFixationLosses" {
	YES,
	NO
}

StringValues="FiniteVolume" {
	YES = Contains a finite volume,
	NO = Does not contain a finite volume,
	UNKNOWN = Might or might not contain a finite volume
}

StringValues="SOPInstanceStatus" {
	NS = Not Specified,
	OR = Original,
	AO = Authorized Original,
	AC = Authorized Copy
}

StringValues="BlindSpotLocalized" {
	YES,
	NO
}

StringValues="TimeDistributionProtocol" {
	NTP = Network Time Protocol,
	IRIG = InterRange Instrumentation Group,
	GPS = Global Positioning System,
	SNTP = Simple Network Time Protocol,
	PTP = IEEE 1588 Precision Time Protocol
}

StringValues="ExcessiveFalseNegativesDataFlag" {
	YES,
	NO
}

StringValues="ContentLabel" {
}

StringValues="Laterality" {
	R = right,
	L = left,
	U = unpaired,
	B = both left and right
}

StringValues="FovealPointNormativeDataFlag" {
	YES,
	NO
}

StringValues="ExcessiveFalsePositives" {
	YES,
	NO
}

StringValues="SteadyStatePulseSequence" {
	FREE_PRECESSION,
	TRANSVERSE,
	TIME_REVERSED,
	LONGITUDINAL NONE
}

StringValues="DoubleExposureFlag" {
	SINGLE = single exposure,
	DOUBLE = double exposure
}

StringValues="DVHVolumeUnits" {
	CM3 = cubic centimeters,
	PERCENT = percent,
	PER_U= volume per u
}

StringValues="OperatingMode" {
	IEC_NORMAL,
	IEC_FIRST_LEVEL,
	IEC_SECOND_LEVEL
}

StringValues="Tagging" {
	GRID,
	LINE,
	NONE
}

StringValues="CompensatorType" {
	STANDARD = physical (static) compensator,
	DYNAMIC = moving Beam Limiting Device (collimator) simulating physical compensator
}

StringValues="DetectorNormalizationCorrection" {
	YES,
	NO
}

StringValues="BodyPartExamined" {
}

StringValues="RetestStimulusSeen" {
	YES,
	NO
}

StringValues="OverlaySmoothingType" {
}

StringValues="ReformattingOperationInitialViewDirection" {
	SAGITTAL,
	TRANSVERSE,
	CORONAL,
	OBLIQUE
}

StringValues="RETIRED_TherapyType" {
}

StringValues="RecognizableVisualFeatures" {
	YES,
	NO
}

StringValues="ExposureControlSensingRegionShape" {
	RECTANGULAR,
	CIRCULAR,
	POLYGONAL
}

StringValues="DefaultMagnificationType" {
	REPLICATE,
	BILINEAR,
	CUBIC,
	NONE
}

StringValues="OphthalmicMappingDeviceType" {
}

StringValues="ReferencedFileID" {
}

StringValues="PlaneIdentification" {
	MONOPLANE,
	PLANE A,
	PLANE B
}

StringValues="VerificationFlag" {
	UNVERIFIED = Not attested by a legally accountable person,
	VERIFIED = Attested to (signed) by a Verifying Observer or Legal Authenticator named in the document, who is accountable for its content
}

StringValues="BorderDensity" {
	BLACK,
	WHITE,
	i = where i represents the desired density in hundredths of OD (e.g. 150 corresponds with 1.5 OD)
}

StringValues="RelativeTimeUnits" {
	SECONDS,
	MINUTES,
	HOURS,
	DAYS,
	WEEKS,
	MONTHS,
	YEARS
}

StringValues="BlockType" {
	SHIELDING = blocking material is inside contour,
	APERTURE = blocking material is outside contour
}

StringValues="HorizontalAlignment" {
	LEFT,
	CENTER,
	RIGHT
}

StringValues="RTImagePlane" {
	NORMAL = image plane normal to beam axis,
	NON_NORMAL = image plane non-normal to beam axis
}

StringValues="TomoClass" {
	MOTION,
	TOMOSYNTHESIS
}

StringValues="ATDAssessmentFlag" {
}

StringValues="RelationshipType" {
	CONTAINS = Source Item contains Target Content Item,
	HAS PROPERTIES = Description of properties of the Source Content Item,
	HAS OBS CONTEXT = Target Content Items shall convey any specialization of Observation Context needed for unambiguous documentation of the Source Content Item,
	HAS ACQ CONTEXT = The Target Content Item describes the conditions present during data acquisition of the Source Content Item,
	INFERRED FROM = Source Content Item conveys a measurement or other inference made from the Target Content Items. Denotes the supporting evidence for a measurement or judgment,
	SELECTED FROM = Source Content Item conveys spatial or temporal coordinates selected from the Target Content Item(s),
	HAS CONCEPT MOD = Used to qualify or describe the Concept Name of the Source Content item, such as to create a post-coordinated description of a concept, or to further describe a concept
}

StringValues="SourceStrengthUnits" {
	AIR_KERMA_RATE = Air Kerma Rate if Source is Gamma emitting Isotope,
	DOSE_RATE_WATER = Dose Rate in Water if Source is Beta emitting Isotope
}

StringValues="RETIRED_ObservationSubjectContextFlagTrial" {
}

StringValues="DetectorGeometry" {
	CYLINDRICAL_RING,
	CYL_RING_PARTIAL,
	MULTIPLE_PLANAR,
	MUL_PLAN_PARTIAL
}

StringValues="SetupTechnique" {
	ISOCENTRIC,
	FIXED_SSD,
	TBI BREAST_BRIDGE,
	SKIN_APPOSITION
}

StringValues="SynchronizationTrigger" {
	SOURCE = this equipment provides synchronization channel or trigger to other equipment,
	EXTERNAL = this equipment receives synchronization channel or trigger from other equipment,
	PASSTHRU = this equipment receives synchronization channel or trigger and forwards it,
	NO TRIGGER = data acquisition not synchronized by common channel or trigger
}

StringValues="ExcessiveFalseNegatives" {
	YES,
	NO
}

StringValues="ScanType" {
}

StringValues="CarrierIDAssigningAuthority" {
}

StringValues="VisualFieldTestNormalsFlag" {
	YES,
	NO
}

StringValues="EchoPlanarPulseSequence" {
	YES,
	NO
}

StringValues="MandatoryComponentType" {
	YES,
	NO
}

StringValues="ShortTermFluctuationCalculated" {
	YES,
	NO
}

StringValues="SpecificAbsorptionRateDefinition" {
	IEC_WHOLE_BODY,
	IEC_PARTIAL_BODY,
	IEC_HEAD,
	IEC_LOCAL
}

StringValues="OversamplingPhase" {
	2D = phase direction,
	3D = out of plane direction,
	2D_3D = both,
	NONE
}

StringValues="DecayCorrected" {
	YES,
	NO
}

StringValues="AnodeTargetMaterial" {
	TUNGSTEN,
	MOLYBDENUM,
	RHODIUM
}

StringValues="ExecutionStatusInfo" {
	NORMAL,
	INVALID PAGE DES = The specified page layout cannot be printed or other page description errors have been detected,
	CHECK_MCD_OP = The media creation request could not be accomplished since the device is not ready at this time and needs to be checked by an operator (e.g., covers/doors opened or device jammed),
	CHECK_MCD_SRV = The media creation request could not be accomplished since the device is not ready at this time and needs to be checked by a vendor service engineer (e.g., internal component failure),
	DIR_PROC_ERR = The DICOMDIR building process failed for some unspecified reason (e.g., mandatory attributes or values missing),
	DUPL_REF_INST = Duplicated instances in the Referenced SOP Sequence (0008,1199),
	INST_AP_CONFLICT = One or more of the elements in the Referenced SOP Sequence (0008,1199) are in conflict (e.g., the SOP Class specified is not consistent with the requested Application Profile),
	INST_OVERSIZED = A single instance size exceeds the actual media capacity. Note: DICOM media does not support spanning of instances,
	INSUFFIC MEMORY = There is not enough memory available to complete this request,
	MCD_BUSY = Media creation device is not available at this time, but should become ready without user intervention (e.g the media creation device's buffer capacity is full). The SCU should retry later,
	MCD_FAILURE = Media creation device fails to operate. This may depend on permanent or transient hardware failures (e.g robot arm broken, DVD writer failed) or because it has been disabled by an operator,
	NO_INSTANCE = One or more of the SOP Instances in the Referenced SOP Sequence (0008,1199) are not available,
	NOT_SUPPORTED = One or more of the Application Profiles, and/or SOP Classes, referenced in the Referenced SOP Sequence (0008,1199) are not supported by the SCP,
	OUT_OF_SUPPLIES = No more supplies (e.g., blank media, labeling ink) are available for the media creation device. Operator intervention is required to replenish the supply,
	PROC_FAILURE = A general processing failure was encountered,
	QUEUED = This Media Creation Management instance is still in queue,
	SET_OVERSIZED = The file-set size exceeds the actual media capacity, and the device is not capable of splitting across multiple pieces of media,
	UNKNOWN = ￼There is an unspecified problem,
	BAD RECEIVE MGZ = There is a problem with the film receive magazine. Films from the printer cannot be transported into the magazine,
	BAD SUPPLY MGZ = There is a problem with a film supply magazine. Films from this magazine cannot be transported into the printer,
	CALIBRATING = Printer is performing self calibration, it is expected to be available for normal operation shortly,
	CALIBRATION ERR = An error in the printer calibration has been detected, quality of processed films may not be optimal,
	CHECK CHEMISTRY = A problem with the processor chemicals has been detected, quality of processed films may not be optimal,
	CHECK SORTER = There is an error in the film sorter,
	CHEMICALS EMPTY = There are no processing chemicals in the processor, films will not be printed and processed until the processor is back to normal,
	CHEMICALS LOW = The chemical level in the processor is low, if not corrected, it will probably shut down soon,
	COVER OPEN = One or more printer or processor covers, drawers, doors are open,
	ELEC CONFIG ERR = Printer configured improperly for this job,
	ELEC DOWN = Printer is not operating due to some unspecified electrical hardware problem,
	ELEC SW ERROR = Printer not operating for some unspecified software error,
	EMPTY 8X10 = The 8x10 inch film supply magazine is empty,
	EMPTY 8X10 BLUE = The 8x10 inch blue film supply magazine is empty,
	EMPTY 8X10 CLR = The 8x10 inch clear film supply magazine is empty,
	EMPTY 8X10 PAPR = The 8x10 inch paper supply magazine is empty,
	EMPTY 10X12 = The 10x12 inch film supply magazine is empty,
	EMPTY 10X12 BLUE = The 10x12 inch blue film supply magazine is empty,
	EMPTY 10X12 CLR = The 10x12 inch clear film supply magazine is empty,
	EMPTY 10X12 PAPR = The 10x12 inch paper supply magazine is empty,
	EMPTY 10X14 = The 10x14 inch film supply magazine is empty,
	EMPTY 10X14 BLUE = The 10x14 inch blue film supply magazine is empty,
	EMPTY 10X14 CLR = The 10x14 inch clear film supply magazine is empty,
	EMPTY 10X14 PAPR = The 10x14 inch paper supply magazine is empty,
	EMPTY 11X14 = The 11x14 inch film supply magazine is empty,
	EMPTY 11X14 BLUE = The 11x14 inch blue film supply magazine is empty,
	EMPTY 11X14 CLR = The 11x14 inch clear film supply magazine is empty,
	EMPTY 11X14 PAPR = The 11x14 inch paper supply magazine is empty,
	EMPTY 14X14 = The 14x14 inch film supply magazine is empty,
	EMPTY 14X14 BLUE = The 14x14 inch blue film supply magazine is empty,
	EMPTY 14X14 CLR = The 14x14 inch clear film supply magazine is empty,
	EMPTY 14X14 PAPR = The 14x14 inch paper supply magazine is empty,
	EMPTY 14X17 = The 14x17 inch film supply magazine is empty,
	EMPTY 14X17 BLUE = The 14x17 inch blue film supply magazine is empty,
	EMPTY 14X17 CLR = The 14x17 inch clear film supply magazine is empty,
	EMPTY 14X17 PAPR = The 14x17 inch paper supply magazine is empty,
	EMPTY 24X24 = The 24x24 cm film supply magazine is empty,
	EMPTY 24X24 BLUE = The 24x24 cm blue film supply magazine is empty,
	EMPTY 24X24 CLR = The 24x24 cm clear film supply magazine is empty,
	EMPTY 24X24 PAPR = The 24x24 cm paper supply magazine is empty,
	EMPTY 24X30 = The 24x30 cm film supply magazine is empty,
	EMPTY 24X30 BLUE = The 24x30 cm blue film supply magazine is empty,
	EMPTY 24X30 CLR = The 24x30 cm clear film supply magazine is empty,
	EMPTY 24X30 PAPR = The 24x30 cm paper supply magazine is empty,
	EMPTY A4 PAPR = The A4 paper supply magazine is empty,
	EMPTY A4 TRANS = The A4 transparency supply magazine is empty,
	EXPOSURE FAILURE = The exposure device has failed due to some unspecified reason,
	FILM JAM = A film transport error has occurred and a film is jammed in the printer or processor,
	FILM TRANSP ERR = There is a malfunction with the film transport, there may or may not be a film jam,
	FINISHER EMPTY = The finisher is empty,
	FINISHER ERROR = The finisher is not operating due to some unspecified reason,
	FINISHER LOW = The finisher is low on supplies,
	LOW 8X10 = The 8x10 inch film supply magazine is low,
	LOW 8X10 BLUE = The 8x10 inch blue film supply magazine is low,
	LOW 8X10 CLR = The 8x10 inch clear film supply magazine is low,
	LOW 8X10 PAPR = The 8x10 inch paper supply magazine is low,
	LOW 10X12 = The 10x12 inch film supply magazine is low,
	LOW 10X12 BLUE = The 10x12 inch blue film supply magazine is low,
	LOW 10X12 CLR = The 10x12 inch clear film supply magazine is low,
	LOW 10X12 PAPR = The 10x12 inch paper supply magazine is low,
	LOW 10X14 = The 10x14 inch film supply magazine is low,
	LOW 10X14 BLUE = The 10x14 inch blue film supply magazine is low,
	LOW 10X14 CLR = The 10x14 inch clear film supply magazine is low,
	LOW 10X14 PAPR = The 10x14 inch paper supply magazine is low,
	LOW 11X14 = The 11x14 inch film supply magazine is low,
	LOW 11X14 BLUE = The 11x14 inch blue film supply magazine is low,
	LOW 11X14 CLR = The 11x14 inch clear film supply magazine is low,
	LOW 11X14 PAPR = The 11x14 inch paper supply magazine is low,
	LOW 14X14 = The 14x14 inch film supply magazine is low,
	LOW 14X14 BLUE = The 14x14 inch blue film supply magazine is low,
	LOW 14X14 CLR = The 14x14 inch clear film supply magazine is low,
	LOW 14X14 PAPR = The 14x14 inch paper supply magazine is low,
	LOW 14X17 = The 14x17 inch film supply magazine is low,
	LOW 14X17 BLUE = The 14x17 inch blue film supply magazine is low,
	LOW 14X17 CLR = The 14x17 inch clear film supply magazine is low,
	LOW 14X17 PAPR = The 14x17 inch paper supply magazine is low,
	LOW 24X24 = The 24x24 cm film supply magazine is low,
	LOW 24X24 BLUE = The 24x24 cm blue film supply magazine is low,
	LOW 24X24 CLR = The 24x24 cm clear film supply magazine is low,
	LOW 24X24 PAPR = The 24x24 cm paper supply magazine is low,
	LOW 24X30 = The 24x30 cm film supply magazine is low,
	LOW 24X30 BLUE = The 24x30 cm blue film supply magazine is low,
	LOW 24X30 CLR = The 24x30 cm clear film supply magazine is low,
	LOW 24X30 PAPR = The 24x30 cm paper supply magazine is low,
	LOW A4 PAPR = The A4 paper supply magazine is low,
	LOW A4 TRANS = The A4 transparency supply magazine is low,
	NO RECEIVE MGZ = The film receive magazine not available,
	NO RIBBON = ￼￼￼￼￼￼￼￼￼￼The ribbon cartridge needs to be replaced,
	NO SUPPLY MGZ = The film supply magazine specified for this job is not available,
	CHECK PRINTER = The printer is not ready at this time, operator intervention is required to make the printer available,
	CHECK PROC = The processor is not ready at this time, operator intervention is required to make the printer available,
	PRINTER DOWN = The printer is not operating due to some unspecified reason,
	PRINTER BUSY = Printer is not available at this time, but should become ready without user intervention. This is to handle non-initialization instances,
	PRINT BUFF FULL = The Printer ‘s buffer capacity is full. The printer is unable to accept new images in this state. The printer will correct this without user intervention. The SCU should retry later,
	PRINTER INIT = The printer is not ready at this time, it is expected to become available without intervention. For example, it may be in a normal warm-up state,
	PRINTER OFFLINE = The printer has been disabled by an operator or service person,
	PROC DOWN = The processor is not operating due to some unspecified reason,
	PROC INIT = The processor is not ready at this time, it is expected to become available without intervention. For example, it may be in a normal warm-up state,
	PROC OVERFLOW FL = Processor chemicals are approaching the overflow full mark,
	PROC OVERFLOW HI = Processor chemicals have reached the overflow full mark,
	QUEUED = Print Job in Queue,
	RECEIVER FULL = The Film receive magazine is full,
	REQ MED NOT INST = The requested film, paper, or other media supply magazine is installed in the printer, but may be available with operator intervention,
	REQ MED NOT AVAI = The requested film, paper, or other media requested is not available on this printer,
	RIBBON ERROR = There is an unspecified problem with the print ribbon,
	SUPPLY EMPTY = The printer is out of film,
	SUPPLY LOW = The film supply is low
}

StringValues="IterativeReconstructionMethod" {
	YES,
	NO
}

StringValues="LUTFunction" {
	TO_LOG,
	TO_LINEAR
}

StringValues="OverlayMagnificationType" {
}

StringValues="OphthalmicAxialMeasurementsDeviceType" {
	ULTRASOUND,
	OPTICAL
}

StringValues="ContrastBolusIngredientOpaque" {
	YES,
	NO
}

StringValues="OverlayBackgroundDensity" {
}

StringValues="ImageBoxSmallScrollType" {
	PAGE: In a TILED image box, replace all image slots with the next N x M images in the set,
	ROW_COLUMN: in a TILED image box, move each row or column of images to the next row or column, depending on Image Box Scroll Direction (0072,0310),
	IMAGE: In a TILED image box, move each image to the next slot, either horizontally or vertically, depending on Image Box Scroll Direction (0072,0310)
}

StringValues="InterventionStatus" {
	PRE,
	INTERMEDIATE,
	POST,
	NONE
}

StringValues="LabelUsingInformationExtractedFromInstances" {
	YES,
	NO
}

StringValues="RadiationType" {
	PHOTON,
	ELECTRON,
	NEUTRON,
	PROTON,
	ION
}

StringValues="LongitudinalTemporalInformationModified" {
	UNMODIFIED,
	MODIFIED,
	REMOVED
}

StringValues="TreatmentIntent" {
	CURATIVE = curative therapy on patient,
	PALLIATIVE = palliative therapy on patient,
	PROPHYLACTIC = preventative therapy on patient,
	VERIFICATION = verification of patient plan using phantom,
	MACHINE_QA= Quality assurance of the delivery machine (independently of a specific patient),
	RESEARCH = Research project,
	SERVICE = Machine repair or maintenance operation
}

StringValues="BlendingLUT1TransferFunction" {
	CONSTANT = A constant floating point value from 0.0 to 1.0, inclusive,
	ALPHA_1 = Pass-through the Alpha 1 input value from the Alpha Palette Color Lookup Table of the Primary data path,
	ALPHA_2 = Pass-through the Alpha 2 input value from the Alpha Palette Color Lookup Table of the Secondary data path,
	TABLE = The output of a Table defining a function of the Alphas from both data paths,
}

StringValues="TypeOfData8" {
}

StringValues="OtherMagnificationTypesAvailable" {
	REPLICATE,
	BILINEAR,
	CUBIC,
	NONE
}

StringValues="PartialView" {
	YES,
	NO
}

StringValues="ImageType" {
	ORIGINAL\?\* = pixel values are based on original or source data,
	DERIVED\?\* = pixel values have been derived in some manner from the pixel value of one or more other images,
	?\PRIMARY\* = image created as a direct result of the Patient examination,
	?\SECONDARY\* = image created after the initial Patient examination
}

StringValues="ArchiveRequested" {
	NO,
	YES
}

StringValues="SourceApplicatorType" {
	FLEXIBLE,
	RIGID
}

StringValues="ExposureControlMode" {
	MANUAL,
	AUTOMATIC
}

StringValues="VerticalAlignment" {
	TOP,
	CENTER,
	BOTTOM
}

StringValues="IdentifierTypeCode" {
	AM = American Express,
	AN = Account number,
	B = Blank (no identifier is available),
	BA = Bank Account Number,
	BR = Birth registry number,
	BRN = Breed Registry Number,
	DI = Diner's Club card,
	DL = Driver's license number,
	DN = Doctor number,
	DR = Donor Registration Number,
	DS = Discover Card,
	EI = Employee number,
	EN = Employer number,
	FI = Facility ID,
	GI = Guarantor internal identifier,
	GN = Guarantor external identifier,
	HC = Health Card Number,
	JHN = Jurisdictional health number (Canada),
	LN = License number,
	LR = Local Registry ID,
	MA = Medicaid number,
	MC = Medicare number,
	MCN = Microchip Number,
	MR = Medical record number,
	MS = MasterCard,
	NE = National employer identifier,
	NH = National Health Plan Identifier,
	NI = National unique individual identifier,
	NNxxx = National Person Identifier where the xxx is the ISO table 3166 3-character (alphabetic) country code,
	NPI = National provider identifier,
	PEN = Pension Number,
	PI = Patient internal identifier,
	PN = Person number,
	PRN = Provider number,
	PT = Patient external identifier,
	RR = Railroad Retirement number,
	RRI = Regional registry ID,
	SL = State license,
	SR = State registry ID,
	SS = Social Security number,
	U = Unspecified,
	UPIN = Medicare/HCFA's Universal Physician Identification numbers,
	VN = Visit number,
	VS = VISA,
	WC = WIC identifier,
	WCN = Workers' Comp Number,
	XX = Organization identifier
}

StringValues="TableTopPitchRotationDirection" {
	CW = clockwise,
	CC = counter-clockwise,
	NONE = no rotation
}

StringValues="CoordinateSystemAxisType" {
}

StringValues="LineDashingStyle" {
	SOLID,
	DASHED
}

StringValues="DVHType" {
	DIFFERENTIAL = differential dose-volume histogram,
	CUMULATIVE = cumulative dose-volume histogram,
	NATURAL = natural dose volume histogram
}

StringValues="FrameLaterality" {
	R = right,
	L = left,
	U = unpaired,
	B = both left and right
}

StringValues="DoseReferenceStructureType" {
	POINT = dose reference point specified as ROI,
	VOLUME = dose reference volume specified as ROI,
	COORDINATES = point specified by Dose Reference Point Coordinates (300A,0018),
	SITE = dose reference clinical site
}

StringValues="ContextGroupExtensionFlag" {
	Y,
	N
}

StringValues="ACR_NEMA_2C_CompressionRecognitionCode" {
}

StringValues="TDRType" {
}

StringValues="SortByCategory" {
	ALONG_AXIS = for CT, MR, other cross-sectional image sets,
	BY_ACQ_TIME
}

StringValues="PartialFourier" {
	YES,
	NO
}

StringValues="RETIRED_ObserverContextFlagTrial" {
}

StringValues="DiffusionAnisotropyType" {
	FRACTIONAL,
	RELATIVE,
	VOLUME_RATIO
}

StringValues="ImageSetSelectorCategory" {
	RELATIVE_TIME,
	ABSTRACT_PRIOR
}

StringValues="PatientSexNeutered" {
	ALTERED = Altered/Neutered,
	UNALTERED = Unaltered/intact
}

StringValues="FalsePositivesEstimateFlag" {
	YES,
	NO
}

StringValues="ImageLaterality" {
	R = right,
	L = left,
	U = unpaired,
	B = both left and right (e.g. cleavage, midline, eyes)
}

StringValues="RETIRED_MeasurementAutomationTrial" {
}

StringValues="EchoPulseSequence" {
	SPIN,
	GRADIENT,
	BOTH
}

StringValues="CardiacBeatRejectionTechnique" {
	NONE,
	RR_INTERVAL = rejection based on deviation from average RR interval,
	QRS_LOOP = rejection based on deviation from regular QRS loop,
	PVC = rejection based on PVC criteria
}

StringValues="TreatmentDeliveryType" {
	TREATMENT = normal patient treatment,
	OPEN_PORTFILM = portal image acquisition with open field,
	TRMT_PORTFILM = portal image acquisition with treatment port,
	CONTINUATION = continuation of interrupted treatment,
	SETUP = no treatment beam is applied for this RT Beam. To be used for specifying the gantry, couch, and other machine positions where X-Ray set-up images or measurements are to be taken,
	VERIFICATION = Treatment used for Quality Assurance rather than patient treatment
}

StringValues="CollimatorType" {
	PARA = Parallel (default),
	PINH = Pinhole,
	FANB = Fan-beam,
	CONE = Cone-beam,
	SLNT = Slant hole,
	ASTG = Astigmatic,
	DIVG = Diverging,
	NONE = No collimator,
	RING = Transverse septa,
	UNKN = Unknown
}

StringValues="DoubleExposureOrdering" {
	OPEN_FIRST = Open field first,
	OPEN_SECOND = Open field second
}

StringValues="BlendingLUT2TransferFunction" {
	CONSTANT = A constant floating point value from 0.0 to 1.0, inclusive,
	ALPHA_1 = Pass-through the Alpha 1 input value from the Alpha Palette Color Lookup Table of the Primary data path,
	ALPHA_2 = Pass-through the Alpha 2 input value from the Alpha Palette Color Lookup Table of the Secondary data path,
	TABLE = The output of a Table defining a function of the Alphas from both data paths,
	ONE_MINUS = The Blending LUT 2 value is (1 - Blending LUT 1 output). Used for Blending LUT 2 Transfer Function (0028,140D) only
}

StringValues="TypeOfInstances" {
	DICOM,
	CDA
}

StringValues="ExecutionStatus" {
	PENDING,
	PRINTING,
	DONE,
	FAILURE
}

StringValues="AttenuationCorrected" {
	YES,
	NO
}

StringValues="ApplicatorApertureShape" {
	SYM_SQUARE = A square-shaped aperture symmetrical to the central axis,
	SYM_RECTANGLE = A rectangular-shaped aperture symmetrical to the central axis,
	SYM_CIRCULA = A circular-shaped aperture symmetrical to the central axis
}

StringValues="FovealSensitivityMeasured" {
	YES,
	NO
}

StringValues="InterpretationTypeID" {
}

StringValues="SurfaceProcessing" {
	YES,
	NO
}

StringValues="Modality" {
	CR = Computed Radiography,
	MR = Magnetic Resonance,
	US = Ultrasound,
	BI = Biomagnetic imaging,
	ES = Endoscopy,
	PT = Positron emission tomography (PET),
	XA = X-Ray Angiography,
	RTIMAGE = Radiotherapy Image,
	RTSTRUCT = Radiotherapy Structure Set,
	RTRECORD = RT Treatment Record,
	DX = Digital Radiography,
	IO = Intra-oral Radiography,
	GM = General Microscopy,
	XC = External-camera Photography,
	AU = Audio,
	CT = Computed Tomography,
	NM = Nuclear Medicine,
	OT = Other,
	DG = Diaphanography,
	LS = Laser surface scan,
	RG = Radiographic imaging (conventional film/screen),
	TG = Thermography,
	RF = Radio Fluoroscopy,
	RTDOSE = Radiotherapy Dose,
	RTPLAN = Radiotherapy Plan,
	HC = Hard Copy,
	MG = Mammography,
	PX = Panoramic X-Ray,
	SM = Slide Microscopy,
	PR = Presentation State,
	ECG = Electrocardiography,
	EPS = Cardiac Electrophysiology,
	SR = SR Document,
	OP = Ophthalmic Photography,
	AR = Autorefraction,
	VA = Visual Acuity,
	OCT = Optical Coherence Tomography (non-Ophthalmic),
	OPV = Ophthalmic Visual Field,
	OAM = Ophthalmic Axial Measurements,
	KO = Key Object Selection,
	REG = Registration,
	BDUS = Bone Densitometry (ultrasound),
	DOC = Document,
	PLAN = Plan,
	IVOCT = Intravascular Optical Coherence Tomography,
	HD = Hemodynamic Waveform,
	IVUS = Intravascular Ultrasound,
	SMR = Stereometric Relationship,
	KER = Keratometry,
	SRF = Subjective Refraction,
	LEN = Lensometry,
	OPM = Ophthalmic Mapping,
	RESP = Respiratory Waveform,
	SEG = Segmentation,
	OPT = Ophthalmic Tomography,
	BMD = Bone Densitometry (X-Ray),
	FID = Fiducials,
	IOL = Intraocular Lens Data,
	DS = Digital Subtraction Angiography,
	DF = Digital fluoroscopy,
	AS = Angioscopy,
	EC = Echocardiography,
	FA = Fluorescein angiography,
	DM = Digital microscopy,
	MA = Magnetic resonance angiography,
	CD = Color flow Doppler,
	ST = Single-photon emission computed tomography (SPECT),
	CF = Cinefluorography,
	VF = Videofluorography,
	CS = Cystoscopy,
	LP = Laparoscopy,
	CP = Culposcopy,
	FS = Fundoscopy,
	MS = Magnetic resonance spectroscopy,
	DD = Duplex Doppler,
	OPR = Ophthalmic Refraction
}

StringValues="OverlayorImageMagnification" {
}

StringValues="BlendingPosition" {
	SUPERIMPOSED,
	UNDERLYING
}

StringValues="TherapyDescription" {
}

StringValues="High-DoseTechniqueType" {
	NORMAL = Standard treatment,
	TBI = Total Body Irradiation,
	HDR = High Dose Rate
}

StringValues="OverlayActivationLayer" {
}

StringValues="AcquisitionCompressionType" {
}

StringValues="BeamStopperPosition" {
	EXTENDED = Beam Stopper extended,
	RETRACTED = Beam Stopper retracted,
	UNKNOWN = Position unknown	
}

StringValues="DefaultSmoothingType" {
    STANDARD\*,
    ROW\*,
    COL\*
}
