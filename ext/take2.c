#include <windows.h>
#include <mmsystem.h>
#include <stdlib.h>

void ShowVolume(void);   //Prototype the function early in the app

int main(char ** args) 
{
    // This is the function that can be added to the Generic Sample to
    // illustrate the use of waveOutGetVolume() and waveOutSetVolume().

    char buffer[40];
    char printbuf[80];
    UINT uRetVal, uNumDevs;
    DWORD volume;
    long lLeftVol, lRightVol;

    WAVEOUTCAPS waveCaps;

    // Make sure there is at least one
    // wave output device to work with.
    if (uNumDevs = waveOutGetNumDevs())
    {
   itoa((int)uNumDevs, buffer, 10);
   wsprintf(printbuf, "Number of devices is %s\n", (LPSTR)buffer);
   MessageBox(GetFocus(), printbuf, "NumDevs", MB_OK);
    }

    // This sample uses a hard-coded 0 as the device ID, but retail
    // applications should loop on devices 0 through N-1, where N is the
    // number of devices returned by waveOutGetNumDevs().
    if (!waveOutGetDevCaps(0,(LPWAVEOUTCAPS)&waveCaps,
       sizeof(WAVEOUTCAPS)))

    {
   // Verify the device supports volume changes
   if(waveCaps.dwSupport & WAVECAPS_VOLUME)
   {
       // The low word is the left volume, the high word is the right.
       // Set left channel: 2000h is one-eighth volume (8192 base ten).
       // Set right channel: 4000h is quarter volume (16384 base ten).
       uRetVal = waveOutSetVolume(0, (DWORD)0x40002000UL);

       // Now get and display the volumes.
       uRetVal = waveOutGetVolume(0, (LPDWORD)&volume);

       lLeftVol = (long)LOWORD(volume);
       lRightVol = (long)HIWORD(volume);

       ltoa(lLeftVol, buffer, 10);
       wsprintf(printbuf, "Left Volume is %s\n", (LPSTR)buffer);
       MessageBox(GetFocus(), printbuf, "Left Volume", MB_OK);

       ltoa(lRightVol, buffer, 10);
       wsprintf(printbuf, "Right Volume is %s\n", (LPSTR)buffer);
       MessageBox(GetFocus(), printbuf, "Right Volume", MB_OK);

       // The low word is the left volume, the high word is the right.
       // Set left channel: 8000h is half volume (32768 base ten).
       // Set right channel: 4000h is quarter volume (16384 base ten).
       uRetVal = waveOutSetVolume(-1, (DWORD)0xFFFFFFFFUL);

       // Now get and display the volumes.
       uRetVal = waveOutGetVolume(0, (LPDWORD)&volume);

       lLeftVol = (long)LOWORD(volume);
       lRightVol = (long)HIWORD(volume);

       ltoa(lLeftVol, buffer, 10);
       wsprintf(printbuf, "Left Volume is %s\n", (LPSTR)buffer);
       MessageBox(GetFocus(), printbuf, "Left Volume", MB_OK);

       ltoa(lRightVol, buffer, 10);
       wsprintf(printbuf, "Right Volume is %s\n", (LPSTR)buffer);
       MessageBox(GetFocus(), printbuf, "Right Volume", MB_OK);

   }
    }
}