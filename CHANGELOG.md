# Changelog

# 1.0.6
- Support for 32 bit builds
- Added flag on installer to add Mecury folder to PATH
- Fixed a typo on the about command
- Fixed a problem with some installer entries
- Fixed an installer problem with a path for the desktop shortcut

# 1.0.5
- Added a flag to specify an alternative repository to download and update packages

# 1.0.4
- Fixed a bug with the update command where it was erasing the "files" property from the package index

# 1.0.3
- Fixed a bug with remove where recursive flag was canceled by forced flag

# 1.0.2
- Added semantic version checking at installing dependencies
- Fixed a bug with packages that did not specify a specific package dependency version
- Added flag to skip optional files at insert and install commands
- Added flag to perform a forced remove with remove command
- Changed how version number was printed with version command
- Fixed a problem for different bundle files in luabundle command
- Fixed a bug with the new Mercury packages standard
- Added ansicolor to support text color printing in old Windows versions
- Fixed a bug related to temporary files not being deleted

# 1.0.1
- Fixed a bug with package dependencies version validation

# 1.0.0
- Initial release