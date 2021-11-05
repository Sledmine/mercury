local constants = {}

constants.mercuryVersion = "3.0.0"
constants.xd3CmdLine = "xdelta3 -d -s \"%s\" \"%s\" \"%s\""
constants.xd3CmdDiffLine = "xdelta3 -v -f -e -s \"%s\" \"%s\" \"%s\""
constants.latestReleaseApi = "https://api.github.com/repos/Sledmine/Mercury/releases/latest"
constants.gitHubReleases = "https://github.com/Sledmine/Mercury/releases/%s/"
constants.mercuryWeb = "https://mercury.shadowmods.net"
constants.repositoryHost = "vulcano.shadowmods.net"
--constants.vulcanoPath = ""
constants.mapRepositoryDownload = "http://maps.halonet.net/maps/%s.zip"

return constants
