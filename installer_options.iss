#define AppVer "0.41.0"

#define AppName "Sensible Cinema"
; AppId === AppName by default BTW

[Run]
; a checkbox run optional after install, disabled since it has a console...
; Filename: vendor/jruby-complete-1.7.0.jar; Description: Launch {#AppName} after finishing installation; WorkingDir: {app}; Parameters: -Ilib bin\startup.rb --background-start; Flags: nowait postinstall

[UninstallRun]

[Files]
Source: *; DestDir: {app}; Excludes: releases; Flags: recursesubdirs
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
Name: "{group}\Run Sensible Cinema"; Filename: java.exe; WorkingDir: {app}; Parameters: -jar vendor/jruby-complete-1.6.2.jar -Ilib bin\sensible-cinema
Name: "{group}\Run Sensible Cinema in advanced or create mode"; Filename: java.exe; WorkingDir: {app}; Parameters: -jar vendor/jruby-complete-1.6.2.jar -Ilib bin\sensible-cinema  --create-mode
; IconFilename: {app}/vendor/webcam-clipart.ico
Name: {group}\Uninstall {#AppName}; Filename: {uninstallexe}

[Messages]
;ConfirmUninstall=Are you sure you want to remove %1 (any saved videos will still be left on the disk)?
;FinishedLabel=Done installing [name].  Go start it from your start button -> programs menu, and add some cameras!
