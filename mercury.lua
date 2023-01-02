------------------------------------------------------------------------------
-- Mercury
-- Sledmine
-- Package Manager for Halo Custom Edition
------------------------------------------------------------------------------
-- Luapower modules
local argparse = require "argparse"
local glue = require "glue"
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
local pack = require"Mercury.modules.merc".pack
local packdiff = require"Mercury.modules.merc".diff
local packtemplate = require"Mercury.modules.merc".template
local map = require "Mercury.actions.map"
local build = require "Mercury.actions.build"

local luabundler = require "Mercury.modules.luabundle"
local constants = require "Mercury.modules.constants"
--if isHostWindows() then
--    constants.progressSymbolEmpty = constants.progressSymbolEmptyWindows
--    constants.progressSymbolFull = constants.progressSymbolFullWindows
--end

-- Create argument parser with Mercury info
local cliDescription =
    "Mercury Webpage: %s\nJoin us on Discord: https://discord.shadowmods.net/\nSupport Mercury on GitHub: https://github.com/Sledmine/Mercury"
local parser = argparse("mercury", "Package Manager for Halo Custom Edition.",
                        cliDescription:format(constants.mercuryWeb))
-- Disable command required message                        
parser:require_command(false)

-- Catch command name as "command" on the args object
parser:command_target("command")

-- General flags
parser:flag("-v", "Get Mercury version.")
parser:flag("--debug", "Enable debug mode, some debug messages will appear.")
parser:flag("--test", "Enable test mode, testing behaviour will occur.")
parser:flag("--unsafe", "Set API requests to unsafe mode.")

local function flagsCheck(args)
    if (args.v) then
        cprint(constants.mercuryVersion)
        os.exit(1)
    end
    if (args.debug) then
        IsDebugModeEnabled = true
        cprint("Warning Debug mode enabled.")
    end
    if (args.test) then
        IsTestModeEnabled = true
        -- Override respository connection data
        api.protocol = "http"
        api.repositoryHost = "localhost:8180"
        cprint("Warning Test mode enabled.")
    end
    if (args.unsafe) then
        -- Use http protocol for API requests
        api.protocol = "http"
    end
end

-- Fetch command
local fetchCmd = parser:command("fetch")
fetchCmd:description("Return the latest package index available on Vulcano.")
fetchCmd:flag("-j --json", "Show list in json format.")
fetchCmd:action(function(args, name)
    flagsCheck(args)
    fetch(args.json)
end)

-- Install command
local installCmd = parser:command("install")
installCmd:description("Download and insert any package from the Mercury repository.")
installCmd:argument("package", "Package or packages to install."):args("+")
-- installCmd:argument("packageVersion", "Version of the package to install."):args("?")
installCmd:flag("-f --force",
                "Force installation by removing packages, deleting conflicting files and preventing backup creation.")
installCmd:flag("-o --skipOptionals", "Ignore optional files at installation.")
installCmd:option("--repository", "Specify a custom repository to use.")
installCmd:action(function(args, name)
    flagsCheck(args)
    if (latest()) then
        -- TODO Add parsing for custom repository protocol
        if (args.repository) then
            api.repositoryHost = args.repository
        end
        for packageIndex, package in pairs(args.package) do
            local packageLabel = glue.string.split(package, "-")[1]
            local packageSplit = glue.string.split(package, packageLabel .. "-")
            local packageVersion = packageSplit[2]
            install.package(packageLabel, packageVersion, args.force, args.skipOptionals)
        end
    end
    environment.clean()
end)

-- List command
local listCmd = parser:command("list")
listCmd:description("Shows installed packages.")
listCmd:flag("-j --json", "Show list in json format.")
listCmd:flag("-t --table", "Show list in a lua table format.")
listCmd:action(function(args, name)
    flagsCheck(args)
    list(args.json, args.table)
end)

-- Update command
local updateCmd = parser:command("update")
updateCmd:description("Update any package with an update from the Mercury repository.")
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

-- Remove command
local removeCmd = parser:command("remove")
removeCmd:description("Delete any currently installed package.")
removeCmd:argument("packageLabel", "Label of the package you want to remove.")
removeCmd:flag("-n --norestore", "Prevent previous backups from being restored.")
removeCmd:flag("-e --erasebackups", "Erase previously created backups.")
removeCmd:flag("-r --recursive", "Remove all the dependencies of this package.")
removeCmd:flag("-i --index", "Force remove by erasing entry from package index.")
removeCmd:action(function(args, name)
    flagsCheck(args)
    remove(args.packageLabel, args.norestore, args.erasebackups, args.recursive, args.index)
    --environment.clean()
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

local mapCmd = parser:command("map")
mapCmd:description("Download a specific map from our HAC2 mirror repository.")
mapCmd:argument("map", "File name of the map to be downloaded"):args("+")
mapCmd:option("-o --output",
              "Path to download the map as a zip file, prevents map unpacking and installation.")
mapCmd:flag("--hac2",
              "Use the well known (but kinda slow) HAC2 maps repository instead of the default one.")
mapCmd:action(function(args, name)
    flagsCheck(args)
    for _, mapName in pairs(args.map) do
        if args.hac2 then
            map(mapName, args.output, constants.hac2MapRepositoryDownload)
        else
            map(mapName, args.output)
        end
    end
    environment.clean()
end)

-- Latest (upgrade mercury) command
local latestCmd = parser:command("latest", "Get latest Mercury version from GitHub.")
latestCmd:description("Open GitHub release page if there is a newer Mercury version available.")
latestCmd:action(function(args, name)
    flagsCheck(args)
    latest()
end)

-- Pack command
local packCmd = parser:command("pack", "Pack a given directory into a mercury package.")
packCmd:description("Create a Mercury package from a specific directory.")
packCmd:argument("packDir", "Path to the directory to pack.")
packCmd:argument("mercPath", "Output path for the resultant package."):args("?")
packCmd:flag("-t --template", "Create a package folder template.")
packCmd:action(function(args, name)
    flagsCheck(args)
    if (args.template) then
        packtemplate()
        return
    else
        local result = pack(args.packDir, args.mercPath or ".")
        environment.clean()
        if result then
            os.exit(0)
        end
        os.exit(1)
    end
end)

-- Diff command
local packdiffCmd = parser:command("packdiff")
packdiffCmd:description("Create an update package from two Mercury packages difference.")
packdiffCmd:argument("oldPackagePath", "Path to old package used as target.")
packdiffCmd:argument("newPackagePath", "Path to new package as the source.")
packdiffCmd:argument("diffPackagePath", "Path to diff package as the result."):args("?")
packdiffCmd:action(function(args, name)
    flagsCheck(args)
    local result = packdiff(args.oldPackagePath, args.newPackagePath, args.diffPackagePath)
    environment.clean()
    if (result) then
        os.exit(0)
    end
    os.exit(1)
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
    if luabundler.bundle(args.bundleFile, args.compile) then
        os.exit(0)
    end
    os.exit(1)
end)

local buildCmd = parser:command("build", "Build a Mercury project using a buildspec file.")
buildCmd:description("Compile and build a Mercury project trough Invader and other tools.")
--buildCmd:argument("yamlFilePath", "Path to the buildspec file."):args("?")
buildCmd:argument("command", "Command to execute."):args("?")
buildCmd:flag("--verbose", "Output more verbose messages to console.")
buildCmd:flag("--release", "Flag this build as a release.")
buildCmd:option("--output", "Output path for the build result."):args("?")
buildCmd:action(function(args, name)
    flagsCheck(args)
    if build("buildspec.yaml", args.command, args.verbose, args.release, (args.output or {})[1]) then
        os.exit(0)
    end
    os.exit(1)
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
    print("\nCurrent Game Path: " .. paths.gamePath)
    print("Current My Games Data Path: " .. paths.myGamesPath)
end

-- Override args array with parser ones
local args = parser:parse()

if (args.v) then
    cprint(constants.mercuryVersion)
    os.exit(0)
end
