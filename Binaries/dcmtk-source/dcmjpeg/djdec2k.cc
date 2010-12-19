#include "osconfig.h"
#include "djdec2k.h"
#include "djcparam.h"
#include "djrplol.h"
#include "djdijp2k.h"
#include "dcpixseq.h"  /* for class DcmPixelSequence */

DJDecoderJP2k::DJDecoderJP2k()
: DJCodecDecoder()
{
}


DJDecoderJP2k::~DJDecoderJP2k()
{
}

OFBool DJDecoderJP2k::canChangeCoding(
    const E_TransferSyntax oldRepType,
    const E_TransferSyntax newRepType) const
{
  E_TransferSyntax myXfer = supportedTransferSyntax();
  DcmXfer newRep(newRepType);
  if (newRep.isNotEncapsulated() && (oldRepType == myXfer))
	return OFTrue; // decompress requested

  if (newRep.getXfer() == EXS_JPEG2000LosslessOnly && (oldRepType == myXfer))
	return OFTrue;

  // we don't support re-coding for now.
  return OFFalse;
}

OFCondition DJDecoderJP2k::encode(
    const E_TransferSyntax fromRepType,
    const DcmRepresentationParameter * fromRepParam,
    DcmPixelSequence *fromPixSeq,
    const DcmRepresentationParameter *toRepParam,
    DcmPixelSequence * & toPixSeq,
    const DcmCodecParameter * cp,
    DcmStack & objStack) const
{
  if( fromRepType == EXS_JPEG2000)
  {
	 toPixSeq = new DcmPixelSequence( *fromPixSeq);
	 toPixSeq->changeXfer( EXS_JPEG2000LosslessOnly);
	 
	 return EC_Normal;
  }
  
  // we don't support re-coding for now.
  return EC_IllegalCall;
}


E_TransferSyntax DJDecoderJP2k::supportedTransferSyntax() const
{
  return EXS_JPEG2000;
}


DJDecoder *DJDecoderJP2k::createDecoderInstance(
    const DcmRepresentationParameter * /* toRepParam */,
    const DJCodecParameter *cp,
    Uint8 bitsPerSample,
    OFBool isYBR) const
{
	return new DJDecompressJP2k(*cp, isYBR);
}

OFBool DJDecoderJP2k::isJPEG2000() const
{
	return OFTrue;
}

// **************

DJDecoderJP2kLossLess::DJDecoderJP2kLossLess()
: DJCodecDecoder()
{
}


DJDecoderJP2kLossLess::~DJDecoderJP2kLossLess()
{
}

OFBool DJDecoderJP2kLossLess::canChangeCoding(
    const E_TransferSyntax oldRepType,
    const E_TransferSyntax newRepType) const
{
  E_TransferSyntax myXfer = supportedTransferSyntax();
  DcmXfer newRep(newRepType);
  if (newRep.isNotEncapsulated() && (oldRepType == myXfer))
	return OFTrue; // decompress requested

  if (newRep.getXfer() == EXS_JPEG2000 && (oldRepType == myXfer))
	return OFTrue;

  // we don't support re-coding for now.
  return OFFalse;
}

OFCondition DJDecoderJP2kLossLess::encode(
    const E_TransferSyntax fromRepType,
    const DcmRepresentationParameter * fromRepParam,
    DcmPixelSequence *fromPixSeq,
    const DcmRepresentationParameter *toRepParam,
    DcmPixelSequence * & toPixSeq,
    const DcmCodecParameter * cp,
    DcmStack & objStack) const
{
  if( fromRepType == EXS_JPEG2000LosslessOnly)
  {
	toPixSeq = new DcmPixelSequence( *fromPixSeq);
	toPixSeq->changeXfer( EXS_JPEG2000);
	
	return EC_Normal;
  }
  
  // we don't support re-coding for now.
  return EC_IllegalCall;
}

E_TransferSyntax DJDecoderJP2kLossLess::supportedTransferSyntax() const
{
  return EXS_JPEG2000LosslessOnly;
}


DJDecoder *DJDecoderJP2kLossLess::createDecoderInstance(
    const DcmRepresentationParameter * /* toRepParam */,
    const DJCodecParameter *cp,
    Uint8 bitsPerSample,
    OFBool isYBR) const
{
	return new DJDecompressJP2k(*cp, isYBR);
}

OFBool DJDecoderJP2kLossLess::isJPEG2000() const
{
	return OFTrue;
}