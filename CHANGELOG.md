# Changelog

# 2.0.0
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