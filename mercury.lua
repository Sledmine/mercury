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
colors = require 'ansicolors'

-- Local libraries
local combiner = require 'Mercury.actions.combiner'
local mercury = require 'Mercury.internal.about'

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

-- Define commands behaivour and info

-- "Install"
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

--------------------------------------------------------------------------------------------

-- "Remove"
local remove = parser:command('remove', 'Delete any currently installed package.')

remove:description('Remove will delete any package that is already installed.')
remove:argument('packageLabel', 'Label of the package you want to remove.')

remove:action(
    function(args, name)
        combiner.remove(args.packageLabel)
    end
)

--------------------------------------------------------------------------------------------

-- "List"
local list = parser:command('list', 'Show already installed packages in the game.') --'Show already installed packages on this game instance.'

--------------------------------------------------------------------------------------------

-- "Mitsosis"

--parser:command("mitosis", "Create a new game instance with only neccessary base files.")

--------------------------------------------------------------------------------------------

-- "Version"
local version = parser:command('version', 'Get Mercury version and usefull info.')

version:action(
    function(args, name)
        cprint(
            '\n%{white bright}Mercury - Package Manager, Version %{reset}%{yellow bright}' ..
                _MERCURY_VERSION .. '%{white}.\n'
        )
        cprint("%{yellow bright}My Games path: %{white}'" .. _MYGAMES .. "'")
        cprint("%{yellow bright}Current Halo CE path: %{white}'" .. _HALOCE .. "'\n")
    end
)

--------------------------------------------------------------------------------------------

-- Override args array with parser ones
local args = parser:parse()
