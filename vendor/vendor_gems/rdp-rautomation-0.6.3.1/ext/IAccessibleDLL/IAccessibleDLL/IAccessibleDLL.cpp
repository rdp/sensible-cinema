// IAccessibleDLL.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"

extern "C"
__declspec( dllexport ) long get_button_state(HWND buttonHwnd) {
	IAccessible		*pIAccessible ;
	VARIANT			varState;
	VARIANT			varChildId;
	BOOL			checked = FALSE ;
	HRESULT hr ;
	HMODULE hModule ;
	LPFNACCESSIBLEOBJECTFROMWINDOW lpfnAccessibleObjectFromWindow ;

	hModule = LoadLibraryA("oleacc.dll");
	lpfnAccessibleObjectFromWindow = (LPFNACCESSIBLEOBJECTFROMWINDOW)GetProcAddress(hModule, "AccessibleObjectFromWindow");

	hr = lpfnAccessibleObjectFromWindow(buttonHwnd, OBJID_CLIENT, IID_IAccessible, (void**)&pIAccessible) ;

	VariantInit(&varChildId);
	varChildId.vt = VT_I4;
	varChildId.lVal = CHILDID_SELF ;

	pIAccessible->get_accState(varChildId, &varState);
	
	return varState.lVal ;
}


