<html>
    <p align="center">
        <img width="200px" src="img/mercury-logo-clean.png"/>
    </p>
    <h1 align="center">Mercury</h1>
    <p align="center">
       Halo Custom Edition Package Manager
    </p>
</html>

# Introduction

Mercury is a CLI program that offers cool features for Halo Custom Edition such as downloading and installing addons, maps and mods in general for your Halo Custom Edition game, everything you need stored in a repository, a unique place.

![Mercury GIF](img/demo.gif)

# What is the purpose of Mercury?

Mercury attempts to solve the problem of descentralized content available out there for the game, it tries to bring a way to simplify the deployment and releasing issues that a modder of the game can encounter at trying to release a mod for the community, we can say Mercury "simplifies" the installation and distribution process, as some users are not friends of a command line but this way is better than trying to explain hundreds of users how to install everything on a mod manually.

In short terms what it offers you:
- Get access into our package repository and download the latest or the specified version of your favorite packages/mods by using simple commands.
- Manage your favorite mods or addons, performing different actions on them, remove, update, etc

We tried to minimize the impact of how complex a package manager really is, as the game is actually really hard to keep stable by installing different mods that are not compatible with each other.

Mercury follows this politic where the final "build" of your game is based on the packages required by the mods you are installing, in theory the mod author should be caring about the dependencies of the mod being published so you will end with a stable experience with multiple mods installed, but at the end you have responsability to decide what packages you want
to keep installed in order to install one package or another.

# Installing Mercury

To download and use Mercury in your computer you have to download Windows binaries from the [releases](https://github.com/Sledmine/Mercury/releases) tab or from the official site, there is an installer for easier setup.

# Documentation

We are working on some documentation for Mercury, stay tuned, some markdowns will be hosted here as
well:

- [Lua Bundler](docs/LUA-BUNDLER.md)
- [Mercury Packages](docs/PACKAGES.md)

# Contribute to Mercury

Feel free to fork and ask for pull requests to this repository, we are looking for an interface application for Mercury so any frontend developer is welcome!

# Building Mercury

Mercury uses [luapower](https://luapower.com) as the base of the project, it is needed to get the required amount of modules and files to bundle/compile the code in this repository.

Mingw-w64 is required to compile the project, at least for Windows builds.

- [Mingw-w64](http://mingw-w64.org/doku.php)

There are some extra modules are required for the project that are not in the luapower distribution, they are already included on my luapower fork called
[luapower-all-x86-x64](https://github.com/Sledmine/luapower-all-x86-x64):


**NOTE:** Use my luapower fork to bundle this project always, it has all the changes needed by 
Mercury to compile.

After setting up all the requirements be sure to have permission to create symlinks on your main
drive as the compilation script requires them right now to acomplish multi arch compilation
(better ideas about how to deal the compilation proccess are welcome).

Using ths command should be enough to compile this repository (assuming the repository folder is
inside the luapower folder as well):
```cmd
cd luapower-all-x86-x64
luajit mercury/compile.lua
```

**NOTE:** I'll try to create a docker container for this, it should simplify compilation process and
provide a way to automatically build this on the cloud.

# Setting up a development environment

If you want to modify and test code in this repository you will have a couple of tools to
test everything in your local environment, some unit testing is being added continuously.

## Run Mercury from source
Luapower follows a structure where everything must be inside the root folder to work, by just making
a Symlink of your cloned respository into the Luapower folder you will be able to run, you can
clone your repository directly in the Luapower folder but we would like to recommend you to create a
symlink.

After that you can just use this command in the luapower folder to run it:
```cmd
./luajit mercury/mercury.lua
```

## Mocking Vulcano API and Server

Vulcano is the API that Mercury consumes, as Vulcano is a really simple HTTP JSON Server we don't
have documentation about it, but if you got this far to start working on Mercury it would be a really simple API to test and consume based on the Mercury code.

You can run a mock of Vulcano API including static package repository using
[easymock](https://github.com/CyberAgent/node-easymock) and the commands below:
```cmd
cd tests/server
easymock
```

# FAQ

## I use a portable version of Halo Custom Edition, can I use Mercury?

Yes, you can by setting the path in the Mercury configuration or setting an environment variable.
To con figure Mercury use this command for example:

```
mercury config game.path "C:\Halo CE"
```

Or by setting an environment variable:
```
set HALO_CE_PATH=C:\Halo CE
```
**NOTE:** You can do this on Linux too!