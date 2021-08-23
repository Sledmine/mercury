#define NAME "Mercury"
#define VERSION "$VNUMBER"
#define AUTHOR "Sledmine"
#define WEBSITE "http://mercury.shadowmods.net/"

#include "environment.iss"

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
ArchitecturesInstallIn64BitMode=$ARCH64
OutputDir=bin
OutputBaseFilename=mercury-{#VERSION}+$OSTARGET.$ARCH
Compression=lzma
SolidCompression=yes
WizardStyle=classic
WizardImageFile="assets\images\WizardImageFile.bmp"
WizardSmallImageFile="assets\images\WizardSmallImageFile.bmp"
SetupIconFile="assets\icons\mercury.ico"
UninstallDisplayIcon="assets\icons\mercury.ico"
ChangesEnvironment=true

[Languages] 
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[CustomMessages]
english.AddToPath="Add Mercury to PATH variable" 
spanish.AddToPath="Agregar Mercury a variable PATH"

[Files]
Source: "bin\ansicon\$ARCH\ANSI32.dll"; DestDir: "{app}"; Flags: ignoreversion
;Source: "bin\ansicon\$ARCH\ANSI64.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "bin\ansicon\$ARCH\ansicon.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "bin\xdelta3\$ARCH\xdelta3.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "bin\mercury.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "mercury_admin.cmd"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{cm:UninstallProgram,{#NAME}}"; Filename: "{uninstallexe}"
Name: "{userdesktop}\Mercury Console"; Filename: "{app}\mercury_admin.cmd"; IconFilename: "{app}\mercury.exe"

[Tasks]
Name: envPath; Description: {cm:AddToPath}

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
begin
    if (CurStep = ssPostInstall) and (WizardIsTaskSelected('envPath')) then
        EnvAddPath(ExpandConstant('{app}'));
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
    if CurUninstallStep = usPostUninstall then
        EnvRemovePath(ExpandConstant('{app}'));
end;