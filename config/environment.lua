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

-- Windows required registry keys
local registryEntries = {
    documents = "HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders",
    haloce32 = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Microsoft Games\\Halo CE",
    haloce64 = "HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Microsoft\\Microsoft Games\\Halo CE"
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
        if (query) then
            gamePath = query.values["EXE Path"]["value"]
        end
    end
    if (not gamePath) then
        cprint("Error, Halo Custom Edition path was not found on the system.")
        cprint("Force game path by setting \"HALO_CE_PATH\" as an environment variable.\n")
        cprint("Example:")
        cprint([[On Linux: export HALO_CE_PATH="/home/117/.wine/c/Halo Custom Edition"]])
        cprint([[On Windows: set HALO_CE_PATH="D:\Games\Halo Custom Edition"]])
        os.exit()
    end
    return gamePath
end

local function getMyGamesPath()
    -- Override documents path using environment variables
    local documentsPath = os.getenv("MY_GAMES_PATH") or os.getenv("HALO_CE_DATA_PATH")
    if (jit.os == "Windows" and not documentsPath) then
        local query = registry.getkey(registryEntries.documents)
        if (query) then
            documentsPath = query.values["Personal"]["value"] .. "\\My Games\\Halo CE"
        end
    end
    if (not documentsPath) then
        cprint("Error, at trying to get \"My Games\" path from the system.")
        cprint("Force game path by setting \"MY_GAMES_PATH\" or \"HALO_CE_DATA_PATH\" as an environment variable.\n")
        cprint("Example:")
        cprint([[On Linux: export MY_GAMES_PATH="/home/117/Documents/My Games/Halo CE"]])
        cprint([[On Windows: set MY_GAMES_PATH="D:\Users\117\Documents\My Games\Halo CE"]])
        os.exit()
    end
    return documentsPath
end

--- Setup environment to work, environment variables, configuration folder, etc
function environment.get()
    local tempFolder = os.getenv("TEMP") or "/tmp"
    local sourceFolder = lfs.currentdir()
    local appData = os.getenv("APPDATA")
    Arch = os.getenv("PROCESSOR_ARCHITECTURE")
    if (Arch ~= "x86") then
        Arch = "x64"
    end
    GamePath = getGamePath()
    MyGamesPath = getMyGamesPath()
    MercuryTemp = tempFolder .. "/mercury"
    MercuryPackages = MercuryTemp .. "/packages"
    if (not exist(MercuryPackages)) then
        createFolder(MercuryPackages)
    end
    MercuryDownloads = MercuryPackages .. "/downloaded"
    if (not exist(MercuryDownloads)) then
        createFolder(MercuryDownloads)
    end
    MercuryUnpacked = MercuryPackages .. "/unpacked"
    if (not exist(MercuryUnpacked)) then
        createFolder(MercuryUnpacked)
    end
    MercuryInstalled = GamePath .. "/mercury/installed"
    MercuryIndex = GamePath .. "/mercury/installed/packages.json"
end

--- Clean temp data, temp folders, trash files...
function environment.cleanTemp()
    dprint("MercuryTemp: " .. MercuryTemp)
    delete(MercuryTemp, true)
end

--- Get mercury local installed packages
---@param newPackages packageMercury[]
---@return packageMercury[] packages
function environment.packages(newPackages)
    if (not newPackages) then
        if (exist(MercuryIndex)) then
            local installedPackages = json.decode(glue.readfile(MercuryIndex, "t"))
            if (installedPackages and #glue.keys(installedPackages) > 0) then
                return installedPackages
            end
        else
            createFolder(MercuryInstalled)
        end
    else
        local installedPackagesJson = json.encode(newPackages)
        glue.writefile(MercuryIndex, installedPackagesJson, "t")
    end
    return nil
end

return environment
