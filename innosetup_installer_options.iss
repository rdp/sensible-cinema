#define AppVer "0.41.6"

#define AppName "Sensible Cinema"
; AppId === AppName by default BTW

[Run]
; doesn't work? LODO fix Description: Run Sensible Cinema; Filename: {app}\sensible_cinema_wrapper.exe; WorkingDir: {app}; Parameters: -Ilib bin\sensible-cinema; Flags: nowait postinstall
; a checkbox run optional after install...

[UninstallRun]

[Files]
Source: *; DestDir: {app}; Excludes: releases, vendor\cache, spec, lib\jruby-swing-helpers\spec; Flags: recursesubdirs
Source: README.TXT; DestDir: {app}; Flags: isreadme

[Setup]
AppName={#AppName}
AppVerName={#AppVer}
; default to someplace editable/installable for now...
DefaultDirName={%HOMEPATH|c:\}\{#AppName}
DefaultGroupName={#AppName}
UninstallDisplayName={#AppName} uninstall
OutputBaseFilename=Setup {#AppName} v{#AppVer}
OutputDir=releases

[Icons]
; extra space hopes to make it appear at the top...
Name: {group}\Run Sensible Cinema; Filename: {app}\sensible_cinema_wrapper.exe; WorkingDir: {app}; Parameters: -Ilib bin\sensible-cinema; Flags: 
Name: {group}\advanced\Run Sensible Cinema in advanced or create mode; Filename: {app}\sensible_cinema_wrapper.exe; WorkingDir: {app}; Parameters: -Ilib bin\sensible-cinema --create-mode; Flags: 
Name: {group}\advanced\Uninstall {#AppName}; Filename: {uninstallexe}
Name: {group}\advanced\ChangeLog ; Filename: {app}\change_log_with_feature_list.txt

[Messages]
;ConfirmUninstall=Are you sure you want to remove %1 (any local EDL files you created will be left on disk, so please upload them first!)?
;FinishedLabel=Done installing [name].  Go start it from your start button -> programs menu, and add some cameras!
