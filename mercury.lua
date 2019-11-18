------------------------------------------------------------------------------
-- Mercury: Package Manager for Halo Custom Edition 
-- Authors: JerryBrick, Sledmine
-- Version: 3.0
------------------------------------------------------------------------------

-- Constant definition.
_MERCURY_VERSION = 3.0
_MERC_EXTENSION = ".merc"

-- Super function to print ASCII color strings
function cprint(text)
    print(colors(text))
end

-- Global libraries
inspect = require "inspect"
colors = require "ansicolors"

-- Local libraries
local actions = require "Mercury.actions.mixer"
local mercury = require "Mercury.internal.about"

-- Local function imports
local environment = require "Mercury.config.environment"

-- Temp stuff
 config = {}
 host = "mercury.shadowmods.net" -- URL for the main repo (example: http://lua.repo.net/)
 protocol = "https://"
 librarianPath = "librarian.php?" -- Path for master librarian index

--[[ TODO STUFF: Global function creation.    
local function mercurySetup()
    -- Create registry entries
    --[[registry.writevalue("HKEY_CLASSES_ROOT\\.merc", "", "REG_SZ", "Mercury Package")
    registry.writevalue("HKEY_CLASSES_ROOT\\.merc\\DefaultIcon", "", "REG_SZ", "\"".._SOURCEFOLDER.."\\assets\\icons\\package.ico\",0")
    registry.writevalue("HKEY_CLASSES_ROOT\\.merc\\shell\\open\\command", "", "REG_SZ", "\"".._SOURCEFOLDER.."\\mercury.exe\" merc %1")
    print("Mercury Successfully setup!")
end]]

-- Main program entry

-- Get all environment variables
environment.get()
cprint("\n%{white bright}[ Mercury - Package Manager | Version: %{reset}%{yellow bright}" .. _MERCURY_VERSION .. " %{white}]\n")
if (#arg == 0) then
    mercury.printUsage()
else
    cprint("%{yellow bright}Current Halo CE path: %{white}'" .. _HALOCE .. "'")
    cprint("%{yellow bright}Current My Games path: %{white}'" .. _MYGAMES .. "'\n")
    local parameters
    if (arg[1] == "install") then -- INSTALL Command
        if (arg[2] ~= nil) then
            local forceInstallation
            local noBackups
            if (arg[3] ~= nil) then
                parameters = ""
                for i = 3,#arg do
                    parameters = parameters..arg[i]
                end
                if (string.find(parameters, "-f") ~= nil) then
                    forceInstallation = true
                end
                if (string.find(parameters, "-nb") ~= nil) then
                    noBackups = true
                end
            end
            actions.download(arg[2], forceInstallation, noBackups)
        else
            printUsage()
        end
    elseif (arg[1] == "remove") then -- REMOVE Command
        if (arg[2] ~= nil) then
            local noBackups
            local eraseBackups
            if (arg[3] ~= nil) then
                parameters = ""
                for i = 3,#arg do
                    parameters = parameters..arg[i]
                end
                if (string.find(parameters, "-eb") ~= nil) then
                    eraseBackups = true
                end
                if (string.find(parameters, "-nb") ~= nil) then
                    noBackups = true
                end
            end
            actions.remove(arg[2], noBackups, eraseBackups)
        else
            printUsage()
        end
    elseif (arg[1] == "update") then  -- UPDATE Command
        if (arg[2] ~= nil) then
            actions.update(arg[2])
        else
            printUsage()
        end
    elseif (arg[1] == "list") then -- LIST Command
        if (arg[2] ~= nil) then
            local onlyNames
            local detailList
            if (arg[3] ~= nil) then
                parameters = ""
                for i = 3,#arg do
                    parameters = arg[i]
                end
                if (string.find(parameters, "-l") ~= nil) then
                    onlyNames = true
                end
            end
            actions.list(arg[2], onlyNames, detailList)
        else
            printUsage()
        end
    elseif (arg[1] == "merc") then
        if (arg[2] ~= nil) then
            actions.install(arg[2])
        else
            printUsage()
        end
    elseif (arg[1] == "mitosis") then
        if (arg[2] ~= nil) then
            actions.mitosis(arg[2])
        else
            printUsage()
        end
    elseif (arg[1] == "version") then
        mercury.printVersion()
    elseif (arg[1] == "set") then
        if (arg[2] ~= nil) then
            actions.set(arg[2])
        else
            printUsage()
        end
    else
        print("'"..arg[1].."' is not an available action...")
    end
end