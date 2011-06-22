/* $Id: dvdid.h 3209 2009-10-14 14:41:34Z chris $ */

#ifndef DVDID__DVDID_H
#define DVDID__DVDID_H


#include <stdint.h>


#include "export.h"


#ifdef __cplusplus
extern "C" {
#endif


enum dvdid_status_e {
  DVDID_STATUS_OK = 0,
  DVDID_STATUS_MALLOC_ERROR,

  /* Error that should only be returned by dvdid_calculate (but not test of API) */
  DVDID_STATUS_PLATFORM_UNSUPPORTED, 
  DVDID_STATUS_READ_VIDEO_TS_ERROR, 
  DVDID_STATUS_READ_VMGI_ERROR, 
  DVDID_STATUS_READ_VTS01I_ERROR, 

  DVDID_STATUS_DETECT_MEDIUM_ERROR, 
  DVDID_STATUS_MEDIUM_UNKNOWN, 
  DVDID_STATUS_FIXUP_SIZE_ERROR,

  DVDID_STATUS_READ_VCD_ERROR, 
  DVDID_STATUS_READ_CDI_ERROR, 
  DVDID_STATUS_READ_EXT_ERROR, 
  DVDID_STATUS_READ_KARAOKE_ERROR, 
  DVDID_STATUS_READ_CDDA_ERROR, 
  DVDID_STATUS_READ_MPEGAV_ERROR, 
  DVDID_STATUS_READ_SEGMENT_ERROR, 
  DVDID_STATUS_READ_INFO_VCD_ERROR, 
  DVDID_STATUS_READ_ENTRIES_VCD_ERROR, 

  DVDID_STATUS_READ_SVCD_ERROR, 
  DVDID_STATUS_READ_MPEG2_ERROR, 
  DVDID_STATUS_READ_INFO_SVD_ERROR, 
  DVDID_STATUS_READ_ENTRIES_SVD_ERROR, 
  DVDID_STATUS_READ_TRACKS_SVD_ERROR, 
};


typedef enum dvdid_status_e dvdid_status_t;

/*
  If unsucessful, errn will be set to a platform specific error number, or zero if no
  such information is available.  If errn is NULL, the parameter will be ignored.
*/
DVDID_API(dvdid_status_t) dvdid_calculate(uint64_t *discid, const char* path, int *errn);

/* Get a pointer to a string describing the contents of a dvdid_status_t */
DVDID_API(const char*) dvdid_error_string(dvdid_status_t status);


#ifdef __cplusplus
}
#endif


#endif
