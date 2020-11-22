------------------------------------------------------------------------------
-- Mercury
-- JerryBrick, Sledmine
-- Package Manager for Halo Custom Edition
-- Version 3.0
------------------------------------------------------------------------------
-- Constant definition.
_MERCURY_VERSION = 3.0
_MERC_EXTENSION = ".merc"

-- Global libraries
argparse = require "argparse"
inspect = require "inspect"

-- Provide path to project modules
package.path = package.path .. ";.\\Mercury\\?.lua"

utils = require "lib.utils" 

-- Project modules
local combiner = require "actions.combiner"
local install = require "actions.install"
api = require "modules.api"

-- Global data
environment = require "config.environment"

-- Get all environment variables and configurations
environment.get()

-- Cleanup
environment.destroy()

-- Create argument parser with Mercury info
local parser = argparse("mercury", "Package Manager for Halo Custom Edition.",
                        "Support mercury on: https://mercury.shadowmods.net")
-- Disable command required message                        
parser:require_command(false)

-- Catch command name as "command" on the args object
parser:command_target("command")

-- Developer flags
parser:flag("-d --debug", "Debug mode will be enabled to print debug messages.")
parser:flag("-t --test", "Test mode will be enabled, some testing behaviour will occur.")

local function flagsCheck(args)
    if (args.debug) then
        _DEBUG_MODE = true
        cprint("Warning, Debug mode enabled.")
    end
    if (args.test) then
        _TEST_MODE = true
        -- Override respository connection data
        api.repositoryHost = "localhost:3000"
        api.httpProtocol = "http"
        api.librarianPath = "api/vulcano"
        cprint("Warning, Test mode enabled.")
    end
end

-- Install command
local installCmd = parser:command("install", "Install any package into the game.")
installCmd:description("Install will download and add any package from Mercury repository.")
installCmd:argument("packageLabel", "Label of the package you want to download.")
installCmd:argument("packageVersion", "Version of the package to install."):args("?")
installCmd:flag("-f --force", "Remove any existing package and force new package installation.")
installCmd:flag("-n --nobackups", "Avoid backup creation for any conflicting package.")
installCmd:action(function(args, name)
    flagsCheck(args)
    install.package(args.packageLabel, args.packageVersion, args.force, args.nobackups)
end)

-- Update command
local update = parser:command("update", "Update any installed package in this game instance.")
update:description("Update any package in your game by binary difference.")
update:argument("packageLabel", "Label of the package you want to update.")
--update:argument("packageVersion", "Version of the package to update, latest by default."):args("?")
--update:flag("-f --force", "Remove any existing package and force new package installation.")
update:action(function(args, name)
    flagsCheck(args)
    combiner.update(args.packageLabel)
end)

-- Bundle command
local bundle = parser:command("bundle", "Bundle any lua mod into a single deployable script.")
bundle:description("Merge any modular lua project into a single script with dependencies.")
bundle:flag("-c --compile", "Compile this project using the lua target compiler in the bundle file.")
bundle:action(function(args, name)
    flagsCheck(args)
    combiner.bundle(nil, args.compile)
end)

-- "Remove command"
local remove = parser:command("remove", "Delete any currently installed package.")
remove:description("Remove will delete any package that is already installed.")
remove:argument("packageLabel", "Label of the package you want to remove.")
remove:flag("-n --norestore", "Prevent previous backups from being restored.")
remove:flag("-e --erasebackups", "Erase previously created backups.")
remove:flag("-r --recursive", "Remove all the dependencies of this package.")
remove:action(function(args, name)
    flagsCheck(args)
    combiner.remove(args.packageLabel, args.norestore, args.erasebackups, args.recursive)
end)

-- "List command"
local list = parser:command("list", "Show already installed packages in this game instance.")
list:flag("-j --json", "Print the packages list in a json format.")
list:flag("-t --table", "Print the packages list in a lua table format.")
list:action(function(args, name)
    flagsCheck(args)
    combiner.list(args.json, args.table)
end)

-- "Mitsosis command"
--[[local mitosis = parser:command("mitosis", "Create a new game instance with just core files.")
mitosis:action(function(args, name)
    print("TODO!!!")
end)]]

-- "Version command"
local version = parser:command("version", "Get Mercury version and usefull info.")
version:action(function(args, name)
    cprint("Mercury - Package Manager, Version " .. _MERCURY_VERSION .. ".")
    cprint("Licensed in GNU General Public License v3.0")
    cprint("My Games path: '" .. MyGamesPath .. "'")
    cprint("Current Halo CE path: '" .. GamePath .. "'")
end)

-- Show commands information if no args
if (not arg[1]) then
    print(parser:get_help())
end

-- Override args array with parser ones
local args = parser:parse()
