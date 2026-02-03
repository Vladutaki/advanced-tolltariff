; Inno Setup script for per-user install of Advanced Tolltariff
; Install into %LOCALAPPDATA%\AdvancedTolltariff and create shortcuts

#define AppName "Advanced Tolltariff"
#define AppVersion "1.0.0"
#define AppPublisher "Your Org"
#define InstallDir "{localappdata}\\AdvancedTolltariff"

[Setup]
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={#InstallDir}
DisableDirPage=yes
DisableProgramGroupPage=yes
AllUsers=no
PrivilegesRequired=lowest
OutputDir=.
OutputBaseFilename=AdvancedTolltariffSetup
Compression=lzma
SolidCompression=yes

[Files]
Source: "..\\..\\*"; DestDir: "{#InstallDir}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{groupname}\\{#AppName}"; Filename: "{#InstallDir}\\packaging\\windows\\run.bat"
Name: "{userdesktop}\\{#AppName}"; Filename: "{#InstallDir}\\packaging\\windows\\run.bat"

[Run]
Filename: "{#InstallDir}\\packaging\\windows\\run.bat"; Description: "Start Advanced Tolltariff"; Flags: postinstall nowait
