------------------------------------------------------------------------------
-- Mercury
-- Sledmine
-- Package Manager for Halo Custom Edition
------------------------------------------------------------------------------
package.path = package.path .. ";Mercury/?.lua"
-- Luapower modules
local argparse = require "argparse"
inspect = require "inspect"
local json = require "cjson"

-- Luapower bundle requires
local luareq = require
function require(modname)
    local ok, mod = pcall(luareq, modname)
    if not ok then
        return luareq("Mercury." .. modname)
    end
    return mod
end

luna = require "modules.luna"
-- Global data and utils for different operations
utils = require "modules.utils"
if isHostWindows() then
    -- Fix for Windows UTF-8 filenames in io and os operations
    require "modules.utf8_filenames"
end
-- Get all environment variables and configurations
config = require "cli.config"
config.load()
local paths = config.paths()
-- Migrate old paths and files to newer ones if needed
-- config.migrate()

-- Modules
install = require "modules.install"
api = require "modules.api"

-- Commands to expose on Mercury
local remove = require "cmd.remove"
local list = require "cmd.list"
local insert = require "cmd.insert"
local latest = require "cmd.latest"
local fetch = require "cmd.fetch"
local pack = require"modules.merc".pack
local packdiff = require"modules.merc".diff
local packtemplate = require"modules.merc".template
local packmanifest = require"modules.merc".manifest
local map = require "cmd.map"
local build = require"cmd.build".build
local buildtemplate = require"cmd.build".template
local serve = require "cmd.serve"

local luabundler = require "modules.luabundle"
local constants = require "modules.constants"

-- Create argument parser with Mercury info
local cliDescription = ([[Mercury Webpage: %s
Join us on Discord: https://discord.shadowmods.net/
Support Mercury on GitHub: https://github.com/Sledmine/Mercury"
]]):format(constants.mercuryWeb)
local parser = argparse("mercury", "Package Manager for Halo Custom Edition.", cliDescription)
-- Disable command required message                        
parser:require_command(false)

-- Catch command name as "command" on the args object
parser:command_target("command")

-- General flags
parser:flag("-v", "Get Mercury version.")
parser:flag("--debug", "Enable debug mode, some debug messages will appear.")
-- parser:flag("--test", "Enable test mode, testing behaviour will occur.")
-- parser:flag("--unsafe", "Set API requests to unsafe mode.")

--- Check flags and paths before executing any command
---@param args table
---@param skipPathValidation? boolean
local function flagsCheck(args, skipPathValidation)
    if not skipPathValidation then
        if not paths.gamePath then
            cprint("Error, Halo Custom Edition path was not found on the system.")
            cprint("Force game path by setting \"HALO_CE_PATH\" as an environment variable.")
            cprint("You can also set it on Mercury config with:\n")
            cprint("mercury config game.path \"my_halo_ce_path\"")

            os.exit(1)
        end
        if not paths.myGamesPath then
            cprint("Error, at trying to get \"My Games\" path from the system.")
            cprint(
                "Force game path by setting \"MY_GAMES_PATH\" or \"HALO_CE_DATA_PATH\" as an environment variable.\n")
            cprint("You can also set it on Mercury config with:\n")
            cprint("mercury config game.data.path \"my_halo_ce_data_path\"")
            os.exit(1)
        end
    end
    if args.v then
        cprint(constants.mercuryVersion)
        os.exit(1)
    end
    if args.debug then
        dprint(args)
        IsDebugModeEnabled = true
        cprint("Warning Debug mode enabled.")
    end
    if args.test then
        IsTestModeEnabled = true
        -- Override respository connection data
        api.protocol = "http"
        api.repositoryHost = "localhost:8180"
        cprint("Warning Test mode enabled.")
    end
    if args.unsafe then
        -- Use http protocol for API requests
        api.protocol = "http"
    end
end

-- Fetch command
local fetchCmd = parser:command("fetch")
fetchCmd:description("Return the latest package index available on Vulcano.")
fetchCmd:flag("-j --json", "Show list in json format.")
fetchCmd:action(function(args, name)
    flagsCheck(args, true)
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
    local code = 0
    if latest() then
        -- TODO Add parsing for custom repository protocol
        if (args.repository) then
            api.repositoryHost = args.repository
        end
        for _, package in pairs(args.package) do
            local packageLabel = package:split("-")[1]
            local packageSplit = package:split(packageLabel .. "-")
            local packageVersion = packageSplit[2]
            if not install.package(packageLabel, packageVersion, args.force, args.skipOptionals) then
                code = 1
            else
                config.clean()
                cprint("Done package " .. packageLabel .. " has been installed.")
            end
        end
    end
    os.exit(code)
end)

-- List command
local listCmd = parser:command("list")
listCmd:description("Shows installed packages.")
listCmd:flag("-j --json", "Show list in json format.")
listCmd:flag("-t --table", "Show list in a lua table format.")
listCmd:action(function(args, name)
    flagsCheck(args)
    if not list(args.json, args.table) then
        os.exit(1)
    end
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
    if not install.update(args.packageLabel) then
        os.exit(1)
    end
    config.clean()
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
    if not remove(args.packageLabel, args.norestore, args.erasebackups, args.recursive, args.index) then
        os.exit(1)
    end
    cprint("Done package " .. args.packageLabel .. " has been removed.")
    os.exit(0)
end)

-- Insert command
local insertCmd = parser:command("insert", "Insert a merc package into the game manually.")
insertCmd:description("Attempts to insert the files from a Mercury package.")
insertCmd:argument("mercPath", "Path of the merc file to insert")
insertCmd:flag("-f --force", "Remove any conflicting files without creating a backup.")
insertCmd:flag("-o --skipOptionals", "Ignore optional files at installation.")
insertCmd:action(function(args, name)
    local code = 0
    flagsCheck(args)
    if insert(args.mercPath, args.force, args.skipOptionals) then
        cprint("Done, files have been inserted.")
    else
        cprint("Error, at inserting merc.")
        code = 1
    end
    config.clean()
    os.exit(code)
end)

local mapCmd = parser:command("map")
mapCmd:description("Download a specific map from our maps repository.")
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
    config.clean()
end)

-- Latest (upgrade mercury) command
local latestCmd = parser:command("latest", "Get latest Mercury version from GitHub.")
latestCmd:description("Download latest Mercury version if available.")
latestCmd:action(function(args, name)
    flagsCheck(args, true)
    if not latest() then
        os.exit(1)
    end
    os.exit(0)
end)

-- Pack command
local packCmd = parser:command("pack", "Pack a given directory into a mercury package.")
packCmd:description("Create a Mercury package from a specific directory.")
packCmd:argument("packDir", "Path to the directory to pack.")
packCmd:argument("mercPath", "Output path for the resultant package."):args("?")
packCmd:flag("-t --template", "Create a package folder template.")
packCmd:flag("-m --manifest", "Get manifest from an existing package.")
packCmd:action(function(args, name)
    local code = 0
    flagsCheck(args, true)
    if args.template then
        packtemplate()
        return
    elseif args.manifest then
        if not packmanifest(args.packDir) then
            code = 1
        end
        return
    else
        if not pack(args.packDir, args.mercPath or ".") then
            code = 1
        end
        config.clean()
    end
    os.exit(code)
end)

-- Diff command
local packdiffCmd = parser:command("packdiff")
packdiffCmd:description("Create an update package from the difference of two packages.")
packdiffCmd:argument("oldPackagePath", "Path to old package used as target.")
packdiffCmd:argument("newPackagePath", "Path to new package as the source.")
packdiffCmd:argument("diffPackagePath", "Path to diff package as the result."):args("?")
packdiffCmd:action(function(args, name)
    local code = 0
    flagsCheck(args, true)
    if not packdiff(args.oldPackagePath, args.newPackagePath, args.diffPackagePath, "7z") then
        code = 1
    end
    config.clean()
    os.exit(code)
end)

-- Bundle command
local luabundleCmd = parser:command("luabundle", "Bundle lua files into one distributable script.")
luabundleCmd:description("Bundle modular lua project into a single script.")
luabundleCmd:argument("bundleFile", "Bundle file name, \"bundle\" by default."):args("?")
luabundleCmd:flag("-c --compile", "Compile output file using target compiler.")
luabundleCmd:flag("-t --template", "Create a bundle template file on current directory.")
luabundleCmd:flag("-r --reload", "Hot reload the bundle file after compilation.")
luabundleCmd:action(function(args, name)
    flagsCheck(args, true)
    if (args.template) then
        luabundler.template()
        return
    end
    if not luabundler.bundle(args.bundleFile, args.compile, args.reload) then
        os.exit(1)
    end
    os.exit(0)
end)

local buildCmd = parser:command("build", "Build a Mercury project using a buildspec file.")
buildCmd:description("Compile and build a Mercury project trough Invader and other tools.")
-- buildCmd:argument("yamlFilePath", "Path to the buildspec file."):args("?")
buildCmd:argument("command", "Command to execute."):args("?")
buildCmd:flag("--verbose", "Output more verbose messages to console.")
buildCmd:flag("--release", "Flag this build as a release.")
buildCmd:flag("--template", "Create a buildspec template file on current directory.")
buildCmd:flag("-s --scenario", "Build specific scenarios."):args("+")
buildCmd:option("--output", "Output path for the build result.")
buildCmd:option("--crc", "Forge crc to use for the build.")
buildCmd:action(function(args, name)
    flagsCheck(args)
    if (args.template) then
        buildtemplate()
        return
    end
    dprint(args)
    if build("buildspec.yaml", args.command, args.verbose, args.release, args.output, args.scenario,
             args.crc) then
        os.exit(0)
    end
    os.exit(1)
end)

-- Config command
local configCmd = parser:command("config", "Manage Mercury configuration.")
configCmd:argument("key", "Configuration key to get or set."):args("?")
configCmd:argument("value", "Value to set to the given key."):args("?")
-- configCmd:flag("-l --list", "List all configuration keys and values.")
configCmd:flag("-r --raw", "Print raw configuration values.")
configCmd:flag("-j --json", "Print configuration values as JSON.")
-- configCmd:flag("-r --reset", "Reset configuration to default values.")
configCmd:action(function(args, name)
    flagsCheck(args, true)
    local output = config.get()
    if args.key then
        if args.value then
            if config.set(args.key, args.value) then
                cprint("Success configuration key \"" .. args.key .. "\" set to \"" .. args.value ..
                           "\".")
            else
                cprint(
                    "Error setting configuration key \"" .. args.key .. "\" to \"" .. args.value ..
                        "\".")
            end
            return
        else
            output = config.get(args.key)
        end
    end
    if args.json then
        print(json.encode(output))
        return
    end
    if not args.raw then
        inspect(output)
        return
    end
    print(output)
end)

---Get option value from argparse table
---@param v table
---@return unknown
local function option(v)
    if v then
        return v[1]
    end
    return nil
end

local serveCmd = parser:command("serve", "Serve a Halo Custom Edition server.")
serveCmd:argument("map", "Map to load on the server."):args("?")
serveCmd:argument("gametype", "Gametype to load on the server."):args("?")
serveCmd:option("-p --port", "Port to use for the server."):args("?")
-- serveCmd:option("-t --template", "Template server to use."):args("?")
serveCmd:option("-s --scripts", "Scripts to load on the server."):args("*")
serveCmd:flag("-n --new", "Create a new temporal server data profile path.")
serveCmd:flag("--server-side-projectiles", "Enable server side projectiles.")
serveCmd:flag("-r --rcon", "Enable remote console on the server.")
serveCmd:option("--rcon-password", "Remote console password to use for the server."):args("?")
serveCmd:option("--difficulty", "Difficulty to use for the server."):choices{
    "easy",
    "normal",
    "hard",
    "impossible"
}:default "normal"
--serveCmd:option("--mapcycle", "Mapcycle to use for the server."):args("*")
serveCmd:action(function(args)
    flagsCheck(args)
    serve(args.map, args.gametype, option(args.port), args.template, args.scripts, args.new, {
        server_side_projectiles = args.server_side_projectiles,
        rcon = args.rcon,
        rcon_password = option(args.rcon_password),
        difficulty = option(args.difficulty)
        --mapcycle = args.mapcycle
    })
    config.clean()
end)

-- About command
local aboutCmd = parser:command("about", "Get Mercury information.")
aboutCmd:action(function(args, name)
    print("Mercury v" .. constants.mercuryVersion)
    print("Package manager for Halo Custom Edition.\n")
    local gamePath = paths.gamePath or "Not found"
    local dataPath = paths.myGamesPath or "Not found"
    cprint("CONF Game path: \"" .. gamePath .. "\"")
    cprint("CONF Data path: \"" .. dataPath .. "\"\n")
    print(cliDescription)
end)

-- Show commands information if no args
if not arg[1] then
    print(parser:get_help())
end

-- Override args array with parser ones
local args = parser:parse()

if args.v then
    cprint(constants.mercuryVersion)
    os.exit(0)
end
