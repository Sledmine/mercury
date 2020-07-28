------------------------------------------------------------------------------
-- Mercury: Package Manager for Halo Custom Edition
-- Authors: JerryBrick, Sledmine
-- Version: 3.0
------------------------------------------------------------------------------
-- Constant definition.
_MERCURY_VERSION = 3.0
_MERC_EXTENSION = ".merc"

-- Global libraries
argparse = require("argparse")
inspect = require("inspect")
utils = require("Mercury.lib.utils")

-- Local libraries
local combiner = require("Mercury.actions.combiner")

-- Global data
environment = require("Mercury.config.environment")

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
        repositoryHost = "localhost:3000"
        httpProtocol = "http://"
        librarianPath = "package?"
        cprint("Warning, Test mode enabled.")
    end
end

-- "Install command"
local install = parser:command("install", "Install any package into the game.")
install:description("Install will download and add any package from Mercury repository.")
install:argument("packageLabel", "Label of the package you want to download.")
install:argument("packageVersion", "Version of the package to install."):args("?")
install:flag("-f --force", "Remove any existing package and force new package installation.")
install:flag("-n --nobackups", "Avoid backup creation for any conflicting package.")
install:action(function(args, name)
    flagsCheck(args)
    combiner.install(args.packageLabel, args.packageVersion, args.force, args.nobackups)
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
list:action(function(args, name)
    print("TODO!!!")
end)

-- "Mitsosis command"
local mitosis = parser:command("mitosis", "Create a new game instance with just core files.")
mitosis:action(function(args, name)
    print("TODO!!!")
end)

-- "Version command"
local version = parser:command("version", "Get Mercury version and usefull info.")
version:action(function(args, name)
    cprint("Mercury - Package Manager, Version " .. _MERCURY_VERSION .. ".")
    cprint("Licensed in GNU General Public License v3.0")
    cprint("My Games path: '" .. _MYGAMES .. "'")
    cprint("Current Halo CE path: '" .. _HALOCE .. "'")
end)

-- Show commands information if no args
if (not arg[1]) then
    print(parser:get_help())
end

-- Override args array with parser ones
local args = parser:parse()
