
# Mercury 3.0 - Development Branch ![MercuryLogo](https://i.imgur.com/4BoDBJ9.png)

-- THIS IS NOT AN STABLE BRANCH USE MASTER BRANCH INSTEAD --

### What is Mercury?
Is a console program that allows you to download all kind of tools, addons, mods, extensions and install it directly into your game, everything you need in one place being downloaded in the pure Linux style, basically a package manager for Halo Custom Edition.

### What i can do with it?
 - Get access into our package repository and download the latest or the oldest version of your favorite packages.
 - Upgrade to a newer version of your favorite addon or simple uninstall it.
 - Manually install .merc packages by command line or by clicking on it.
 - Make different Halo Custom Edition versions in just seconds "mitosising" an existing version of the game.
 - Define parameters for mitosised versions of the game and launch their respective executables.

### Installing Mercury
To download and use Mercury in your computer you have to download Windows binaries usually located in the "bin" folder and run Mercury.exe in your favorite command prompt.

### Using Mercury
You can run Mercury in any kind of terminal, calling the Mercury executable will show available commands and their respective description, in anycase here is a complete documentation to use Mercury.

Every parameter inside **[ ]** is an optional parameter.

The sintaxis for every command is being triggered calling "mercury" before every command, example:
```
mercury <command> <parameters> [<sub-parameters>]
```
Using a real command example:
```
mercury install chimera
```
In some commands you can pass sub params to cause little modifications in the behaviour of the command:
```
mercury remove opensauce -eb
```

### List of available commands

#### install
This command can download and install any package from our repository, you can request any version of the desired package, use "-" after the package name to specify the version you want to request, if the version is not given, the most recent version will be downloaded.

Request specific version:
```
mercury install luablam-2.0
```
Request most recent version:
```
mercury install luablam
```

### Building Mercury
To build Mercury using this repo you need to install couple of things to being able to create a Windows binary executable:
 
- LuaPower distribution
- LuaSec
- Lua ANSI Colors
- OpenSSL
- MSYS
- MinGW
