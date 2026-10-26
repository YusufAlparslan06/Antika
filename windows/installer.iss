#define MyAppName "Eskilerden"
#define MyAppVersion "1.0.4"
#define MyAppExeName "antika_stok.exe"
#define MyAppIconName "Eskilerden-icon.ico"

[Setup]
AppId={{64B91EC3-FB0B-44D1-8B36-1DF6EF6DCCAA}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=Eskilerden
DefaultDirName={localappdata}\Programs\Eskilerden
DefaultGroupName=Eskilerden
DisableDirPage=no
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppIconName}
SetupIconFile=runner\resources\app_icon.ico
OutputDir=..\dist
OutputBaseFilename=Eskilerden-Setup-x64-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"

[Tasks]
Name: "desktopicon"; Description: "Masaüstüne kısayol oluştur"; GroupDescription: "Ek seçenekler:"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "runner\resources\app_icon.ico"; DestDir: "{app}"; DestName: "{#MyAppIconName}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\Eskilerden"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppIconName}"
Name: "{autodesktop}\Eskilerden"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppIconName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Eskilerden uygulamasını başlat"; Flags: postinstall nowait skipifsilent
