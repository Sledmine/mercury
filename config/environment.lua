------------------------------------------------------------------------------
-- Environment
-- Author: Sledmine
-- Version: 2.0
-- Create and provide environment stuff to use over the code
------------------------------------------------------------------------------
local environment = {}

local lfs = require("lfs")
local glue = require("glue")
local json = require("cjson")

-- Libraries importation
local registry = require "registry"

-- Registry keys declaration
REGENTRIES = {
    DOCUMENTS = "HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders",
    HALOCE32 = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Microsoft Games\\Halo CE",
    HALOCE64 = "HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Microsoft\\Microsoft Games\\Halo CE",
}

local function getMyGamesPath()
    local documentsPath = registry.getkey(REGENTRIES.DOCUMENTS)
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
    registryPath = registry.getkey(REGENTRIES.HALOCE64)
    if (_ARCH == "x86") then
        registryPath = registry.getkey(REGENTRIES.HALOCE32)
    end
    if (registryPath) then
        return registryPath.values["EXE Path"]["value"]
    else
        print("Error at getting Halo CE path, are you using a portable version?...")
        os.exit()
    end
    return nil
end

--[[
_MERCURY_CONFIG = _MYGAMES.."\\mercury\\config.json"
    if (utilis.fileExist(_MERCURY_CONFIG)) then
    config = json.decode(utilis.fileToString(_MERCURY_CONFIG))
    if (config.HaloCE) then
        _HALOCE = config.HaloCE
    end
end
local function mercurySetup()
    -- Create registry entries
    --[[registry.writevalue("HKEY_CLASSES_ROOT\\.merc", "", "REG_SZ", "Mercury Package")
    registry.writevalue("HKEY_CLASSES_ROOT\\.merc\\DefaultIcon", "", "REG_SZ", "\"".._SOURCEFOLDER.."\\assets\\icons\\package.ico\",0")
    registry.writevalue("HKEY_CLASSES_ROOT\\.merc\\shell\\open\\command", "", "REG_SZ", "\"".._SOURCEFOLDER.."\\mercury.exe\" merc %1")
    print("Mercury Successfully setup!")
end]]

--- Setup environment to work, environment variables, configuration folder, etc
function environment.get() 
    local _TEMP = os.getenv("TEMP")
    local _SOURCEFOLDER = lfs.currentdir()
    local _APPDATA = os.getenv("APPDATA")
    _HALOCE = getGamePath()
    _MYGAMES = getMyGamesPath()
    _MERCURY_TEMP = _TEMP .. "\\mercury"
    _MERCURY_PACKAGES = _MERCURY_TEMP .. "\\packages"
    if (not folderExist(_MERCURY_PACKAGES)) then
        createFolder(_MERCURY_PACKAGES)
    end
    _MERCURY_DOWNLOADS = _MERCURY_PACKAGES .. "\\downloaded"
    if (not folderExist(_MERCURY_DOWNLOADS)) then
        createFolder(_MERCURY_DOWNLOADS)
    end
    _MERCURY_DEPACKED = _MERCURY_PACKAGES .. "\\depacked"
    if (not folderExist(_MERCURY_DEPACKED)) then
        createFolder(_MERCURY_DEPACKED)
    end
    _MERCURY_INSTALLED = _HALOCE .. "\\mercury\\installed"
    _HALOCE_INSTALLED_PACKAGES = _HALOCE .. "\\mercury\\installed\\packages.json"
end

--- Destroy environment previously created, temp folders, trash files, etc
function environment.destroy()
    deleteFile(_MERCURY_TEMP .. "\\mercury\\", true)
end

--- Get mercury local installed packages
---@param newPackages packageMercury[]
function environment.packages(newPackages)
    if (not newPackages) then
        if (fileExist(_HALOCE_INSTALLED_PACKAGES)) then
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
