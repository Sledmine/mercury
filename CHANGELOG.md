# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.7.0] - 2024-06-18
### Added
- Flag `--difficulty` to `serve` command, allows to set the game server difficulty
- Custom tags feature in builspec.yaml for `build` command, allows to set custom tags override for a specific scenario
- Extra tags feature in buildspec.yaml for `build` command, allows to set global extra tags for all scenarios

### Changed
- Package diff in `packdiff` command now will now use the 7z binary to unpack diff packages, improves speed

### Fixed
- Fixed issue with `pack` and `packdiff` commands not properly normalizing paths in Windows

# 3.6.1
- Fixed issue with flag `server_side_projectiles` being inverted in `serve` command
- Added new insert button to UI, allows to insert a package from a local folder
- Added update indicator to UI, helps to see when a new package update is available

# 3.6.0
- Fixed issue with path splitting causing problems with repetitive pattern paths
- Fixed issue with `build` command not filtering properly specific scenarios to build
- Fixed issue with `pack` command at creating packages on Windows resulting in packages not working on Linux
- Added `serve` command to start a game server on demand, experimental
- Added `--crc` flag to `build` command, allows to build a specific scenario or scenarios given a CRC32 hash
- Added current tab navigation highlight to UI
- Fixed images not appearing for installed packages in UI
- Fixed progress bars not appearing properly for some commands on Windows in UI
- Added console view for `update` command in UI, helps to see progress of heavy commands
- Added spinner status bar to UI, helps to see when a Mercury command is still running
- Added cancel command button color change depending if Mercury command executed successfully or not in UI
- Changed minimum window size for UI to 800x510, default window size is 900x510
- Fixed some buttons outline not dissapearing when clicking in other buttons in UI

# 3.5.2
- Fixed issues with package unpacking, backend now uses 7zip instead of minizip (7z packages will be supported in the future)
- Fixed an issue with package cache not taking checksum into account
- Changed default downloads path to user Downloads folder on Windows, helps with cache and gives more control to the user

# 3.5.1
- Fixed an issue with some constant nil paths when no specific game paths are defined
- Added prototype flag `-r --reload` to `luabundle` command, allowing for hot reloading chimera scripts
- Refactored package insertion and downloading more stable and simpler
- Added dependency tree output for required dependencies when installing packages
- Simplified messages output
- Downloaded packages will be kept in the Mercury temp cache folder when installation fails, this will allow to retry installation without downloading the package again
- Added package image preview to UI
- Packages installed by force will not remove previous package if target is not found in the Mercury packages repository
- Mercury install will always add Mercury folder to PATH from now on
- Optional files will be kept when upgrading packages that are dependencies of other packages

# 3.5.0
- Added `--manifest` flag to `pack` command, allows to retrieve manifest from a package
- Added properties validation to `pack --template` for manifest files
- Updated description for some commands
- Added `-s --scenario` to `build` command, allows to build a specific scenario or scenarios
- Added `--template` flag to `build` command, this will bootstrap a build project
- Fixed upgrading to latest version downloading update based on CPU arch instead of Mercury binary arch
- Added `config` command to manage Mercury configuration
- Fixed search bar scrolling to top when searching packages in UI
- Added status game path bar to UI
- Added game path config button to UI
- Added experimental live terminal output to UI, helps to see process of heavy commands

# 3.4.2
- Fixed exit code for `list` command
- Removed "Mercury Admin" shortcut desktop from installer

# 3.4.1
- Fixed exit code when no game paths are defined
- Added Mercury UI to installer (will not work for 32 bits installations, sorry)

# 3.4.0
- Fixed HTTP request timeout not being applied because of an override by another HTTP client
- Add `--template` flag to `build` command, this will create a template of a buildspec.yaml file in the current directory
- Fixed multiple exit codes in different commands (install, update, remove, luabundle, build)

# 3.3.0
- Fixed multi scenario building using `build` command
- Expanded HTTP request timeout to 5000 milliseconds, improving downloading stability
- Fixed bug with installer at attempting to replace ANSICON while updating
- Added UTF8 support in Windows operations like copy and getenv using libuv also by changing Windows code page to 65001 in the Mercury console
- Simplified Mercury console output, now with a more friendly progress bar at downloading files
- Fixed bug with installer at attempting to close other Mercury console instances
- Fixed bug with backups removal and restoring in `remove` command

# 3.2.0
- Added current downloading map name to `map` command
- Added `build` command for standard projects building using a buildspec.yaml file

# 3.1.0
- Added semi automatic Mercury upgrade using GitHub API for releases
- Added optional flag `--hac2` to `map` command, default maps repository now uses a Mercury repository
- Updated error message handling at getting games path from registry
- Fixed file handle leak at copying files
- Expanded HTTP request timeout to 500 milliseconds
- Fixed stdout bug with `pack` command, current file being compressed now prints before starting compression
- Added common package folders creation in `pack` command
- Fixed optional parameters using `--template` on `pack` command
- Added optional `outputPath` to `packdiff` command

# 3.0.1
- Fixed memory leak at copying large files
- Fixed memory leak at unpacking large packages
- Added `--unsafe` flag, allows unsafe API requests
- Expanded HTTP request timeout
- Removed minizip dependency, migrated to minizip2 (a tester reported minizip2 causes crashes on Windows 7, needs testing)

# 3.0.0
- Updated repository API (deprecates old API, old Mercury versions are obsolete now)
- Added repository API versioning, it will improve support for future Mercury versions without
breaking API instantly for Mercury users on older versions
- Fixed an issue at giving multiple specific packages version to `install` command
- Added automatic `pack` command build based on folders path
- Added `packdiff` command, allows to create diff/update package between packages
- Removed `-f --forced` flag from `remove` command, renamed to `-i --index`
- Updated maps host for `map` command to search on HAC2 repository

# 2.0.0
- Added experimental `map` and `pack` commands
- Added support for Linux 64 bit builds
- Added `fetch` command to retrieve the latest package index available on the respository
- New manifest version `1.1.0` has been added, packages manifest now have a few different way to setup paths and an extra field for package category, check out the [Package Documentation](docs/PACKAGE.md) for more information.
- Removed `version` command, use `-v` to flag to get the Mercury version instead.
- Fixed issues with `install` and `update` commands at returning wrong data as the result of the command.

# 1.2.0
- Added `-t --template` flag to the `luabundle` command, this will create a template of a
bundle.json file in the current directory
```
mercury luabundle --template
```

# 1.1.0
- Added `latest` command to get the latest Mercury version available on GitHub
```
mercury latest
```

# 1.0.6
- Added support for 32 bit builds
- Added flag on installer to add Mecury folder to PATH
- Fixed a typo on the `about` command
- Fixed a problem with some installer entries
- Fixed an installer problem with a path for the desktop shortcut
- Added package version message on `install` and `update` commands at getting latest package available

# 1.0.5
- Added `--repository` flag to specify an alternative repository to download and update packages
```cmd
mercury install chimera --repository alternative.repo.com
```

# 1.0.4
- Fixed a bug with the `update` command where it was erasing the `files` property from the package index

# 1.0.3
- Fixed a bug with the `remove` command where `-r --recursive` flag was canceled by `-f --forced` flag

# 1.0.2
- Added semantic version checking at installing dependencies
- Added `-o --skipOptionals` flag to skip optional files installation at `insert` and `install` commands
```cmd
mercury install chimera -o
```
Command above will omit optional files like `chimera.ini` and similars.
- Added `-f --force` flag to perform a forced package removal with `remove` command, this will erase the package entry in the Mercury packages index
```cmd
mercury remove chimera -f
```
Command above will keep chimera files in place but remove Mercury awareness of the package.
- Added ansicolor to support text color printing in old Windows versions
- Changed how version number was printed with version command
- Fixed a problem for different bundle files in luabundle command
- Fixed a bug with the new Mercury packages standard
- Fixed a bug related to temporary files not being deleted
- Fixed a bug with packages that did not specify a specific package dependency version

# 1.0.1
- Fixed a bug with package dependencies version validation

# 1.0.0
- Initial release