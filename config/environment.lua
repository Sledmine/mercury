------------------------------------------------------------------------------
-- Environment
-- Sledmine
-- Create and provide environment stuff to use over the code
------------------------------------------------------------------------------
local environment = {}

local lfs = require "lfs"
local glue = require "glue"
local json = require "cjson"

-- // TODO Move this to a local module
local registry = require "registry"

-- Registry keys declaration
local registryEntries = {
    documents = "HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders",
    haloce32 = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Microsoft Games\\Halo CE",
    haloce64 = "HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Microsoft\\Microsoft Games\\Halo CE"
}

local function getMyGamesPath()
    local documentsPath = registry.getkey(registryEntries.documents)
    if (documentsPath) then
        return documentsPath.values["Personal"]["value"] .. "\\My Games\\Halo CE"
    else
        print("Error at trying to get \"My Documents\" path...")
        os.exit()
    end
    return nil
end

local function getGamePath()
    local registryPath
    local arch = os.getenv("PROCESSOR_ARCHITECTURE")
    registryPath = registry.getkey(registryEntries.haloce64)
    if (arch == "x86") then
        registryPath = registry.getkey(registryEntries.haloce32)
    end
    if (registryPath) then
        return registryPath.values["EXE Path"]["value"]
    else
        print("Error at getting game path, Mercury does not support portable installations.")
        os.exit()
    end
    return nil
end

--- Setup environment to work, environment variables, configuration folder, etc
function environment.get()
    local temp = os.getenv("TEMP")
    local sourceFolder = lfs.currentdir()
    local appData = os.getenv("APPDATA")
    GamePath = getGamePath()
    MyGamesPath = getMyGamesPath()
    MercuryTemp = temp .. "\\mercury"
    MercuryPackages = MercuryTemp .. "\\packages"
    if (not exist(MercuryPackages)) then
        createFolder(MercuryPackages)
    end
    MercuryDownloads = MercuryPackages .. "\\downloaded"
    if (not exist(MercuryDownloads)) then
        createFolder(MercuryDownloads)
    end
    MercuryUnpacked = MercuryPackages .. "\\unpacked"
    if (not exist(MercuryUnpacked)) then
        createFolder(MercuryUnpacked)
    end
    MercuryInstalled = GamePath .. "\\mercury\\installed"
    MercuryIndex = GamePath .. "\\mercury\\installed\\packages.json"
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
