------------------------------------------------------------------------------
-- Environment
-- Sledmine
-- Create and provide environment stuff to use over the code
------------------------------------------------------------------------------
local config = {}
local glue = require "glue"
local json = require "cjson"
local registry = require "registry"

-- Paths table instance
local paths
local cfgPath = gpath(exedir(), "/mercuryconf.json")

---@class configCLI
local cfg = {
    game = {
        path = nil,
        data = {path = nil}
        -- , maps = {path = nil}, mods = {path = nil}
    }
}

-- Windows required registry keys
local registryEntries = {
    documents = [[HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders]],
    haloce32 = [[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Games\Halo CE]],
    haloce64 = [[HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Microsoft Games\Halo CE]]
}

local function getGamePath()
    -- Override game path using environment variables
    local gamePath = getenv("HALO_CE_PATH")
    if (isHostWindows() and not gamePath) then
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
    return gamePath
end

local function getMyGamesHaloCEPath()
    -- Override documents path using environment variables
    local documentsPath = getenv("MY_GAMES_PATH") or getenv("HALO_CE_DATA_PATH")
    if (isHostWindows() and not documentsPath) then
        local query = registry.getkey(registryEntries.documents)
        if (query and query.values["Personal"]) then
            documentsPath = query.values["Personal"]["value"] .. "\\My Games\\Halo CE"
        end
    end
    return documentsPath
end

--- Setup environment to work, environment variables, configuration folder, etc
function config.paths()
    -- local sourceFolder = lfs.currentdir()
    -- local appData = os.getenv("APPDATA")

    -- Singleton like method, return gathered paths instead of getting them every invocation
    if not paths then
        local game = cfg.game.path or gpath(getGamePath())
        local data = cfg.game.data.path or gpath(getMyGamesHaloCEPath())

        if game and data then
            local maps = gpath(game, "/maps")
            local mods = gpath(game, "/mods")

            local mercuryTemp = gpath((getenv "TEMP" or "/tmp") .. "/mercury")
            local mercuryDownloads = gpath(mercuryTemp, "/downloads")
            local mercuryUnpacked = gpath(mercuryTemp, "/unpacked")
            local mercuryIndex = gpath(game, "/mercury.json")
            local mercuryOldIndex = gpath(game, "/mercury/installed/packages.json")

            local luaScriptsGlobal = gpath(data, "/chimera/lua/scripts/global")
            local luaScriptsMap = gpath(data, "/chimera/lua/scripts/map")
            local luaScriptsSAPP = gpath(data, "/sapp/lua")
            local luaDataGlobal = gpath(data, "/chimera/lua/data/global")
            local luaDataMap = gpath(data, "/chimera/lua/data/map")

            createFolder(mercuryDownloads)
            createFolder(mercuryUnpacked)
            paths = {
                gamePath = game,
                myGamesPath = data,
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
                gameMaps = maps,
                gameDLLMods = mods
            }
        end
    end
    return paths
end

--- Get mercury local installed packages
---@param newPackages? packageMercury[]
---@return packageMercury[]? packages
function config.packages(newPackages)
    if (not newPackages) then
        if (exists(paths.mercuryIndex)) then
            local installedPackages = json.decode(readFile(paths.mercuryIndex))
            if (installedPackages and #table.keys(installedPackages) > 0) then
                return installedPackages
            end
        end
    else
        local installedPackagesJson = json.encode(newPackages)
        if writeFile(paths.mercuryIndex, installedPackagesJson) then
            return installedPackagesJson
        end
    end
end

--- Clean temp data, temp folders, trash files...
function config.clean()
    if (not IsDebugModeEnabled) then
        dprint("Cleaning " .. paths.mercuryTemp .. "...")
        delete(paths.mercuryTemp, true)
    else
        cprint("Warning, environment will not be cleaned due to debug mode!")
    end
end

--- Migrate deprecated or old files and paths
function config.migrate()
    if (exists(paths.mercuryOldIndex)) then
        cprint("Warning, migrating old packages index path to new index path!")
        move(paths.mercuryOldIndex, paths.mercuryIndex)
        delete(gpath(paths.gamePath, "/mercury"), true)
    end
end

function config.load()
    local currentCfg
    if exists(cfgPath) then
        currentCfg = json.decode(readFile(cfgPath))
        if currentCfg then
            cfg = table.merge(cfg, currentCfg) --[[@as configCLI]]
        end
    end
    config.paths()
    return currentCfg
end

--- Get CLI configuration
---@param key string?
---@return configCLI
function config.get(key)
    if key then
        if key:includes "." then
            local keys = key:split "."
            local value = cfg
            for _, k in ipairs(keys) do
                value = value[k]
            end
            return value
        else
            return cfg[key]
        end
    end
    return cfg
end

--- Set CLI configuration
---@param key string
---@param value any
---@return boolean
function config.set(key, value)
    if key then
        if value == "" then
            value = nil
        end
        if key:includes "." then
            local keys = key:split "."
            local lastKey = keys[#keys]
            local currentCfg = cfg
            for _, k in ipairs(keys) do
                if k == lastKey then
                    currentCfg[k] = value
                else
                    currentCfg = currentCfg[k]
                end
            end
        else
            cfg[key] = value
        end
        if writeFile(cfgPath, json.encode(cfg)) then
            print(cfgPath)
            return true
        end
    end
    return false
end

return config
