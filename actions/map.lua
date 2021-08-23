local paths = require"Mercury.config.environment".paths()
local constants = require "Mercury.modules.constants"
local download = require "Mercury.modules.download"
local zip = require "minizip2"

local function unpackMap(mapPath)
    local readZip = zip.open(mapPath, "r")
    if (readZip) then
        readZip:extract_all(gpath(paths.gamePath, "/maps"))
        readZip:close()
        return true
    end
    return false
end

-- TODO Add delete and list flags to provide complete map management
--- Download maps from a external repository
---@param mapName string File name of the map to download
---@param outputPath string Path to download the map as zip file
local function map(mapName, outputPath)
    local downloadUrl = constants.mapRepositoryDownload:format(mapName)
    dprint(downloadUrl)
    local alternativePath = gpath(paths.mercuryDownloads, "/", mapName, ".zip")
    dprint(alternativePath)
    cprint("Downloading map from repository... ")
    local code = download.url(downloadUrl, outputPath or alternativePath)
    if (code and code == 200) then
        cprint("Done, map downloaded successfully.")
        if (not outputPath) then
            cprint("Unpacking map... ", true)
            if (unpackMap(alternativePath)) then
                cprint("done.")
                return true
            end
            cprint("Error, at trying unpacking map zip.")
        end
        return true
    end
    cprint("Error, unable to find map on the repository.")
    return false
end

return map
