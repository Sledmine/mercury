local constants = {}

constants.mercuryVersion = "2.0.0-beta"
constants.xd3CmdLine = "xdelta3 -d -s \"%s\" \"%s\" \"%s\""
constants.latestReleaseApi =
    "https://api.github.com/repos/Sledmine/Mercury/releases/latest"
constants.gitHubReleases = "https://github.com/Sledmine/Mercury/releases/{tagName}/"
constants.mercuryWeb = "http://mercury.shadowmods.net"
constants.packageIndex = constants.mercuryWeb .. "/pindex"
constants.repositoryHost = "genesis.vadam.net"
constants.vulcanoPath = "api/vulcano"

return constants
