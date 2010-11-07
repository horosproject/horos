#include "osconfig.h"
#include "djdec2k.h"
#include "djcparam.h"
#include "djrplol.h"
#include "djdijp2k.h"

DJDecoderJP2k::DJDecoderJP2k()
: DJCodecDecoder()
{
}


DJDecoderJP2k::~DJDecoderJP2k()
{
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