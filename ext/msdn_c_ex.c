#include <windows.h>
    #include <mmsystem.h>
int main(char **args) {
    MMRESULT rc;              // Return code.
    HMIXER hMixer;            // Mixer handle used in mixer API calls.
    MIXERCONTROL mxc;         // Holds the mixer control data.
    MIXERLINE mxl, mline;            // Holds the mixer line data.
    MIXERLINECONTROLS mxlc;   // Obtains the mixer control.

    // Open the mixer. This opens the mixer with a deviceID of 0. If you
    // have a single sound card/mixer, then this will open it. If you have
    // multiple sound cards/mixers, the deviceIDs will be 0, 1, 2, and
    // so on.
    rc = mixerOpen(&hMixer, 0,0,0,0);
    if (MMSYSERR_NOERROR != rc) {
        // Couldn't open the mixer.
      printf("bad3");
    }

    // Initialize MIXERLINE structure.
    ZeroMemory(&mxl,sizeof(mxl));
    mxl.cbStruct = sizeof(mxl);

    // Specify the line you want to get. You are getting the input line
    // here. If you want to get the output line, you need to use
    // MIXERLINE_COMPONENTTYPE_SRC_WAVEOUT.
    // MIXERLINE_COMPONENTTYPE_DST_WAVEIN => fail
    // appears you can find it more easily thus: http://www.eggheadcafe.com/forumarchives/win32programmerdirectxaudio/Feb2006/post25682865.asp
    
    // MIXERLINE_COMPONENTTYPE_DST_SPEAKERS is what AHK uses
    
    // MIXERCONTROL_CONTROLTYPE_VOLUME
    
    /*
    
    MIXERCAPS caps;  
  
    MMRESULT error = mixerGetDevCaps((HMIXEROBJ)hMixer, &caps, sizeof(MIXERCAPS));  
  
    if (MMSYSERR_NOERROR != error)    
      return;  
  
    for (j = 0; j < caps.cDestinations; j++)  
  
    {  
  
      mline.dwDestination = j;  
  
      error = mixerGetLineInfo((HMIXEROBJ)mixer, &mline, MIXER_GETLINEINFOF_DESTINATION);  
  
      if (MMSYSERR_NOERROR == error)  
  
      {  
  
        if (MIXERLINE_COMPONENTTYPE_DST_WAVEIN == mline.dwComponentType)   {
          mxl = mline;
          printf("found it");
          break;
        }
      }
    
      } */
      
    mxl.dwComponentType = MIXERLINE_COMPONENTTYPE_SRC_WAVEOUT;

    rc = mixerGetLineInfo((HMIXEROBJ)hMixer, &mxl,
                           MIXER_GETLINEINFOF_COMPONENTTYPE);
    if (MMSYSERR_NOERROR != rc) {
        // Couldn't get the mixer line.
      printf("bad4 %d %d %d %d %d %d, %d]", rc, MIXERR_INVALLINE, MMSYSERR_BADDEVICEID, MMSYSERR_INVALFLAG, MMSYSERR_INVALHANDLE, MMSYSERR_INVALPARAM,MMSYSERR_NODRIVER);
    }
    

    // Get the control.
    ZeroMemory(&mxlc, sizeof(mxlc));
    mxlc.cbStruct = sizeof(mxlc);
    mxlc.dwLineID = mxl.dwLineID;
    mxlc.dwControlType = MIXERCONTROL_CONTROLTYPE_PEAKMETER;
    mxlc.cControls = 1;
    mxlc.cbmxctrl = sizeof(mxc);
    mxlc.pamxctrl = &mxc;
    ZeroMemory(&mxc, sizeof(mxc));
    mxc.cbStruct = sizeof(mxc);
    // MIXER_GETLINECONTROLSF_ALL
    // MIXER_GETLINECONTROLSF_ONEBYTYPE => fail
    rc = mixerGetLineControls((HMIXEROBJ)hMixer,&mxlc,
                               MIXER_GETLINECONTROLSF_ALL);
    if (MMSYSERR_NOERROR != rc) {
        // Couldn't get the control.
      printf("bad2 %d %d %d %d %d %d %d %d]", rc, MIXERR_INVALCONTROL, MIXERR_INVALLINE, MMSYSERR_BADDEVICEID, MMSYSERR_INVALFLAG, MMSYSERR_INVALHANDLE, MMSYSERR_INVALPARAM, MMSYSERR_NODRIVER);
    }

    // After successfully getting the peakmeter control, the volume range
    // will be specified by mxc.Bounds.lMinimum to mxc.Bounds.lMaximum.

    MIXERCONTROLDETAILS mxcd;             // Gets the control values.
    MIXERCONTROLDETAILS_SIGNED volStruct; // Gets the control values.
    long volume;                          // Holds the final volume value.

    // Initialize the MIXERCONTROLDETAILS structure
    ZeroMemory(&mxcd, sizeof(mxcd));
    mxcd.cbStruct = sizeof(mxcd);
    mxcd.cbDetails = sizeof(volStruct);
    mxcd.dwControlID = mxc.dwControlID;
    mxcd.paDetails = &volStruct;
    mxcd.cChannels = 1;

    // Get the current value of the peakmeter control. Typically, you
    // would set a timer in your program to query the volume every 10th
    // of a second or so.
    rc = mixerGetControlDetails((HMIXEROBJ)hMixer, &mxcd,
                                 MIXER_GETCONTROLDETAILSF_VALUE);
    if (MMSYSERR_NOERROR != rc) {
      printf("bad1");
        // Couldn't get the current volume.
    }
    volume = volStruct.lValue;

    // Get the absolute value of the volume.
    if (volume < 0)
        volume = -volume;
    
    printf("got %f %d", volume, volume);
  }