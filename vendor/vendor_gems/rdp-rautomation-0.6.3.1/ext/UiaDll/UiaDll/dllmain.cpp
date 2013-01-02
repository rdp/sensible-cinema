// dllmain.cpp : Defines the entry point for the DLL application.
#include "stdafx.h"

IUIAutomation *pAutomation ;

IUIAutomation* getGlobalIUIAutomation() {
	return pAutomation ;
}


BOOL APIENTRY DllMain( HMODULE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
					 )
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH: 
	case DLL_THREAD_ATTACH:
		HRESULT hr ;
		hr = CoInitialize(NULL) ;
		if (FAILED(hr)) {
			printf("UiaDll: CoInitialize failed. hr = 0x%x", hr) ;
			return FALSE ;
		}
		hr = CoCreateInstance(__uuidof(CUIAutomation), NULL, CLSCTX_INPROC_SERVER, __uuidof(IUIAutomation), (void**)&pAutomation);
		if (FAILED(hr)) {
			printf("UiaDll: CoCreateInstance failed. hr = 0x%x", hr) ;
			return FALSE ;
		}
		break ;
	case DLL_THREAD_DETACH:
	case DLL_PROCESS_DETACH:
		CoUninitialize() ;
		break;
	}
	return TRUE;
}

