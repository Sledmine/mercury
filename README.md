
# Mercury - Halo Custom Edition Package Manager

### What is Mercury?
Is a console program that allows you to download all kind of tools, addons, mods, extensions and install it directly into your game, everything you need in one place being downloaded in the pure Linux style, basically a package manager for Halo Custom Edition.

### What is the purpose of Mercury?
 - Get access into our package repository and download the latest or the oldest version of your favorite packages.
 - Manage your favorite mods or addons, install from remote repository, upgrade them, etc.
 - Make different Halo Custom Edition versions in just seconds "mitosising" an existing version of the game.

### Installing Mercury
To download and use Mercury in your computer you have to download Windows binaries from the releases tab or from the official site.

### Building Mercury
Mercury uses [LuaPower](https://luapower.com) as the base of the project, this is needed to get the required amount of libraries and files to bundle/compile the code in this repository.

Some libraries and tools are needed too:
- [LuaSec](https://github.com/brunoos/luasec)
- [MSYS](http://www.mingw.org/wiki/MSYS)
- [MinGW](http://mingw-w64.org/doku.php)

These libraries are already included in the repository but you can check their own repository if needed:
- [argparse](https://github.com/luarocks/argparse)
- [registry](https://github.com/Tieske/registry)