// this pilfered from the AutoHotKey code
#include <windows.h>
#include <mmsystem.h>
#include <stdio.h> // sprintf


char error_string[256];
#define MIXERCONTROL_CONTROLTYPE_BASS_BOOST (MIXERCONTROL_CONTROLTYPE_BOOLEAN + 0x00002277)


const char * SoundSetGet(char *aSetting, DWORD aComponentType, int aComponentInstance
	, DWORD aControlType, UINT aMixerID)
// If the caller specifies NULL for aSetting, the mode will be "Get".  Otherwise, it will be "Set".
{
	#define SOUND_MODE_IS_SET aSetting // Boolean: i.e. if it's not NULL, the mode is "SET".
	double setting_percent;
	char *output_var;
	if (SOUND_MODE_IS_SET)
	{
		output_var = NULL; // To help catch bugs.
		setting_percent = atof(aSetting);
		if (setting_percent < -100)
			setting_percent = -100;
		else if (setting_percent > 100)
			setting_percent = 100;
	}
	else // The mode is GET.
	{
    output_var = aSetting;    
	}

	// Open the specified mixer ID:
	HMIXER hMixer;
    if (mixerOpen(&hMixer, aMixerID, 0, 0, 0) != MMSYSERR_NOERROR)
		  return "Can't Open Specified Mixer";

	// Find out how many destinations are available on this mixer (should always be at least one):
	int dest_count;
	MIXERCAPS mxcaps;
	if (mixerGetDevCaps((UINT_PTR)hMixer, &mxcaps, sizeof(mxcaps)) == MMSYSERR_NOERROR)
		dest_count = mxcaps.cDestinations;
	else
		dest_count = 1;  // Assume it has one so that we can try to proceed anyway.

	// Find specified line (aComponentType + aComponentInstance):
	MIXERLINE ml = {0};
    ml.cbStruct = sizeof(ml);
	if (aComponentInstance == 1)  // Just get the first line of this type, the easy way.
	{
		ml.dwComponentType = aComponentType;
		if (mixerGetLineInfo((HMIXEROBJ)hMixer, &ml, MIXER_GETLINEINFOF_COMPONENTTYPE) != MMSYSERR_NOERROR)
		{
			mixerClose(hMixer);
			return "Mixer Doesn't Support This Component Type";
		}
	}
	else
	{
		// Search through each source of each destination, looking for the indicated instance
		// number for the indicated component type:
		int source_count;
		bool found = false;
		for (int d = 0, found_instance = 0; d < dest_count && !found; ++d) // For each destination of this mixer.
		{
			ml.dwDestination = d;
			if (mixerGetLineInfo((HMIXEROBJ)hMixer, &ml, MIXER_GETLINEINFOF_DESTINATION) != MMSYSERR_NOERROR)
				// Keep trying in case the others can be retrieved.
				continue;
			source_count = ml.cConnections;  // Make a copy of this value so that the struct can be reused.
			for (int s = 0; s < source_count && !found; ++s) // For each source of this destination.
			{
				ml.dwDestination = d; // Set it again in case it was changed.
				ml.dwSource = s;
				if (mixerGetLineInfo((HMIXEROBJ)hMixer, &ml, MIXER_GETLINEINFOF_SOURCE) != MMSYSERR_NOERROR)
					// Keep trying in case the others can be retrieved.
					continue;
				// This line can be used to show a soundcard's component types (match them against mmsystem.h):
				//MsgBox(ml.dwComponentType);
				if (ml.dwComponentType == aComponentType)
				{
					++found_instance;
					if (found_instance == aComponentInstance)
						found = true;
				}
			} // inner for()
		} // outer for()
		if (!found)
		{
			mixerClose(hMixer);
			return "Mixer Doesn't Have That Many of That Component Type";
		}
	}

	// Find the mixer control (aControlType) for the above component:
    MIXERCONTROL mc; // MSDN: "No initialization of the buffer pointed to by [pamxctrl below] is required"
    MIXERLINECONTROLS mlc;
	mlc.cbStruct = sizeof(mlc);
	mlc.pamxctrl = &mc;
	mlc.cbmxctrl = sizeof(mc);
	mlc.dwLineID = ml.dwLineID;
	mlc.dwControlType = aControlType;
	mlc.cControls = 1;
	if (mixerGetLineControls((HMIXEROBJ)hMixer, &mlc, MIXER_GETLINECONTROLSF_ONEBYTYPE) != MMSYSERR_NOERROR)
	{
		mixerClose(hMixer);
		return "Component Doesn't Support This Control Type";
	}

	// Does user want to adjust the current setting by a certain amount?
	// For v1.0.25, the first char of RAW_ARG is also checked in case this is an expression intended
	// to be a positive offset, such as +(var + 10)
	bool adjust_current_setting = aSetting && (*aSetting == '-' || *aSetting == '+');// || *RAW_ARG1 == '+');

	// These are used in more than once place, so always initialize them here:
	MIXERCONTROLDETAILS mcd = {0};
    MIXERCONTROLDETAILS_UNSIGNED mcdMeter;
	mcd.cbStruct = sizeof(MIXERCONTROLDETAILS);
	mcd.dwControlID = mc.dwControlID;
	mcd.cChannels = 1; // MSDN: "when an application needs to get and set all channels as if they were uniform"
	mcd.paDetails = &mcdMeter;
	mcd.cbDetails = sizeof(mcdMeter);

	// Get the current setting of the control, if necessary:
	if (!SOUND_MODE_IS_SET || adjust_current_setting)
	{
		if (mixerGetControlDetails((HMIXEROBJ)hMixer, &mcd, MIXER_GETCONTROLDETAILSF_VALUE) != MMSYSERR_NOERROR)
		{
			mixerClose(hMixer);
			return "Can't Get Current Setting";
		}
	}

	bool control_type_is_boolean;
	switch (aControlType)
	{
	case MIXERCONTROL_CONTROLTYPE_ONOFF:
	case MIXERCONTROL_CONTROLTYPE_MUTE:
	case MIXERCONTROL_CONTROLTYPE_MONO:
	case MIXERCONTROL_CONTROLTYPE_LOUDNESS:
	case MIXERCONTROL_CONTROLTYPE_STEREOENH:
	case MIXERCONTROL_CONTROLTYPE_BASS_BOOST:
		control_type_is_boolean = true;
		break;
	default: // For all others, assume the control can have more than just ON/OFF as its allowed states.
		control_type_is_boolean = false;
	}

	if (SOUND_MODE_IS_SET)
	{
		if (control_type_is_boolean)
		{
			if (adjust_current_setting) // The user wants this toggleable control to be toggled to its opposite state:
				mcdMeter.dwValue = (mcdMeter.dwValue > mc.Bounds.dwMinimum) ? mc.Bounds.dwMinimum : mc.Bounds.dwMaximum;
			else // Set the value according to whether the user gave us a setting that is greater than zero:
				mcdMeter.dwValue = (setting_percent > 0.0) ? mc.Bounds.dwMaximum : mc.Bounds.dwMinimum;
		}
		else // For all others, assume the control can have more than just ON/OFF as its allowed states.
		{
			// Make this an __int64 vs. DWORD to avoid underflow (so that a setting_percent of -100
			// is supported whenenver the difference between Min and Max is large, such as MAXDWORD):
			__int64 specified_vol = (__int64)((mc.Bounds.dwMaximum - mc.Bounds.dwMinimum) * (setting_percent / 100.0));
			if (adjust_current_setting)
			{
				// Make it a big int so that overflow/underflow can be detected:
				__int64 vol_new = mcdMeter.dwValue + specified_vol;
				if (vol_new < mc.Bounds.dwMinimum)
					vol_new = mc.Bounds.dwMinimum;
				else if (vol_new > mc.Bounds.dwMaximum)
					vol_new = mc.Bounds.dwMaximum;
				mcdMeter.dwValue = (DWORD)vol_new;
			}
			else
				mcdMeter.dwValue = (DWORD)specified_vol; // Due to the above, it's known to be positive in this case.
		}
    printf("set to %i", mcdMeter.dwValue);

		MMRESULT result = mixerSetControlDetails((HMIXEROBJ)hMixer, &mcd, MIXER_GETCONTROLDETAILSF_VALUE);
		mixerClose(hMixer);
		return result == MMSYSERR_NOERROR ? "Success set" : "Can't Change Setting";
	}

	// Otherwise, the mode is "Get":
	mixerClose(hMixer);
  //hmm...g_ErrorLevel->Assign(ERRORLEVEL_NONE); // Indicate success.

	if (control_type_is_boolean)
    return mcdMeter.dwValue ? "On" : "Off";
  else {// For all others, assume the control can have more than just ON/OFF as its allowed states.
		// The MSDN docs imply that values fetched via the above method do not distinguish between
		// left and right volume levels, unlike waveOutGetVolume():
		sprintf(error_string, "%f", ((double)100 * (mcdMeter.dwValue - (DWORD)mc.Bounds.dwMinimum))
			/ (mc.Bounds.dwMaximum - mc.Bounds.dwMinimum)   );
    return error_string;
  }
}

int main(char **args) {
    int device_id = 0;//*ARG4 ? ArgToInt(4) - 1 : 0;    
		int instance_number = 1;  // Set default.
    
    /*
    			|| !strlicmp(aBuf, "Speakers", length_to_check))   return MIXERLINE_COMPONENTTYPE_DST_SPEAKERS;
		if (!strlicmp(aBuf, "Headphones", length_to_check))    return MIXERLINE_COMPONENTTYPE_DST_HEADPHONES;
		if (!strlicmp(aBuf, "Digital", length_to_check))       return MIXERLINE_COMPONENTTYPE_SRC_DIGITAL;
		if (!strlicmp(aBuf, "Line", length_to_check))          return MIXERLINE_COMPONENTTYPE_SRC_LINE;
		if (!strlicmp(aBuf, "Microphone", length_to_check))    return MIXERLINE_COMPONENTTYPE_SRC_MICROPHONE;
		if (!strlicmp(aBuf, "Synth", length_to_check))         return MIXERLINE_COMPONENTTYPE_SRC_SYNTHESIZER;
		if (!strlicmp(aBuf, "CD", length_to_check))            return MIXERLINE_COMPONENTTYPE_SRC_COMPACTDISC;
		if (!strlicmp(aBuf, "Telephone", length_to_check))     return MIXERLINE_COMPONENTTYPE_SRC_TELEPHONE;
		if (!strlicmp(aBuf, "PCSpeaker", length_to_check))     return MIXERLINE_COMPONENTTYPE_SRC_PCSPEAKER;
		if (!strlicmp(aBuf, "Wave", length_to_check))          return MIXERLINE_COMPONENTTYPE_SRC_WAVEOUT;
		if (!strlicmp(aBuf, "Aux", length_to_check))           return MIXERLINE_COMPONENTTYPE_SRC_AUXILIARY;
		if (!strlicmp(aBuf, "Analog", length_to_check))        return MIXERLINE_COMPONENTTYPE_SRC_ANALOG;
    */
    int a[] = {MIXERLINE_COMPONENTTYPE_DST_SPEAKERS, MIXERLINE_COMPONENTTYPE_DST_HEADPHONES, MIXERLINE_COMPONENTTYPE_SRC_DIGITAL,
      MIXERLINE_COMPONENTTYPE_SRC_LINE, MIXERLINE_COMPONENTTYPE_SRC_MICROPHONE,MIXERLINE_COMPONENTTYPE_SRC_SYNTHESIZER, MIXERLINE_COMPONENTTYPE_SRC_WAVEOUT};
   for(int i = 0; i < 7; i++) {
      
		DWORD component_type = i;//*ARG2 ? SoundConvertComponentType(ARG2, &instance_number) : MIXERLINE_COMPONENTTYPE_DST_SPEAKERS;
    char *getSet = NULL;//"+3"; // NULL
    printf("got %s\n", SoundSetGet(getSet
			, component_type, instance_number,  // Which instance of this component, 1 = first
    // Default *ARG3 ? SoundConvertControlType(ARG3) : 
    MIXERCONTROL_CONTROLTYPE_VOLUME // default, though can change it...
			, (UINT)device_id));
    }
  
}
