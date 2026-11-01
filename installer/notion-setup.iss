; Notion Setup — rebranded AutoHotkey v2
; SourceDir is set to repo root (parent of this file's folder).

#define AppName    "Notion"
#define AppVersion "2.0"
#define RepoRoot   SourcePath + "..\"

[Setup]
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=Notion Labs, Inc.
AppPublisherURL=https://notion.so
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
OutputDir={#RepoRoot}
OutputBaseFilename=Notion_Setup
SetupIconFile={#RepoRoot}NotionIcon.ico
UninstallDisplayName=Notion
UninstallDisplayIcon={app}\Notion.exe
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
DisableDirPage=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; Rebranded runtime
Source: "{#RepoRoot}Notion.exe";       DestDir: "{app}"; Flags: ignoreversion
Source: "{#RepoRoot}NotionIcon.ico";   DestDir: "{app}"; Flags: ignoreversion
; Launcher: opens the Dash when user runs Notion.exe with no script
Source: "NotionLauncher.ahk";          DestDir: "{app}"; DestName: "Notion.ahk"; Flags: ignoreversion
; AutoHotkey UX / Dash  (internal AHK branding inside the window is unchanged)
Source: "{#RepoRoot}ahk-ux\*";         DestDir: "{app}\UX"; Flags: ignoreversion recursesubdirs createallsubdirs

[Registry]
; .ahk file association → Notion.exe
Root: HKLM; Subkey: "SOFTWARE\Classes\.ahk";                              ValueType: string; ValueName: "";        ValueData: "AutoHotkeyScript";              Flags: uninsdeletevalue
Root: HKLM; Subkey: "SOFTWARE\Classes\AutoHotkeyScript";                   ValueType: string; ValueName: "";        ValueData: "Notion Script";                  Flags: uninsdeletekey
Root: HKLM; Subkey: "SOFTWARE\Classes\AutoHotkeyScript\DefaultIcon";       ValueType: string; ValueName: "";        ValueData: "{app}\Notion.exe,1"
Root: HKLM; Subkey: "SOFTWARE\Classes\AutoHotkeyScript\Shell\Open\Command"; ValueType: string; ValueName: "";        ValueData: """{app}\Notion.exe"" ""%1"" %*"
; Also override per-user association in case AHK set one
Root: HKCU; Subkey: "SOFTWARE\Classes\.ahk";                              ValueType: string; ValueName: "";        ValueData: "AutoHotkeyScript";              Flags: uninsdeletevalue
Root: HKCU; Subkey: "SOFTWARE\Classes\AutoHotkeyScript\Shell\Open\Command"; ValueType: string; ValueName: "";        ValueData: """{app}\Notion.exe"" ""%1"" %*"

[Dirs]
; Create the user's Notion scripts folder in Documents
Name: "{userdocs}\Notion"; Flags: uninsneveruninstall

[Icons]
Name: "{group}\Notion";           Filename: "{app}\Notion.exe"; IconFilename: "{app}\NotionIcon.ico"
Name: "{commondesktop}\Notion";   Filename: "{app}\Notion.exe"; IconFilename: "{app}\NotionIcon.ico"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Run]
Filename: "{app}\Notion.exe"; Description: "Launch Notion"; Flags: nowait postinstall skipifsilent
