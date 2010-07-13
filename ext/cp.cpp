#include <windows.h>
#include <mmsystem.h>
#include <stdio.h> // sprintf

int main(char **a) {
  
  MMRESULT result;
  HMIXER hMixer;
  result = mixerOpen(&hMixer, MIXER_OBJECTF_MIXER, 0, 0, 0);

  MIXERLINE ml = {0};
ml.cbStruct = sizeof(MIXERLINE);
ml.dwComponentType = MIXERLINE_COMPONENTTYPE_DST_SPEAKERS;
result = mixerGetLineInfo((HMIXEROBJ) hMixer, 
         &ml, MIXER_GETLINEINFOF_COMPONENTTYPE);


MIXERLINECONTROLS mlc = {0};
MIXERCONTROL mc = {0};
mlc.cbStruct = sizeof(MIXERLINECONTROLS);
mlc.dwLineID = ml.dwLineID;
mlc.dwControlType = MIXERCONTROL_CONTROLTYPE_VOLUME;
mlc.cControls = 1;
mlc.pamxctrl = &mc;
mlc.cbmxctrl = sizeof(MIXERCONTROL);
result = mixerGetLineControls((HMIXEROBJ) hMixer, 
           &mlc, MIXER_GETLINECONTROLSF_ONEBYTYPE);

MIXERCONTROLDETAILS mcd = {0};
MIXERCONTROLDETAILS_UNSIGNED mcdu = {0};
mcdu.dwValue = 0;//18500; // the volume is a number between 0 and 65535

mcd.cbStruct = sizeof(MIXERCONTROLDETAILS);
mcd.hwndOwner = 0;
mcd.dwControlID = mc.dwControlID;
mcd.paDetails = &mcdu;
mcd.cbDetails = sizeof(MIXERCONTROLDETAILS_UNSIGNED);
mcd.cChannels = 1;
result = mixerSetControlDetails((HMIXEROBJ) hMixer, 
               &mcd, MIXER_SETCONTROLDETAILSF_VALUE);

return 3;

}