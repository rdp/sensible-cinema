#define AppVer "0.41.1"

#define AppName "Sensible Cinema"
; AppId === AppName by default BTW

[Run]
; a checkbox run optional after install, NB, has a console...
Description: Run Sensible Cinema; Filename: "java.exe"; WorkingDir: {app}; Parameters: -jar vendor/jruby-complete-1.6.2.jar -Ilib bin\sensible-cinema; Flags: nowait postinstall runminimized

[UninstallRun]

[Files]
Source: *; DestDir: {app}; Excludes: releases, vendor\cache, spec, lib\jruby-swing-helpers\spec; Flags: recursesubdirs
Source: README.TXT; DestDir: {app}; Flags: isreadme

[Setup]
AppName={#AppName}
AppVerName={#AppVer}
; someplace editable...
DefaultDirName={%HOMEPATH|c:\}\{#AppName} v{#AppVer}
DefaultGroupName={#AppName}
UninstallDisplayName={#AppName} uninstall
OutputBaseFilename=Setup {#AppName} v{#AppVer}
OutputDir=releases

[Icons]
; extra space hopes to make it appear at the top...
Name: {group}\Run Sensible Cinema; Filename: "java.exe"; WorkingDir: {app}; Parameters: -jar vendor/jruby-complete-1.6.2.jar -Ilib bin\sensible-cinema; Flags: runminimized
Name: {group}\advanced\Run Sensible Cinema in advanced or create mode; Filename: "java.exe"; WorkingDir: {app}; Parameters: -jar vendor/jruby-complete-1.6.2.jar -Ilib bin\sensible-cinema  --create-mode; Flags: runminimized
Name: {group}\advanced\Uninstall {#AppName}; Filename: {uninstallexe}
Name: {group}\advanced\ChangeLog ; Filename: {app}\change_log_with_feature_list.txt

[Messages]
;ConfirmUninstall=Are you sure you want to remove %1 (any saved videos will still be left on the disk)?
;FinishedLabel=Done installing [name].  Go start it from your start button -> programs menu, and add some cameras!
