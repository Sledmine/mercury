;# Mercury info
#define NAME "Mercury"
#define VERSION "1.0"
#define AUTHOR "Sledmine, JerryBrick"
#define WEBSITE "https://mercury.shadowmods.net/"

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
OutputDir=bin
OutputBaseFilename=mercury-{#VERSION}-x64
Compression=lzma
SolidCompression=yes
WizardStyle=classic

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Files]
Source: "mercury.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "mercury_uac.cmd"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{cm:UninstallProgram,{#NAME}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\Mercury Console"; Filename: "{app}\mercury_uac.cmd"; IconFilename: "{app}\mercury.exe"
