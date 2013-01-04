// ListViewExplorer.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"

HWND ask_for_list_view_handle() {
	HWND hwnd = 0 ;

	printf("HWND of list view control: ") ;
	scanf_s("%x", &hwnd) ;
	while(getchar() != '\n') continue;

	return hwnd ;
}

void print_acc_name(VARIANT varIn, IAccessible *pAccessible) {
	BSTR bstrName ;

	if (pAccessible->get_accName(varIn, &bstrName) == S_OK) {
		char *pszName = _com_util::ConvertBSTRToString(bstrName) ;
		printf("  Name: %s\r\n", pszName) ;
		delete[] pszName ;
		SysFreeString(bstrName) ;
	} else
		printf("  Name: not available\r\n") ;
}

void print_acc_value(VARIANT varIn, IAccessible *pAccessible) {
	BSTR bstrValue ;

	if (pAccessible->get_accValue(varIn, &bstrValue) == S_OK) {
		char *pszValue = _com_util::ConvertBSTRToString(bstrValue) ;
		printf("  Value: %s\r\n", pszValue) ;
		delete[] pszValue ;
		SysFreeString(bstrValue) ;
	} else
		printf("  Value: not available\r\n") ;
}

void print_acc_description(VARIANT varIn, IAccessible *pAccessible) {
	BSTR bstrValue ;

	if (pAccessible->get_accDescription(varIn, &bstrValue) == S_OK) {
		char *pszValue = _com_util::ConvertBSTRToString(bstrValue) ;
		printf("  Description: %s\r\n", pszValue) ;
		delete[] pszValue ;
		SysFreeString(bstrValue) ;
	} else
		printf("  Description: not available\r\n") ;
}

void print_acc_child_count(IAccessible *pAccessible) {
	long count ;
	pAccessible->get_accChildCount(&count) ;
	printf("  Number of childs: %d\r\n", count) ;
}

void print_acc_role(VARIANT varIn, IAccessible *pAccessible) {
	VARIANT varOut ;
	VariantInit(&varOut) ;
	varOut.vt = VT_I4 ;

	pAccessible->get_accRole(varIn, &varOut) ;

	int roleTextMax = 255 ;
	LPTSTR pRoleText = new TCHAR[roleTextMax] ;
	GetRoleText(varOut.lVal, pRoleText, roleTextMax) ;

	int lenSzRoleText = 255 ;
	char *pszRoleText = new char[lenSzRoleText] ;
	WideCharToMultiByte(CP_ACP, 0, pRoleText, wcslen(pRoleText) + 1, pszRoleText, lenSzRoleText, NULL, NULL) ;

	printf("  Role is %s\r\n", pszRoleText) ;
}

void print_properties(IAccessible *pAccessible, long childId) {
	VARIANT varChild ;
	VariantInit(&varChild) ;
	varChild.vt = VT_I4 ;
	varChild.lVal = childId ;

	print_acc_name(varChild, pAccessible) ;
	print_acc_value(varChild, pAccessible) ;
	print_acc_role(varChild, pAccessible) ;
	print_acc_description(varChild, pAccessible) ;

	if (childId == CHILDID_SELF)
		print_acc_child_count(pAccessible) ;
}

void iterate_over_childs(IAccessible *pAccessible) {
	printf("Iterating over childs\r\n") ;

	long childCount ;
	pAccessible->get_accChildCount(&childCount) ;

	for (int childId = 1; childId <= childCount; childId++) {
		printf("Child number %d: ", childId) ;
		VARIANT varChild ;
		VariantInit(&varChild) ;
		varChild.vt = VT_I4 ;
		varChild.lVal = childId ;

		IDispatch *pIDispatch ;
		HRESULT hr = pAccessible->get_accChild(varChild, &pIDispatch) ;
		if (hr == S_OK) {
			printf("get_accChild returned S_OK. Now asking for IDispatch") ;
			IAccessible *pChildIAccessible ;
			pIDispatch->QueryInterface(IID_IAccessible, (void**)&pChildIAccessible) ;
			print_properties(pChildIAccessible, CHILDID_SELF) ;
		} else if (hr == S_FALSE) {
			printf("Simple element\r\n") ;
			print_properties(pAccessible, childId) ;
		} else if (hr == E_INVALIDARG)
			printf("Invalid argument\r\n") ;
		else
			printf("getAccChild returned %x\r\n", hr) ;
	}
}

int _tmain(int argc, _TCHAR* argv[])
{
	printf("ListView Explorer\r\n") ;

	HWND hwndListView = ask_for_list_view_handle() ;

	HMODULE hModule = LoadLibraryA("oleacc.dll");
	if (hModule == 0) {
		printf("Cannot load oleacc.dll\r\n") ;
		return 1 ;
	}

	long numberOfRows ;
	long numberOfColumns ;
	char ***tableStrings ;

	get_table_strings(hModule, hwndListView, (char **)&tableStrings, &numberOfRows, &numberOfColumns) ;

	printf("Now printing result\r\n") ;
	for (int row = 0; row < numberOfRows; row++) {
		for (int column = 0; column < numberOfColumns; column++) {
			printf("row %d, col %d is '%s'\r\n", row, column, tableStrings[row][column]) ;
			free(tableStrings[row][column]) ;
		}
		free(tableStrings[row]) ;
	}


	/*
	printf("ListView Explorer\r\n") ;

	HWND hwndListView = ask_for_list_view_handle() ;
	IAccessible *pAccessible ;
	LPFNACCESSIBLEOBJECTFROMWINDOW lpfnAccessibleObjectFromWindow ;

	HMODULE hModule = LoadLibraryA("oleacc.dll");
	if (hModule == 0) {
		printf("Cannot load oleacc.dll\r\n") ;
		return 1 ;
	}

	lpfnAccessibleObjectFromWindow = (LPFNACCESSIBLEOBJECTFROMWINDOW)GetProcAddress(hModule, "AccessibleObjectFromWindow");

	if (HRESULT hResult = lpfnAccessibleObjectFromWindow(hwndListView, OBJID_CLIENT, IID_IAccessible, (void**)&pAccessible) == S_OK) {
		printf("Got IAccessible\r\n") ;
		print_properties(pAccessible, CHILDID_SELF) ;
		iterate_over_childs(pAccessible) ;
	} else
		printf("Cannot retrieve IAccessible for window HWND %x. AccessibleObjectFromWindow returned %x\r\n", hwndListView, hResult) ;
	*/

	return 0;
}

