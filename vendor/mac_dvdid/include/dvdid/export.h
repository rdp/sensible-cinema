/* $Id: export.h 2781 2009-09-13 11:31:27Z chris $ */
/* File structure and dll export system derived from FLAC */

#ifndef DVDID__EXPORT_H
#define DVDID__EXPORT_H

#if defined(DVDID__NO_DLL) || !defined(_MSC_VER)

#define DVDID_API(type) type
#define DVDID_CALLBACK

#else

#ifdef DVDID_API_EXPORTS
/* We use a .def file rather than __declspec(dllexport) */
#define DVDID_API(type) type __stdcall
#else
#define DVDID_API(type) __declspec(dllimport) type __stdcall
#endif

#define DVDID_CALLBACK __stdcall

#endif

/** These #defines will mirror the libtool-based library version number, see
 * http://www.gnu.org/software/libtool/manual.html#Libtool-versioning
 */
#define DVDID_API_VERSION_CURRENT 0
#define DVDID_API_VERSION_REVISION 0
#define DVDID_API_VERSION_AGE 0

#endif
