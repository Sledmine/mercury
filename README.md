# Mercury - Halo Custom Edition Package Manager

## What is Mercury?

Is a console program that gives you some features such as downloading an installing tools, addons, mods and maps for your Halo Custom Edition game, everything you need in one place being downloaded in the pure Linux style, basically a software package manager oriented to a game with mods.

![Mercury GIF](https://i.imgur.com/0Brri7L.gif)

## What is the purpose of Mercury?

- Get access into our package repository and download the latest or the oldest version of your favorite packages.
- Manage your favorite mods or addons, install them, upgrade them,  etc, all from the Mercury repository.
- Create different Halo Custom Edition versions in just seconds "mitosising" an existing version of the game.

## Installing Mercury

To download and use Mercury in your computer you have to download Windows binaries from the [releases](https://github.com/Sledmine/Mercury/releases) tab or from the official site.
**AN INSTALLER WILL BE AVAILABLE SOON!**

# Contribute to Mercury

Feel free to fork and ask for pull requests to this repository also we are looking for an interface application for Mercury so any frontend developer is welcome! :)

# Building Mercury

Mercury uses [luapower](https://luapower.com) as the base of the project, this is needed to get the required amount of libraries and files to bundle/compile the code in this repository.
**There are known some problems with precompiled libs, try to compile your own ssl libs from LuaPower if you are having problems at bundle time.**

Some libraries and tools are needed too:

- [MSYS](http://www.mingw.org/wiki/MSYS)
- [MinGW](http://mingw-w64.org/doku.php)

These libraries are already included in the repository but you can check their own repository if needed:

- [argparse](https://github.com/luarocks/argparse)
- [registry](https://github.com/Tieske/registry)
- [middleclass](https://github.com/kikito/middleclass)
- [luaunit](https://github.com/bluebird75/luaunit)

# Development Environment

If you want to modify and verify code in this repository you will have a couple of tools to
test everything in your local environment, some unit testing is being added continuously.

## Run with LuaJIT
Luapower follows a structure where everything must be inside the root folder to work, by just making a Symlink of your cloned respository into the Luapower folder you will be able to run, you can clone your repository directly in the Luapower folder but I would recommend you to create a Symlink.

After that you can just use this command in the luapower folder in order to run it:
```
luajit mercury\mercury.lua
```

## Mocking Librarian Server

You can run a mock of a librarian server using [json-server](https://github.com/typicode/json-server) and the command below:
```
mercury\server.cmd
```

# FAQ
- **Luapower is a cross platform framework, why is this only working for Windows?**

Halo Custom Edition only works in a Windows environment by native running or via emulation using Wine for example, so creating a package manager for Linux would be a little bit weird if the game itself only runs on Windows.
