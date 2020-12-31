;# Mercury info
#define NAME "Mercury"
#define VERSION "1.0.3"
#define AUTHOR "Sledmine"
#define WEBSITE "https://mercury.vadam.net/"

;# Setup details
[Setup]
AppId={{D23C545A-EFD1-4E62-8A55-B3512E3CC2E1}
AppName={#NAME}
AppVersion={#VERSION}
AppVerName={#NAME} {#VERSION}
AppPublisher={#AUTHOR}
AppPublisherURL={#WEBSITE}
AppSupportURL={#WEBSITE}
AppUpdatesURL={#WEBSITE}
DefaultDirName={autopf}\Mercury
DefaultGroupName={#NAME}
DisableProgramGroupPage=yes
LicenseFile=LICENSE
;PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64
OutputDir=bin
OutputBaseFilename=mercury-{#VERSION}-x64
Compression=lzma
SolidCompression=yes
WizardStyle=classic
WizardImageFile="assets\images\WizardImageFile.bmp"
WizardSmallImageFile="assets\images\WizardSmallImageFile.bmp"
SetupIconFile="assets\icons\mercury.ico"
UninstallDisplayIcon="assets\icons\mercury.ico"
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Files]
Source: "bin\ANSI32.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "bin\ANSI64.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "bin\ansicon.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "bin\mercury.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "bin\xdelta3.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "mercury_admin.cmd"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{cm:UninstallProgram,{#NAME}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\Mercury Console"; Filename: "{app}\mercury_admin.cmd"; IconFilename: "{app}\mercury.exe"
