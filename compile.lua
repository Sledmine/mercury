------------------------------------------------------------------------------
-- Compile script for Mercury
-- Sledmine
-- Script to simplify mercury bundle process
------------------------------------------------------------------------------
local glue = require "glue"
local fs = require "fs"
------------ Bundle configuration ------------

local v = require "semver"
local constants = require "Mercury.modules.constants"
local version = v(constants.mercuryVersion)

local staticLibs = {
    "socket_core",
    "mime_core",
    "luasec",
    "libssl",
    "libcrypto",
    "lfs",
    "cjson",
    "z",
    "minizip",
    "minizip2",
    "md5"
}

local modules = {
    -- Luapower modules
    "bundle.lua",
    "socket.lua",
    "socket/*.lua",
    "ltn12.lua",
    "mime.lua",
    "fs*.lua",
    "path.lua",
    "inspect.lua",
    "ssl.lua",
    "glue.lua",
    "minizip*.lua",
    -- Custom modules
    "registry.lua",
    "argparse.lua",
    "middleclass.lua",
    "semver.lua",
    "mime.lua",
    "md5.lua",
    "requests.lua",
    "pretty/*.lua",
    "pretty/json/*.lua",
    -- "luaunit.lua", -- Testing purposes only, keep it here for tracking, not needed for release
    -- Mercury modules
    "Mercury/actions/*.lua",
    "Mercury/modules/*.lua",
    "Mercury/config/*.lua",
    "Mercury/entities/*.lua",
    "Mercury/internal/*.lua",
    "Mercury/lib/*.lua",
    -- Main file
    -- For some reason this causes the program to fail if running on certain folders
    -- "Mercury/mercury.lua",
    -- So main file should on the root folder for compilation purposes
    "mercury.lua"
}

local windowsVersion = table.concat({version.major, version.minor, version.patch}, ".")

local versionInfo = {
    "FileVersion=" .. windowsVersion,
    "ProductVersion=" .. tostring(version),
    "FileDescription=Halo Custom Edition Package Manager",
    "ProductName=Mercury",
    "InternalName=Mercury"
}

local iconPath = "Mercury/assets/icons/mercury.ico"

-- This requires a certain link on the luapower root
local mainLua = "mercury"

local outputPath = "Mercury/bin/mercury.exe"

------------ Compilation process ------------
local luapowerArchs = {x64 = "64", x86 = "32"}

local function compileMercury(compilationArch)
    if (not fs.is("Mercury/bin")) then
        fs.mkdir("Mercury/bin")
    end
    local bundleCmdTemplate =
        "set LUAJIT_PATH=bin/mingw%s/luajit.exe && mgit bundle %s -a \"%s\" -m \"%s\" -M \"%s\" -i \"%s\" -fv %s -vi \"%s\" -o \"%s\" -av %s"

    -- No x86 flag
    local bundleBashTemplate =
        "export LUAJIT_PATH=bin/linux%s/luajit && ./mgit bundle -a \"%s\" -m \"%s\" -M \"%s\" -i \"%s\" -fv %s -vi \"%s\" -o \"%s\" -av %s"

    if (jit.os == "Linux") then
        os.execute([[rm -rf bundle-tmp/]])
        -- Fix lib names on Linux
        for _, libname in pairs(staticLibs) do
            staticLibs[_] = libname:gsub("lib", "")
        end
        local bundleBash = string.format(bundleBashTemplate, luapowerArchs[compilationArch],
                                         table.concat(staticLibs, " "), table.concat(modules, " "),
                                         mainLua, iconPath, version, table.concat(versionInfo, ";"),
                                         outputPath:gsub(".exe", ""), tostring(version))
        print(bundleBash)
        return os.execute(bundleBash)
    else
        os.execute([[rmdir bundle-tmp]])
        -- Multi arch compilation using diferrent path definitions for x86 and x64 builds
        local x86Flag = ""
        if (compilationArch == "x86") then
            x86Flag = "-m32"
            bundleCmdTemplate = [[set PATH=C:\mingw32;%PATH% && ]]
        else
            bundleCmdTemplate = [[set PATH=C:\mingw64;%PATH% && ]]
        end

        local bundleCmd = string.format(bundleCmdTemplate, luapowerArchs[compilationArch], x86Flag,
                                        table.concat(staticLibs, " "), table.concat(modules, " "),
                                        mainLua, iconPath, windowsVersion .. ".0",
                                        table.concat(versionInfo, ";"), outputPath,
                                        tostring(version))
        print(bundleCmd)
        return os.execute(bundleCmd)
    end

end

local function compileInstaller(compilationArch)
    if (jit.os == "Windows") then
        ---@type string
        local installerTemplate = glue.readfile("mercury/installerTemplate.iss", "t")
        if (installerTemplate) then
            installerTemplate = installerTemplate:gsub("$VNUMBER", tostring(version))
            installerTemplate = installerTemplate:gsub("$OSTARGET", "windows")
            local arch64 = compilationArch
            local arch = compilationArch
            if (compilationArch == "x86") then
                arch64 = ""
            else
                -- Enable optional binary sources for x64
                installerTemplate = installerTemplate:gsub(";Source", "Source")
            end
            installerTemplate = installerTemplate:gsub("$ARCH64", arch64)
            installerTemplate = installerTemplate:gsub("$ARCH", arch)
            glue.writefile("mercury\\installer.iss", installerTemplate, "t")
            local installerCmd = "cd mercury\\ & ISCC installer.iss && cd .."
            print(installerCmd .. "\n")
            return os.execute(installerCmd)
        end
    else
        print("Installer compilation for Linux is not supported yet, aiming for a .deb package!")
    end
end

if (jit.os == "Windows") then
    compileMercury("x86")
    compileInstaller("x86")
end
compileMercury("x64")
compileInstaller("x64")
