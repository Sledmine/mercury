<html>
    <p align="center">
        <img width="300px" src="assets/images/mercury.png"/>
    </p>
    <h1 align="center">Mercury</h1>
    <p align="center">
       Halo Custom Edition Package Manager
    </p>
</html>

# Mercury v1.3.0-beta

## What is Mercury?

Is a console program that gives you some features such as downloading an installing tools, addons, mods and maps for your Halo Custom Edition game, everything you need in one place being downloaded in the pure developer style, basically a software package manager oriented to a game with mods.

![Mercury GIF](https://i.imgur.com/kzVgOu3.gif)

## What is the purpose of Mercury?

- Get access into our package repository and download the latest or the oldest version of your favorite packages.
- Manage your favorite mods or addons perform different actions for them such as, install, update, remove, etc.

# Installing Mercury

To download and use Mercury in your computer you have to download Windows binaries from the [releases](https://github.com/Sledmine/Mercury/releases) tab or from the official site, there is an installer for easier setup.

# Documentation

We are working on some documentation for Mercury, stay tuned, some markdowns will be hosted here as
well:

- [Packages](docs/PACKAGE.md)
- [Lua Bundler](docs/LUABUNDLER.md)

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

# Development Environment

If you want to modify and verify code in this repository you will have a couple of tools to
test everything in your local environment, some unit testing is being added continuously.

## Run with LuaJIT
Luapower follows a structure where everything must be inside the root folder to work, by just making a Symlink of your cloned respository into the Luapower folder you will be able to run, you can clone your repository directly in the Luapower folder but we would like to recommend you to create a symlink.

After that you can just use this command in the luapower folder to run it:
```cmd
luajit mercury\mercury.lua
```

## Mocking Vulcano API and Server

You can run a mock of a Vulcano API with a testing repository server using [easymock](https://github.com/CyberAgent/node-easymock) and the commands below:
```cmd
cd tests\server
easymock
```

# FAQ

## Luapower is a cross platform framework, why is this only working for Windows?

Halo Custom Edition only works in a Windows environment by native running or via emulation using
Wine for example, so creating a package manager for Linux would be a little bit weird if the game
itself only runs on Windows, but after some work migration a Linux build would be possible in the future.

## I use a portable version of Halo Custom Edition, can I use Mercury?

Not right now, Mercury aims to bring the most easy way to install mods into Halo Custom Edition
without the needs of setting and defining paths or values into any file or directory, a support for
those portable installations will come later.

As a "fix" you can try to register your portable installation path into the Windows registry in
order to allow Mercury find the path of your Halo Custom Edition installation.