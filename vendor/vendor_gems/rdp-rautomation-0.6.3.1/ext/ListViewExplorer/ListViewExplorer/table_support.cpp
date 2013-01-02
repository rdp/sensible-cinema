#include "stdafx.h"

#define BUFFER_SIZE 255

long get_number_of_rows(IAccessible *pAccessible) {
	long count ;

	pAccessible->get_accChildCount(&count) ;
	return count ;
}

void get_name(long childId, IAccessible *pAccessible, char *itemText) {
	BSTR bstrValue ;

	VARIANT varIn ;
	VariantInit(&varIn) ;
	varIn.vt = VT_I4 ;
	varIn.lVal = childId ;

	if (pAccessible->get_accName(varIn, &bstrValue) == S_OK) {
		char *pszName = _com_util::ConvertBSTRToString(bstrValue) ;
		strcpy(itemText, pszName) ;
		delete[] pszName ;
		SysFreeString(bstrValue) ;
	} else
		strcpy(itemText, "\0") ;
}

HRESULT get_role(long childId, IAccessible *pAccessible, long *pRole) {
	VARIANT varIn ;
	VariantInit(&varIn) ;
	varIn.vt = VT_I4 ;
	varIn.lVal = childId ;

	VARIANT varOut ;
	VariantInit(&varOut) ;
	varOut.vt = VT_I4 ;

	HRESULT hr = pAccessible->get_accRole(varIn, &varOut) ;
	*pRole = varOut.lVal ;

	return hr ;
}

void get_role(long childId, IAccessible *pAccessible, char *itemText) {
	long role ;

	if (get_role(childId, pAccessible, &role) == S_OK) {
		int roleTextMax = 255 ;
		LPTSTR pRoleText = new TCHAR[roleTextMax] ;
		GetRoleText(role, pRoleText, roleTextMax) ;

		int lenSzRoleText = 255 ;
		char *pszRoleText = new char[lenSzRoleText] ;
		WideCharToMultiByte(CP_ACP, 0, pRoleText, wcslen(pRoleText) + 1, pszRoleText, lenSzRoleText, NULL, NULL) ;

		sprintf(itemText, "0x%x, %s", role, pszRoleText) ;
	}
}

void get_description(long childId, IAccessible *pAccessible, char *itemText) {
	BSTR bstrValue ;

	VARIANT varIn ;
	VariantInit(&varIn) ;
	varIn.vt = VT_I4 ;
	varIn.lVal = childId ;

	if (pAccessible->get_accDescription(varIn, &bstrValue) == S_OK) {
		char *pszName = _com_util::ConvertBSTRToString(bstrValue) ;
		strcpy(itemText, pszName) ;
		delete[] pszName ;
		SysFreeString(bstrValue) ;
	} else
		strcpy(itemText, "\0") ;
}

void print_child_name(long childId, IAccessible *pAccessible) {
	char *childName = (char *)malloc(sizeof(char) * BUFFER_SIZE) ;
	get_name(childId, pAccessible, childName) ;

	if (childId == CHILDID_SELF)
		printf("Name for child SELF is %s\r\n", childId, childName) ;
	else
		printf("Name for child %d is %s\r\n", childId, childName) ;

	free(childName) ;
}

void print_child_role(long childId, IAccessible *pAccessible) {
	char *childRole = (char *)malloc(sizeof(char) * BUFFER_SIZE) ;
	get_role(childId, pAccessible, childRole) ;

	if (childId == CHILDID_SELF)
		printf("Role for child SELF is %s\r\n", childId, childRole) ;
	else
		printf("Role for child %d is %s\r\n", childId, childRole) ;

	free(childRole) ;
}

void walk_tree(IAccessible *pAccessible, char **pColumnHeaderNames, long *pColumnHeadersCount) {
	HRESULT hr ;
	long childCount ;

	hr = pAccessible->get_accChildCount(&childCount) ;
	if (FAILED(hr) || childCount == 0)
		return ;

	VARIANT *pChildVariants = new VARIANT[childCount] ;
	long childrenFound ;
	hr = AccessibleChildren(pAccessible, 0, childCount, pChildVariants, &childrenFound) ;
	if (FAILED(hr))
		return ;

	for (int i=1; i < childrenFound + 1; i++) {
		VARIANT vChild = pChildVariants[i] ;
		if (vChild.vt == VT_DISPATCH) {
			IDispatch *pDispatch = vChild.pdispVal ;
			IAccessible *pChildAccessible = NULL ;
			hr = pDispatch->QueryInterface(IID_IAccessible, (void**) &pChildAccessible) ;
			if (hr == S_OK) {
				walk_tree(pChildAccessible, pColumnHeaderNames, pColumnHeadersCount) ;

				pChildAccessible->Release() ;
			}

			pDispatch->Release() ;
		} else {
			long role ;
			get_role(i, pAccessible, &role) ;
			if (role == 0x19) {
				if (pColumnHeaderNames == NULL) {
					*pColumnHeadersCount = *pColumnHeadersCount + 1 ;
				} else {
					char *headerName = (char *)malloc(sizeof(char) * BUFFER_SIZE) ;
					get_name(i, pAccessible, headerName) ;
					pColumnHeaderNames[i - 1] = headerName ;
				}
			}
		}
	}
}

void find_column_headers(IAccessible *pAccessible, char ***pHeaderNames, long *pColumns) {
	long columns = 0 ;

	walk_tree(pAccessible, NULL, &columns) ;
	printf("Columns: %d\r\n", columns) ;

	char **pHeaders = (char **)malloc(sizeof(char *) * columns) ;
	walk_tree(pAccessible, pHeaders, &columns) ;

	*pHeaderNames = pHeaders ;
	*pColumns = columns ;
}

char *trimwhitespace(char *str) {   
	char *end;    
	// Trim leading space   
	while(isspace(*str)) 
		str++;    
	if(*str == 0)  
		// All spaces?     
		return str;    
	// Trim trailing space   
	end = str + strlen(str) - 1;   
	
	while(end > str && isspace(*end)) 
		end--;    // Write new null terminator  

	*(end+1) = 0;   
	
	return str; 
} 

char* remove_column_header_name(char *columnName, char *item) {
	int itemLen = strlen(item) ;
	int columnNameLen = strlen(columnName) ;

	if (itemLen > 0) {
		char *newItem = (char *)malloc(sizeof(char *) * (itemLen - columnNameLen)) ; // still a bit too long

		strcpy(newItem, item + columnNameLen + 2) ;  // :<space>

		free(item) ;
		return newItem ;
	} else
		return item ;
}

void get_table_strings(HMODULE oleAccModule, HWND controlHwnd, char **tableStrings, long *numberOfRowsOut, long *numberOfColumnsOut) {
	IAccessible *pAccessible ;
	LPFNACCESSIBLEOBJECTFROMWINDOW lpfnAccessibleObjectFromWindow ;

	lpfnAccessibleObjectFromWindow = (LPFNACCESSIBLEOBJECTFROMWINDOW)GetProcAddress(oleAccModule, "AccessibleObjectFromWindow");

	if (HRESULT hResult = lpfnAccessibleObjectFromWindow(controlHwnd, OBJID_CLIENT, IID_IAccessible, (void**)&pAccessible) == S_OK) {
		int numberOfRows = get_number_of_rows(pAccessible) ;   // including the header
		long numberOfColumns = 3 ;
		char ***table_rows ;
		char **pHeaderNames ;

		find_column_headers(pAccessible, &pHeaderNames, &numberOfColumns) ;
		
		table_rows = (char ***)malloc(sizeof(char*) * numberOfRows) ;
		table_rows[0] = pHeaderNames ;

		for (int row = 1; row < numberOfRows; row++) {
			char **table_column = (char **)malloc(sizeof(char*) * numberOfColumns) ;

			char *mainItem = (char *)malloc(sizeof(char) * BUFFER_SIZE) ;
			get_name(row, pAccessible, mainItem) ;

			char *description = (char *)malloc(sizeof(char) * 2048) ;
			get_description(row, pAccessible, description) ;

			char *token ;
			if (strlen(description) > 0)
				token = strtok(description, ",") ;
			else
				token = NULL ;

			for (int column = 0; column < numberOfColumns; column++) {
				if (column == 0)
					table_column[column] = mainItem ;
				else {
					char *item = (char *)malloc(sizeof(char) * BUFFER_SIZE) ;

					if (token != NULL) {
						strcpy(item, token) ;
						token = strtok(NULL, ",") ;
					} else
						strcpy(item, "\0") ;

					table_column[column] = remove_column_header_name(pHeaderNames[column], trimwhitespace(item)) ;
				}
			}

			table_rows[row] = table_column ;
		}

		*tableStrings = (char *)table_rows ;
		*numberOfRowsOut = numberOfRows ;
		*numberOfColumnsOut = numberOfColumns ;
	} else {
		*numberOfRowsOut = 0 ;
		*numberOfColumnsOut = 0 ;
	}
}
