// UiaDll.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"

extern "C"
__declspec( dllexport ) IUIAutomationElement *RA_FindWindow(char *pszAutomationId) {
	IUIAutomationElement *pRootElement ;

	HRESULT hr = getGlobalIUIAutomation()->GetRootElement(&pRootElement) ;
	if (SUCCEEDED(hr)) {
		IUIAutomationCondition *pCondition ;
		VARIANT varProperty ;

		VariantInit(&varProperty) ;
		varProperty.vt = VT_BSTR ;
		varProperty.bstrVal = _bstr_t(pszAutomationId) ;

		hr = getGlobalIUIAutomation()->CreatePropertyCondition(UIA_AutomationIdPropertyId, varProperty, &pCondition) ;
		if (SUCCEEDED(hr)) {
			IUIAutomationElement *pFound ;

			hr = pRootElement->FindFirst(TreeScope_Children, pCondition, &pFound) ;
			if (SUCCEEDED(hr)) {
				return pFound ;
			}
		}
	}
	return NULL ;
}

extern "C"
__declspec( dllexport ) BOOL RA_IsOffscreen(IUIAutomationElement *pElement) {
	BOOL isOffscreen ;
	pElement->get_CurrentIsOffscreen(&isOffscreen) ;

	return isOffscreen ;
}

extern "C"
__declspec ( dllexport ) IUIAutomationElement *RA_ElementFromHandle(HWND hwnd) {
	IUIAutomationElement *pElement ;

	HRESULT hr = getGlobalIUIAutomation()->ElementFromHandle(hwnd, &pElement) ;
	if (SUCCEEDED(hr))
		return pElement ;
	else {
		printf("RA_ElementFromHandle: Cannot find element from handle 0x%x. HRESULT was 0x%x\r\n", hwnd, hr) ;
		return NULL ;
	}
}

extern "C" __declspec ( dllexport ) IUIAutomationElement *RA_FindChildById(IUIAutomationElement *pElement, char *automationId) {
	IUIAutomationCondition *pCondition ;
	VARIANT varProperty ;

	VariantInit(&varProperty) ;
	varProperty.vt = VT_BSTR ;
	varProperty.bstrVal = _bstr_t(automationId) ;

	HRESULT hr = getGlobalIUIAutomation()->CreatePropertyCondition(UIA_AutomationIdPropertyId, varProperty, &pCondition) ;
	if (SUCCEEDED(hr)) {
		IUIAutomationElement *pFound ;

		hr = pElement->FindFirst(TreeScope_Descendants, pCondition, &pFound) ;
		if (SUCCEEDED(hr)) {
			if (pFound == NULL)
				printf("RA_FindChildById: Element with automation id %s was not found\r\n", automationId) ;

			return pFound ;
		} else {
			printf("RA_FindChildById: FindFirst for children looking for %s failed. hr = 0x%x\r\n", automationId, hr) ;
			return NULL ;
		}
	} else {
		printf("RA_FindChildById: Cannot create search condition. hr = 0x%x\r\n", hr) ;
		return NULL ;
	}
}

extern "C" __declspec ( dllexport ) HWND RA_CurrentNativeWindowHandle(IUIAutomationElement *pElement) {
	UIA_HWND uia_hwnd ;

	if (pElement == NULL) {
		printf("RA_CurrentNativeWindowHandle: Cannot operate on NULL element\r\n") ;
		return (HWND)0 ;
	}

	pElement->get_CurrentNativeWindowHandle(&uia_hwnd) ;
	return (HWND)uia_hwnd ;
}

extern "C" __declspec ( dllexport ) BOOL RA_SetFocus(IUIAutomationElement *pElement) {
	HRESULT hr = pElement->SetFocus() ;
	if (hr != S_OK)
		printf("RA_SetFocus: SetFocus on element returned 0x%x\r\n", hr) ;

	return SUCCEEDED(hr) ;
}

extern "C" __declspec ( dllexport ) int RA_GetCurrentControlType(IUIAutomationElement *pElement) {
	CONTROLTYPEID control_type ;

	HRESULT hr = pElement->get_CurrentControlType(&control_type) ;
	if (SUCCEEDED(hr))
		return control_type ;
	else {
		printf("RA_GetCurrentControlType: CurrentControlType returned 0x%x\r\n", hr) ;
		return 0 ;
	}
}

extern "C" __declspec ( dllexport ) int RA_FindChildren(IUIAutomationElement *pElement, IUIAutomationElement *pChildren[]) {
	IUIAutomationCondition *pTrueCondition ;
	IUIAutomationElementArray *pElementArray ;
	int element_count ;

	HRESULT hr = getGlobalIUIAutomation()->CreateTrueCondition(&pTrueCondition) ;
	if (FAILED(hr)) {
		printf("RA_FindChildren: Could not create true condition 0x%x\r\n", hr) ;
		return 0 ;
	}

	hr = pElement->FindAll(TreeScope_Children, pTrueCondition, &pElementArray) ;
	if (FAILED(hr)) {
		printf("RA_FindChildren: FindAll failed 0x%x\r\n", hr) ;
		return 0 ;
	}
	 
	hr = pElementArray->get_Length(&element_count) ;
	if (FAILED(hr)) {
		printf("RA_FindChildren: get_length failed 0x%x\r\n", hr) ;
		return 0 ;
	}

	if (pChildren != NULL) {
		// given some memory get the details
		for (int index = 0; index < element_count; index++) {
			IUIAutomationElement *pElement ;

			hr = pElementArray->GetElement(index, &pElement) ;
			if (FAILED(hr)) {
				printf("RA_FindChildren: GetElement failed 0x%x\r\n", hr) ;
			} else {
				pChildren[index] = pElement ;
			}
		}
	}

	return element_count ;
}

extern "C" __declspec ( dllexport ) int RA_GetName(IUIAutomationElement *pElement, char *pName) {
	BSTR bstrName ;
	HRESULT hr = pElement->get_CurrentName(&bstrName) ;
	if (FAILED(hr)) {
		printf("RA_GetName: get_CurrentName failed 0x%x\r\n", hr) ;
		return 0 ;
	}

	char *pszName = _com_util::ConvertBSTRToString(bstrName) ;
	if (pName == NULL) {
		return strlen(pszName) ;
	} else {
		strcpy(pName, pszName) ;
		return strlen(pszName) ;
	}
}

extern "C" __declspec ( dllexport ) BOOL RA_GetIsSelected(IUIAutomationElement *pElement, int *pResult) {
	ISelectionItemProvider *pSelectionPattern ;
	HRESULT hr = pElement->GetCurrentPattern(UIA_SelectionItemPatternId, (IUnknown**)&pSelectionPattern) ;
	
	if (FAILED(hr)) {
		printf("RA_GetIsSelected: getCurrentPattern failed 0x%x\r\n") ;
		return FALSE ;
	}

	BOOL pRetVal ;
	hr = pSelectionPattern->get_IsSelected(&pRetVal) ;
	if (FAILED(hr)) {
		printf("RA_GetIsSelected: get_IsSelected failed 0x%x\r\n", hr) ;
		return FALSE ;
	} else {
		*pResult = pRetVal ;
		return TRUE ;
	}
}

extern "C" __declspec ( dllexport ) int RA_Select(IUIAutomationElement *pElement) {
	ISelectionItemProvider *pSelectionPattern ;
	HRESULT hr = pElement->GetCurrentPattern(UIA_SelectionItemPatternId, (IUnknown**)&pSelectionPattern) ;
	if (FAILED(hr)) {
		printf("RA_GetIsSelected: getCurrentPattern failed 0x%x\r\n") ;
		return FALSE ;
	}

	hr = pSelectionPattern->Select();
	if (FAILED(hr)) {
		printf("RA_Select: Select failed 0x%x\r\n", hr) ;
		return 0 ;
	}

	return 1;
}
