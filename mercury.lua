------------------------------------------------------------------------------
-- Mercury: Package Manager for Halo Custom Edition
-- Authors: JerryBrick, Sledmine
-- Version: 3.0
------------------------------------------------------------------------------

-- Constant definition.
_MERCURY_VERSION = 3.0
_MERC_EXTENSION = '.merc'

-- Global libraries
argparse = require 'argparse'
inspect = require 'inspect'

-- Local libraries
local combiner = require 'Mercury.actions.combiner'

-- Local function imports
local environment = require 'Mercury.config.environment'

-- Get all environment variables
environment.get()

-- Create argument parser with Mercury info
local parser =
    argparse(
    'mercury',
    'Package manager for Halo Custom Edition.',
    'Support mercury on: https://mercury.shadowmods.net/'
)

-- Catch command name as "command" on the args object
parser:command_target('command')

-- Developer flags
parser:flag('-d --debug', 'Mercury will print debug messages.')
parser:flag('-t --test', 'Every command will test their own functionality.')

-- "Install command"
local install = parser:command('install', 'Download and install any package into the game.')
install:description('Download and install any package from Mercury repository.')
install:argument('packageLabel', 'Label of the package you want to download.')
install:argument('packageVersion', 'Version of the package to retrieve.'):args('?')
install:flag('-f --force', 'Will remove any package and replace any file before installing.')
install:flag('-n --nobackups', 'Avoid backup creation for any conflict package file.')
install:action(
    function(args, name)
        dprint(args)
        if (args.debug) then
            _DEBUG_MODE = true
            dprint('\nMERCURY DEBUG: ON!!!!!')
        end
        if (args.test) then
            _TEST_MODE = true
            dprint('\nMERCURY TEST: ON!!!!!')
        end
        -- (packageLabel, packageVersion, forceInstallation, noBackups)
        combiner.install(args.packageLabel, args.packageVersion, args.force, args.nobackups)
    end
)

-- "Remove command"
local remove = parser:command('remove', 'Delete any currently installed package.')
remove:description('Remove will delete any package that is already installed.')
remove:argument('packageLabel', 'Label of the package you want to remove.')
remove:action(
    function(args, name)
        combiner.remove(args.packageLabel)
    end
)

-- "List command"
local list = parser:command('list', 'Show already installed packages in this game instance.')
list:action(
    function(args, name)
        print("TODO!!!")
    end
)

-- "Mitsosis command"
local mitosis = parser:command("mitosis", "Create a new game instance with just core files.")
mitosis:action(
    function(args, name)
        print("TODO!!!")
    end
)

-- "Version command"
local version = parser:command('version', 'Get Mercury version and usefull info.')
version:action(
    function(args, name)
        cprint(
            '\nMercury - Package Manager, Version ' ..
                _MERCURY_VERSION .. '.\n'
        )
        cprint("My Games path: '" .. _MYGAMES .. "'")
        cprint("Current Halo CE path: '" .. _HALOCE .. "'\n")
    end
)

-- Override args array with parser ones
local args = parser:parse()
