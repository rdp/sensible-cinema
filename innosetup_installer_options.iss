#define VerFile FileOpen("VERSION")
#define AppVer FileRead(VerFile)
#expr FileClose(VerFile)
#undef VerFile

#define AppName "Sensible Cinema"
; AppId === AppName by default BTW

[Run]
; doesn't work? LODO fix Description: Run Sensible Cinema; Filename: {app}\sensible_cinema_wrapper.exe; WorkingDir: {app}; Parameters: -Ilib bin\sensible-cinema; Flags: nowait postinstall
; a checkbox run optional after install...

[UninstallRun]

[Files]
Source: *; DestDir: {app}; Excludes: pkg, html5_javascript, .git, releases, vendor\cache, spec, lib\jruby-swing-helpers\spec, vendor\jruby-complete.jar; Flags: recursesubdirs
Source: README.TXT; DestDir: {app}\vendor; Flags: isreadme

; easier than re-running launch4j? :|
Source: vendor\jruby-complete.jar; DestDir: {app}\vendor; DestName: jruby-complete-1.6.2.jar

; attempt to remove previous versions' icons
[InstallDelete]
Type: filesandordirs; Name: {group}\*;

[Setup]
AppName={#AppName}
AppVerName={#AppVer}beta
; default to someplace editable/installable for now until DVD's don't need it for creation...
DefaultDirName={%HOMEPATH|c:\}\{#AppName} {#AppVer}
; typical: 
; DefaultDirName={pf}\{#AppName} 
DefaultGroupName={#AppName}
UninstallDisplayName={#AppName} uninstall
OutputBaseFilename=Setup {#AppName} v{#AppVer}
OutputDir=releases

[Icons]
Name: {group}\Run Sensible Cinema for DVDs or Files; Filename: {app}\sensible_cinema_wrapper.exe; WorkingDir: {app}; Parameters: -Ilib bin\sensible-cinema; Flags: 
Name: {group}\Advanced\Run Sensible Cinema in advanced or create mode; Filename: {app}\sensible_cinema_debug.exe; WorkingDir: {app}; Parameters: -Ilib bin\sensible-cinema --create-mode; Flags: 
Name: {group}\Advanced\Run Sensible Cinema with debug console; Filename: {app}\sensible_cinema_debug.exe; WorkingDir: {app}; Parameters: -Ilib bin\sensible-cinema; Flags: 
Name: {group}\Advanced\Run Sensible Cinema Online Player mode; Filename: {app}\sensible_cinema_debug.exe; WorkingDir: {app}; Parameters: -Ilib bin\sensible-cinema --online-player-mode; Flags: 
Name: {group}\Advanced\Uninstall {#AppName}; Filename: {uninstallexe}
Name: {group}\Advanced\ChangeLog ; Filename: {app}\change_log_with_feature_list.txt

Name: "{userdesktop}\Run Sensible Cinema for DVDs or Files"; Filename: {app}\sensible_cinema_wrapper.exe; WorkingDir: {app}; Parameters: -Ilib bin\sensible-cinema; Flags: ; IconFilename: vendor/profs.ico  
                                                                                 
[Messages]
;ConfirmUninstall=Are you sure you want to remove %1 (any local EDL files you created will be left on disk, so please upload them first!)?
;FinishedLabel=Done installing [name].  Go start it from your start button -> programs menu, and add some cameras!

; TODO remove vendor/* files at uninstall time
; TODO I have double jruby's...