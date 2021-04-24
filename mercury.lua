------------------------------------------------------------------------------
-- Mercury
-- Sledmine
-- Package Manager for Halo Custom Edition
------------------------------------------------------------------------------
-- Global modules
inspect = require "inspect"

local argparse = require "argparse"

-- Create custom require due to app bundle messing with the modules import
local appBundle = require "bundle"
local orequire = require
-- Running in compiled mode
if (appBundle.appversion) then
    local function crequire(import)
        local result, error = pcall(function()
            orequire(import)
        end)
        if (result == false) then
            return orequire("Mercury." .. import)
        end
        return orequire(import)
    end
    require = crequire
else
    -- Developer mode, provide path to project modules
    package.path = package.path .. ";.\\Mercury\\?.lua"
end

utils = require "lib.utils"

-- Project modules
-- FIXME Install is a global module due to recursive calls, a better solution should be provided
install = require "modules.install"
api = require "modules.api"

local remove = require "actions.remove"
local list = require "actions.list"
local insert = require "actions.insert"
local latest = require "actions.latest"

local luabundler = require "modules.luabundle"
local constants = require "modules.constants"

-- Global data
environment = require "config.environment"

-- Get all environment variables and configurations
environment.get()

--  FIXME There is a problem with temp files cleanup messing with package installation
-- Cleanup
-- environment.cleanTemp()

-- Create argument parser with Mercury info
local parser = argparse("mercury", "Package Manager for Halo Custom Edition.",
                        "Mercury Webpage: http://mercuryce.com\nJoin us on Discord: https://discord.shadowmods.net/\nSupport Mercury on GitHub: https://github.com/Sledmine/Mercury")
-- Disable command required message                        
parser:require_command(false)

-- Catch command name as "command" on the args object
parser:command_target("command")

-- Developer flags
parser:flag("-d --debug", "Debug mode will be enabled to print debug messages.")
parser:flag("-t --test", "Test mode will be enabled, some testing behaviour will occur.")

local function flagsCheck(args)
    if (args.debug) then
        IsDebugModeEnabled = true
        cprint("Warning, Debug mode enabled.")
    end
    if (args.test) then
        IsTestModeEnabled = true
        -- Override respository connection data
        api.repositoryHost = "localhost:3000"
        api.httpProtocol = "http"
        api.librarianPath = "api/vulcano"
        cprint("Warning, Test mode enabled.")
    end
end

-- Install command
local installCmd = parser:command("install", "Install any package into the game.")
installCmd:description(
    "Install will download and add any package from Mercury repository.")
installCmd:argument("packageLabel", "Label of the package you want to download.")
installCmd:argument("packageVersion", "Version of the package to install."):args("?")
installCmd:flag("-f --force",
                "Force installation by removing packages and deleting conflicting files also avoid backup creation.")
installCmd:flag("-o --skipOptionals", "Ignore optional files at installation.")
installCmd:option("--repository", "Specify a custom repository to use.")
installCmd:action(function(args, name)
    flagsCheck(args)
    -- TODO Add parsing for custom repository protocol
    if (args.repository) then
        api.repositoryHost = args.repository
    end
    install.package(args.packageLabel, args.packageVersion, args.force, args.skipOptionals)
    environment.cleanTemp()
end)

-- Update command
local updateCmd = parser:command("update",
                                 "Update any installed package in this game instance.")
updateCmd:description("Update any package to a next version by downloading difference.")
updateCmd:argument("packageLabel", "Label of the package you want to update.")
updateCmd:option("--repository", "Specify a custom repository to use.")
-- update:argument("packageVersion", "Version of the package to update, latest by default."):args("?")
-- update:flag("-f --force", "Remove any existing package and force new package installation.")
updateCmd:action(function(args, name)
    flagsCheck(args)
    if (args.repository) then
        api.repositoryHost = args.repository
    end
    install.update(args.packageLabel)
    environment.cleanTemp()
end)

-- Upgrade command
local latestCmd = parser:command("latest", "Get latest Mercury version from GitHub.")
latestCmd:description(
    "Open GitHub release page if there is a newer Mercury version available.")
latestCmd:action(function(args, name)
    flagsCheck(args)
    latest()
    environment.cleanTemp()
end)

-- Insert command
local insertCmd =
    parser:command("insert", "Insert a merc package into the game manually.")
insertCmd:description("Attempts to insert the files from a mercury package.")
insertCmd:argument("mercPath", "Path of the merc file to insert")
insertCmd:flag("-f --force", "Remove any conflicting files without creating a backup.")
insertCmd:flag("-o --skipOptionals", "Ignore optional files at installation.")
insertCmd:action(function(args, name)
    flagsCheck(args)
    if (insert(args.mercPath, args.force, args.skipOptionals)) then
        cprint("Done, files have been inserted.")
    else
        cprint("Error, at inserting merc.")
    end
    environment.cleanTemp()
end)

-- Bundle command
local luabundleCmd = parser:command("luabundle",
                                    "Bundle lua files into one distributable script.")
luabundleCmd:description("Bundle modular lua projects into a single script.")
luabundleCmd:argument("bundleFile", "Bundle file name, \"bundle\" by default."):args("?")
luabundleCmd:flag("-c --compile", "Compile output file using target compiler.")
luabundleCmd:flag("-t --template", "Create a bundle template file on current directory.")
luabundleCmd:action(function(args, name)
    flagsCheck(args)
    if (args.template) then
        luabundler.template()
        return
    end
    luabundler.bundle(args.bundleFile, args.compile)
end)

-- Remove command
local removeCmd = parser:command("remove", "Delete any currently installed package.")
removeCmd:description("Remove will delete any package that is already installed.")
removeCmd:argument("packageLabel", "Label of the package you want to remove.")
removeCmd:flag("-n --norestore", "Prevent previous backups from being restored.")
removeCmd:flag("-e --erasebackups", "Erase previously created backups.")
removeCmd:flag("-r --recursive", "Remove all the dependencies of this package.")
removeCmd:flag("-f --force", "Force remove by erasing entry from package index.")
removeCmd:action(function(args, name)
    flagsCheck(args)
    remove(args.packageLabel, args.norestore, args.erasebackups, args.recursive,
           args.force)
end)

-- List command
local listCmd = parser:command("list",
                               "Shows already installed packages in this game instance.")
listCmd:flag("-j --json", "Print the packages list in a json format.")
listCmd:flag("-t --table", "Print the packages list in a lua table format.")
listCmd:action(function(args, name)
    flagsCheck(args)
    list(args.json, args.table)
end)

-- Mitsosis command
--[[local mitosis = parser:command("mitosis", "Create a new game instance with just core files.")
mitosis:action(function(args, name)
    print("TODO!!!")
end)]]

-- About command
local aboutCmd = parser:command("about", "Get Mercury information.")
aboutCmd:action(function(args, name)
    cprint("Package manager for Halo Custom Edition.")
    cprint("Licensed in GNU General Public License v3.0\n")
    cprint("My Games path: \"" .. MyGamesPath .. "\"")
    cprint("Current Halo CE path: \"" .. GamePath .. "\"")
end)

-- Version command
local versionCmd = parser:command("version", "Get Mercury version.")
versionCmd:action(function(args, name)
    cprint(constants.mercuryVersion)
end)

-- Show commands information if no args
if (not arg[1]) then
    print(parser:get_help())
end

-- Override args array with parser ones
local args = parser:parse()
