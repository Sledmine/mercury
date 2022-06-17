------------------------------------------------------------------------------
-- Environment
-- Sledmine
-- Create and provide environment stuff to use over the code
------------------------------------------------------------------------------
local environment = {}

local lfs = require "lfs"
local glue = require "glue"
local json = require "cjson"
local registry = require "registry"

-- Paths table instance
local paths

-- Windows required registry keys
local registryEntries = {
    documents = [[HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders]],
    haloce32 = [[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Games\Halo CE]],
    haloce64 = [[HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Microsoft Games\Halo CE]]
}

local function getGamePath()
    -- Override game path using environment variables
    local gamePath = os.getenv("HALO_CE_PATH")
    if (jit.os == "Windows" and not gamePath) then
        local query
        local arch = os.getenv("PROCESSOR_ARCHITECTURE")
        if (arch == "x86") then
            query = registry.getkey(registryEntries.haloce32)
        else
            query = registry.getkey(registryEntries.haloce64)
        end
        if (query and query.values["EXE Path"]) then
            gamePath = query.values["EXE Path"]["value"]
        end
    end
    if (not gamePath) then
        cprint("Error, Halo Custom Edition path was not found on the system.")
        cprint("Force game path by setting \"HALO_CE_PATH\" as an environment variable.\n")
        cprint("Example:")
        cprint([[On Linux: export HALO_CE_PATH="/home/117/.wine/c/Halo Custom Edition"]])
        cprint([[On Windows: set HALO_CE_PATH=D:\Games\Halo Custom Edition]])
        os.exit()
    end
    return gamePath
end

local function getMyGamesHaloCEPath()
    -- Override documents path using environment variables
    local documentsPath = os.getenv("MY_GAMES_PATH") or os.getenv("HALO_CE_DATA_PATH")
    if (jit.os == "Windows" and not documentsPath) then
        local query = registry.getkey(registryEntries.documents)
        if (query and query.values["Personal"]) then
            documentsPath = query.values["Personal"]["value"] .. "\\My Games\\Halo CE"
        end
    end
    if (not documentsPath) then
        cprint("Error, at trying to get \"My Games\" path from the system.")
        cprint(
            "Force game path by setting \"MY_GAMES_PATH\" or \"HALO_CE_DATA_PATH\" as an environment variable.\n")
        cprint("Example:")
        cprint([[On Linux: export MY_GAMES_PATH="/home/117/Documents/My Games/Halo CE"]])
        cprint([[On Windows: set MY_GAMES_PATH=D:\Users\117\Documents\My Games\Halo CE]])
        os.exit()
    end
    return documentsPath
end

--- Setup environment to work, environment variables, configuration folder, etc
function environment.paths()
    -- local sourceFolder = lfs.currentdir()
    -- local appData = os.getenv("APPDATA")

    -- Singleton like method, return gathered paths instead of getting them every invocation
    if (not paths) then
        local gamePath = gpath(getGamePath())
        local myGamesHaloCEPath = gpath(getMyGamesHaloCEPath())
        local mercuryTemp = gpath((os.getenv("TEMP") or "/tmp") .. "/mercury")
        local mercuryDownloads = gpath(mercuryTemp, "/downloads")
        local mercuryUnpacked = gpath(mercuryTemp, "/unpacked")
        local mercuryOldIndex = gpath(gamePath, "/mercury/installed/packages.json")
        local mercuryIndex = gpath(gamePath, "/mercury.json")
        local luaScriptsGlobal = gpath(myGamesHaloCEPath, "/chimera/lua/scripts/global")
        local luaScriptsMap = gpath(myGamesHaloCEPath, "/chimera/lua/scripts/map")
        local luaScriptsSAPP = gpath(myGamesHaloCEPath, "/sapp/lua")
        local luaDataGlobal = gpath(myGamesHaloCEPath, "/chimera/lua/data/global")
        local luaDataMap = gpath(myGamesHaloCEPath, "/chimera/lua/data/map")
        local gameMaps = gpath(gamePath, "/maps")
        local gameDLLMods = gpath(gamePath, "/mods")

        createFolder(mercuryDownloads)
        createFolder(mercuryUnpacked)
        paths = {
            gamePath = gamePath,
            myGamesPath = myGamesHaloCEPath,
            mercuryTemp = mercuryTemp,
            mercuryDownloads = mercuryDownloads,
            mercuryUnpacked = mercuryUnpacked,
            mercuryOldIndex = mercuryOldIndex,
            mercuryIndex = mercuryIndex,
            luaScriptsGlobal = luaScriptsGlobal,
            luaScriptsMap = luaScriptsMap,
            luaScriptsSAPP = luaScriptsSAPP,
            luaDataGlobal = luaDataGlobal,
            luaDataMap = luaDataMap,
            gameMaps = gameMaps,
            gameDLLMods = gameDLLMods
        }
    end
    return paths
end

--- Get mercury local installed packages
---@param newPackages packageMercury[]
---@return packageMercury[] packages
function environment.packages(newPackages)
    if (not newPackages) then
        if (exists(paths.mercuryIndex)) then
            local installedPackages = json.decode(glue.readfile(paths.mercuryIndex, "t"))
            if (installedPackages and #glue.keys(installedPackages) > 0) then
                return installedPackages
            end
        end
    else
        local installedPackagesJson = json.encode(newPackages)
        local result, error = glue.writefile(paths.mercuryIndex, installedPackagesJson, "t")
        return result
    end
    return nil
end

--- Clean temp data, temp folders, trash files...
function environment.clean()
    if (not IsDebugModeEnabled) then
        dprint("Cleaning " .. paths.mercuryTemp .. "...")
        delete(paths.mercuryTemp, true)
    else
        cprint("Warning, environment will not be cleaned due to debug mode!")
    end
end

--- Migrate deprecated or old files and paths
function environment.migrate()
    if (exists(paths.mercuryOldIndex)) then
        cprint("Warning, migrating old packages index path to new index path!")
        move(paths.mercuryOldIndex, paths.mercuryIndex)
        delete(gpath(paths.gamePath, "/mercury"), true)
    end
end

return environment
