local constants = {}

constants.mercuryVersion = "3.0.1-beta"
constants.xd3CmdLine = "xdelta3 -d -s \"%s\" \"%s\" \"%s\""
constants.xd3CmdDiffLine = "xdelta3 -v -f -e -s \"%s\" \"%s\" \"%s\""
constants.latestReleaseApi = "https://api.github.com/repos/Sledmine/Mercury/releases/latest"
constants.gitHubReleases = "https://github.com/Sledmine/Mercury/releases/%s/"
constants.mercuryWeb = "https://mercury.shadowmods.net"
constants.repositoryHost = "vulcano.shadowmods.net"
constants.mapRepositoryDownload = "http://maps.halonet.net/maps/%s.zip"
constants.unzipCmdLine = "unzip -q -o \"%s\" -d \"%s\""
--constants.unzipCmdLine = "7za x -y \"%s\" -o\"%s\""
constants.unzipCmdDebugLine = "unzip -o \"%s\" -d \"%s\""
constants.copyCmdWindowsLine = "copy /Y \"%s\" \"%s\""
constants.copyCmdLinuxLine = "cp -f \"%s\" \"%s\""

return constants
