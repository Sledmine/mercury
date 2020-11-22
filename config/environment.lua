------------------------------------------------------------------------------
-- Environment
-- Sledmine
-- Create and provide environment stuff to use over the code
------------------------------------------------------------------------------
local environment = {}

local lfs = require "lfs"
local glue = require "glue"
local json = require "cjson"

-- Libraries importation
local registry = require "registry"

-- Registry keys declaration
local registryEntries = {
    documents = "HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders",
    haloce32 = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Microsoft Games\\Halo CE",
    haloce64 = "HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Microsoft\\Microsoft Games\\Halo CE"
}

local function getMyGamesPath()
    local documentsPath = registry.getkey(registryEntries.documents)
    if (documentsPath ~= nil) then
        return documentsPath.values["Personal"]["value"] .. "\\My Games\\Halo CE"
    else
        print("Error at trying to get 'My Documents' path...")
        os.exit()
    end
    return nil
end

local function getGamePath()
    local registryPath
    local _ARCH = os.getenv("PROCESSOR_ARCHITECTURE")
    registryPath = registry.getkey(registryEntries.haloce64)
    if (_ARCH == "x86") then
        registryPath = registry.getkey(registryEntries.haloce32)
    end
    if (registryPath) then
        return registryPath.values["EXE Path"]["value"]
    else
        print("Error at getting game path, are you using a portable version?...")
        os.exit()
    end
    return nil
end

--- Setup environment to work, environment variables, configuration folder, etc
function environment.get()
    local _TEMP = os.getenv("TEMP")
    local _SOURCEFOLDER = lfs.currentdir()
    local _APPDATA = os.getenv("APPDATA")
    GamePath = getGamePath()
    MyGamesPath = getMyGamesPath()
    _MERCURY_TEMP = _TEMP .. "\\mercury"
    _MERCURY_PACKAGES = _MERCURY_TEMP .. "\\packages"
    if (not exist(_MERCURY_PACKAGES)) then
        createFolder(_MERCURY_PACKAGES)
    end
    _MERCURY_DOWNLOADS = _MERCURY_PACKAGES .. "\\downloaded"
    if (not exist(_MERCURY_DOWNLOADS)) then
        createFolder(_MERCURY_DOWNLOADS)
    end
    _MERCURY_DEPACKED = _MERCURY_PACKAGES .. "\\depacked"
    if (not exist(_MERCURY_DEPACKED)) then
        createFolder(_MERCURY_DEPACKED)
    end
    _MERCURY_INSTALLED = GamePath .. "\\mercury\\installed"
    _HALOCE_INSTALLED_PACKAGES = GamePath .. "\\mercury\\installed\\packages.json"
end

--- Destroy laat environment data, temp folders, trash files...
function environment.destroy()
    delete(_MERCURY_TEMP .. "\\mercury\\", true)
end

--- Get mercury local installed packages
---@param newPackages packageMercury[]
function environment.packages(newPackages)
    if (not newPackages) then
        if (exist(_HALOCE_INSTALLED_PACKAGES)) then
            local installedPackages = json.decode(glue.readfile(_HALOCE_INSTALLED_PACKAGES, "t"))
            if (installedPackages and #glue.keys(installedPackages) > 0) then
                return installedPackages
            end
        else
            createFolder(_MERCURY_INSTALLED)
        end
    else
        local installedPackagesJson = json.encode(newPackages)
        glue.writefile(_HALOCE_INSTALLED_PACKAGES, installedPackagesJson, "t")
    end
    return nil
end

return environment
