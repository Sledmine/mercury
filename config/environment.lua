------------------------------------------------------------------------------
-- Environment
-- Author: Sledmine
-- Version: 2.0
-- Create and provide environment stuff to use over the code
------------------------------------------------------------------------------

local _M = {}

local registry = require 'registry'

-- Super function to print ASCII color strings and structures, tables and functions.
function cprint(value)
    if (type(value) ~= 'string') then
        print(inspect(value))
    else
        print(colors(value))
    end
end

-- Debug print for testing purposes only
function dprint(value)
    if (_DEBUG_MODE and value) then
        cprint(value)
    end
end

local function getMyGamesPath()
    local documentsPath = registry.getkey('HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders')
    if (documentsPath ~= nil) then
        return documentsPath.values['Personal']['value'] .. '\\My Games\\Halo CE'
    else
        print("Error at trying to get 'My Documents' path...")
        os.exit()
    end
    return nil
end

local function getGamePath()
    local registryPath
    local _ARCH = os.getenv('PROCESSOR_ARCHITECTURE')
    registryPath = registry.getkey('HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Microsoft\\Microsoft Games\\Halo CE')
    if (_ARCH == 'x86') then
        registryPath = registry.getkey('HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Microsoft Games\\Halo CE')
    end
    if (registryPath) then
        return registryPath.values['EXE Path']['value']
    else
        print('\nError at trying to get Halo Custom Edition installation path, are you using a portable version (?)')
        os.exit()
    end
    return nil
end

--[[
    DUDE... I DID THIS THING???!
    
    _MERCURY_CONFIG = _MYGAMES.."\\mercury\\config.json"
    if (utilis.fileExist(_MERCURY_CONFIG)) then
        config = json.decode(utilis.fileToString(_MERCURY_CONFIG))
        if (config.HaloCE) then
            _HALOCE = config.HaloCE
        end
    end
    ]]
--[[
        
    JESUS, THIS IS NOT OKKKK!!!!

    _ENVFOLDERS = {
    _MYGAMES.."\\mercury",
    _HALOCE.."\\mercury\\installed",
    ,
    _TEMP.."\\mercury\\packages\\downloaded",
    _TEMP.."\\mercury\\packages\\depacked"}
    for i = 1,#_ENVFOLDERS do
        utilis.createFolder(_ENVFOLDERS[i])
    end
    if (utilis.fileExist(_APPDATA.."\\mercury\\installed\\packages.json") or utilis.fileExist(_MYGAMES.."\\mercury\\installed\\packages.json")) then -- Migrate older installed packages.json to Halo CE folder
        print(colors("\n%{yellow bright}WARNING!!!: Found installed packages json in older path, migrating them to Halo Custom Edition folder now!!!"))
        local result, desc, error = utilis.move(_APPDATA.."\\mercury\\installed\\packages.json" or _MYGAMES.."\\mercury\\installed\\packages.json", _HALOCE.."\\mercury\\installed\\packages.json")
        if (result) then
            utilis.deleteFolder(_APPDATA.."\\mercury\\", true)
            utilis.deleteFolder(_MYGAMES.."\\mercury\\installed", true)
            print(colors("%{green bright}SUCCESS!!!: %{reset}Installed json packages succesfully migrated to Halo Custom Edition folder."))
        else
            print(colors("%{red bright}ERROR!!!: %{reset}Error at trying to migrate packages json, reason: "..tostring(desc).."."))
        end
    end]]
--[[ TODO STUFF: Global function creation.    
local function mercurySetup()
    -- Create registry entries
    --[[registry.writevalue("HKEY_CLASSES_ROOT\\.merc", "", "REG_SZ", "Mercury Package")
    registry.writevalue("HKEY_CLASSES_ROOT\\.merc\\DefaultIcon", "", "REG_SZ", "\"".._SOURCEFOLDER.."\\assets\\icons\\package.ico\",0")
    registry.writevalue("HKEY_CLASSES_ROOT\\.merc\\shell\\open\\command", "", "REG_SZ", "\"".._SOURCEFOLDER.."\\mercury.exe\" merc %1")
    print("Mercury Successfully setup!")
end]]
local function get() -- Setup environment to work, store data, temp files, etc.
    local _TEMP = os.getenv('TEMP')
    local _SOURCEFOLDER = lfs.currentdir()
    local _APPDATA = os.getenv('APPDATA')
    _HALOCE = getGamePath()
    _MYGAMES = getMyGamesPath()
    _MERCURY_PACKAGES = _TEMP .. '\\mercury\\packages'
    if (not folderExist(_MERCURY_PACKAGES)) then
        createFolder(_MERCURY_PACKAGES)
    end
    _MERCURY_DOWNLOADS = _MERCURY_PACKAGES .. '\\downloaded'
    if (not folderExist(_MERCURY_DOWNLOADS)) then
        createFolder(_MERCURY_DOWNLOADS)
    end
    _MERCURY_DEPACKED = _MERCURY_PACKAGES .. '\\depacked'
    if (not folderExist(_MERCURY_DEPACKED)) then
        createFolder(_MERCURY_DEPACKED)
    end
    _MERCURY_INSTALLED = _HALOCE .. '\\mercury\\installed'
    _HALOCE_INSTALLED_PACKAGES = _HALOCE .. '\\mercury\\installed\\packages.json'
end

local function destroyEnvironment() -- Destroy environment previously created, temp folders, trash files, etc
    utilis.deleteFile(_TEMP .. '\\mercury\\', true)
end

_M.get = get

return _M
