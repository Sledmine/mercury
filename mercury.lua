------------------------------------------------------------------------------
-- Mercury
-- Sledmine
-- Package Manager for Halo Custom Edition
------------------------------------------------------------------------------
-- Luapower modules
local argparse = require "argparse"
inspect = require "inspect"

-- Global data and utils for different operations
utils = require "Mercury.modules.utils"
-- Get all environment variables and configurations
environment = require "Mercury.config.environment"
local paths = environment.paths()
-- Migrate old paths and files to newer ones if needed
environment.migrate()

-- Modules
-- FIXME Install is a global module due to recursive calls, a better solution should be provided
install = require "Mercury.modules.install"
api = require "Mercury.modules.api"

-- Commands to expose on Mercury
local remove = require "Mercury.actions.remove"
local list = require "Mercury.actions.list"
local insert = require "Mercury.actions.insert"
local latest = require "Mercury.actions.latest"
local fetch = require "Mercury.actions.fetch"

local luabundler = require "Mercury.modules.luabundle"
local constants = require "Mercury.modules.constants"

-- Create argument parser with Mercury info
local cliDescription = "Mercury Webpage: %s\nJoin us on Discord: https://discord.shadowmods.net/\nSupport Mercury on GitHub: https://github.com/Sledmine/Mercury"
local parser = argparse("mercury", "Package Manager for Halo Custom Edition.", cliDescription:format(constants.mercuryWeb))
-- Disable command required message                        
parser:require_command(false)

-- Catch command name as "command" on the args object
parser:command_target("command")

-- General flags
parser:flag("-v", "Get Mercury version.")
parser:flag("--debug", "Enable debug mode, some extra printing will show.")
parser:flag("--test", "Enable test mode, testing behaviour will occur.")

local function flagsCheck(args)
    if (args.v) then
        cprint(constants.mercuryVersion)
        os.exit(1)
    end
    if (args.debug) then
        IsDebugModeEnabled = true
        cprint("Warning, Debug mode enabled.")
    end
    if (args.test) then
        IsTestModeEnabled = true
        -- Override respository connection data
        api.repositoryHost = "localhost:3000"
        api.protocol = "http"
        api.librarianPath = "api/vulcano"
        cprint("Warning, Test mode enabled.")
    end
end

-- Install command
local installCmd = parser:command("install", "Install any package into the game.")
installCmd:description("Install will download and insert any package from Mercury repository.")
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
    environment.clean()
end)

local fetchCmd = parser:command("fetch", "Fetch the most recent package index from the repository.")
fetchCmd:description("Fetch will return the latest package index available on vulcano.")
fetchCmd:flag("-j --json", "Show list in json format.")
fetchCmd:action(function(args, name)
    flagsCheck(args)
    fetch(args.json)
end)

-- Update command
local updateCmd = parser:command("update", "Update any installed package in this game instance.")
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
    environment.clean()
end)

-- Upgrade command
local latestCmd = parser:command("latest", "Get latest Mercury version from GitHub.")
latestCmd:description("Open GitHub release page if there is a newer Mercury version available.")
latestCmd:action(function(args, name)
    flagsCheck(args)
    latest()
    environment.clean()
end)

-- Insert command
local insertCmd = parser:command("insert", "Insert a merc package into the game manually.")
insertCmd:description("Attempts to insert the files from a Mercury package.")
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
    environment.clean()
end)

-- Bundle command
local luabundleCmd = parser:command("luabundle", "Bundle lua files into one distributable script.")
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
    remove(args.packageLabel, args.norestore, args.erasebackups, args.recursive, args.force)
end)

-- List command
local listCmd = parser:command("list", "Shows already installed packages in this game instance.")
listCmd:flag("-j --json", "Show list in json format.")
listCmd:flag("-t --table", "Show list in a lua table format.")
listCmd:action(function(args, name)
    flagsCheck(args)
    list(args.json, args.table)
end)

-- About command
local aboutCmd = parser:command("about", "Get Mercury information.")
aboutCmd:action(function(args, name)
    cprint("Package manager for Halo Custom Edition.")
    cprint("Licensed in GNU General Public License v3.0\n")
    cprint("My Games path: \"" .. paths.myGamesPath .. "\"")
    cprint("Current Halo CE path: \"" .. paths.gamePath .. "\"")
end)

-- Show commands information if no args
if (not arg[1]) then
    print(parser:get_help())
    print("\nGame Path: " .. paths.gamePath)
    print("My Games Data Path: " .. paths.myGamesPath)
end

-- Override args array with parser ones
local args = parser:parse()

if (args.v) then
    cprint(constants.mercuryVersion)
    os.exit(1)
end
