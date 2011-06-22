/* $Id: dvdid2.h 3221 2009-10-14 20:08:09Z chris $ */

#ifndef DVDID__DVDID2_H
#define DVDID__DVDID2_H

#include <stdint.h>


#include "export.h"


#include "dvdid.h"


#ifdef __cplusplus
extern "C" {
#endif


enum dvdid_medium_e {
  DVDID_MEDIUM_DVD = 1,
  DVDID_MEDIUM_VCD,
  DVDID_MEDIUM_SVCD,
};

enum dvdid_dir_e {
  /* DVD */
  DVDID_DIR_VIDEO_TS = 1,
  /* VCD */
  DVDID_DIR_VCD,
  DVDID_DIR_CDI,
  DVDID_DIR_EXT,
  DVDID_DIR_KARAOKE,
  DVDID_DIR_CDDA,
  DVDID_DIR_MPEGAV,
  DVDID_DIR_SEGMENT,
  /* SVCD */
  DVDID_DIR_SVCD,
  /* DVDID_DIR_CDI, */
  /* DVDID_DIR_EXT */
  /* DVDID_DIR_KARAOKE, */
  /* DVDID_DIR_CDDA, */
  DVDID_DIR_MPEG2,
  /* DVDID_DIR_SEGMENT, */
};

enum dvdid_file_e {
  /* DVD */
  DVDID_FILE_VMGI = 1,
  DVDID_FILE_VTS01I,
  /* VCD */
  DVDID_FILE_INFO_VCD,
  DVDID_FILE_ENTRIES_VCD,
  /* SVCD */
  DVDID_FILE_INFO_SVD,
  DVDID_FILE_ENTRIES_SVD,
  DVDID_FILE_TRACKS_SVD,
};


typedef struct dvdid_hashinfo_s dvdid_hashinfo_t;
typedef struct dvdid_fileinfo_s dvdid_fileinfo_t;

typedef enum dvdid_medium_e dvdid_medium_t;
typedef enum dvdid_dir_e dvdid_dir_t;
typedef enum dvdid_file_e dvdid_file_t;


struct dvdid_fileinfo_s {
  /* Creation time as a Win32 FILETIME */
  uint64_t creation_time;

  /* Lowest 32bits of file size (explicitly, the 
     value stoted on the physical medium, which is
     not necessarily the value reported by the OS
     for (S)VCDs) */
  uint32_t size;

  /* Filename, uppercases, in ASCII */
  char *name;
};


DVDID_API(dvdid_status_t) dvdid_calculate2(uint64_t *discid, const dvdid_hashinfo_t *hi);

/* Create a hashinfo struct.  Returns non-zero on error */
DVDID_API(dvdid_status_t) dvdid_hashinfo_create(dvdid_hashinfo_t **hi);

/* Set/get the media type.  Defaults to DVDID_TYPE_DVD for backwards 
  compatibility.  Set this before adding file info / data. */
DVDID_API(dvdid_status_t) dvdid_hashinfo_set_medium(dvdid_hashinfo_t *hi, dvdid_medium_t medium);
DVDID_API(dvdid_medium_t) dvdid_hashinfo_get_medium(const dvdid_hashinfo_t *hi);

/* Add a file to the hashinfo struct.  The fileinfo will be copied, 
  and memory allocated as appropriate.  Returns non-zero on error, in
  which case dvdid_hashinfo_free must be called on the hashinfo struct
  as it's not guaranteed to be useable */
DVDID_API(dvdid_status_t) dvdid_hashinfo_add_fileinfo(dvdid_hashinfo_t *hi, dvdid_dir_t dir, const dvdid_fileinfo_t *fi);

/* Add the data read from various key files on the medium .  This buffer 
  will be copied, so does not need to be valid until dvd_hashinfo_free is
  called.  Only call this once (per file to be added). */
/* We need at most the first DVDID_HASHINFO_FILEDATE_MAXSIZE bytes of the file */
#define DVDID_HASHINFO_FILEDATA_MAXSIZE 0x10000
DVDID_API(dvdid_status_t) dvdid_hashinfo_add_filedata(dvdid_hashinfo_t *hi, dvdid_file_t file, const uint8_t *buf, size_t size);

/* Having added the necessary files and data,  perform any additional init 
  work before dvdid_calculate2 gets called */
DVDID_API(dvdid_status_t) dvdid_hashinfo_init(dvdid_hashinfo_t *hi);

/* Free hashinfo struct one finished with */
DVDID_API(void) dvdid_hashinfo_free(dvdid_hashinfo_t *hi);


/* From previous API, calls dvdid_hashinfo_add_file(hi, DVDID_DIR_VIDEO_TS, fi); */
DVDID_API(dvdid_status_t) dvdid_hashinfo_addfile(dvdid_hashinfo_t *hi, const dvdid_fileinfo_t *fi);

/* From previous API, calls dvdid_hashinfo_add_data(hi, DVDID_FILE_VMGI, buf, size); */
#define DVDID_HASHINFO_VXXI_MAXBUF DVDID_HASHINFO_FILEDATA_MAXSIZE
DVDID_API(dvdid_status_t) dvdid_hashinfo_set_vmgi(dvdid_hashinfo_t *hi, const uint8_t *buf, size_t size);

/* From previous API, calls dvdid_hashinfo_add_data(hi, DVDID_FILE_VTS01I, buf, size); */
DVDID_API(dvdid_status_t) dvdid_hashinfo_set_vts01i(dvdid_hashinfo_t *hi, const uint8_t *buf, size_t size);


#ifdef __cplusplus
}
#endif


#endif
