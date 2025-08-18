local constants = {}

constants.mercuryVersion = "3.8.2"
constants.latestReleaseApi = "https://api.github.com/repos/Sledmine/Mercury/releases/latest"
constants.githubPass = "http://githubpass.shadowmods.net"
constants.mercuryWeb = "https://mercury.shadowmods.net"
constants.repositoryHost = "mercury.shadowmods.net"
constants.hac2MapRepositoryDownload = "http://maps.halonet.net/maps/%s.zip"
constants.mapRepositoryDownload = "http://mercury.shadowmods.net/archive/maps/%s.zip"

-- Commands
constants.xd3CmdLine = "xdelta3 -d -s \"%s\" \"%s\" \"%s\""
constants.xd3CmdDiffLine = "xdelta3 -v -f -e -s \"%s\" \"%s\" \"%s\""
local sevenZipExecutable = "7z"
if isHostWindows() then
    sevenZipExecutable = "7za"
end
constants.sevenZipExtractCmdLine = sevenZipExecutable .. " x -y \"%s\" -o\"%s\""
constants.sevenZipCompressCmdLine = sevenZipExecutable .. " a -y \"%s\" \"%s\""

-- constants.loadingSymbol = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
constants.progressSymbolEmpty = "░"
constants.progressSymbolFull = "█"

constants.maximumProgressSize = 20

return constants
