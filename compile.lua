------------------------------------------------------------------------------
-- Compile script for Mercury
-- Sledmine
-- Script to simplify mercury bundle process
------------------------------------------------------------------------------
local glue = require "glue"
local fs = require "fs"
------------ Bundle configuration ------------

-- Provide path to project modules
package.path = package.path .. ";.\\Mercury\\?.lua"

local constants = require "modules.constants"
local version = constants.mercuryVersion

local staticLibs = {
    "socket_core",
    "mime_core",
    "ssl",
    "libssl",
    "libcrypto",
    "lfs",
    "cjson",
    "z",
    "minizip"
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
    -- "luaunit.lua", -- Testing purposes only, keep it here for tracking, not needed for release
    -- Mercury modules
    "Mercury/actions/*.lua",
    "Mercury/modules/*.lua",
    "Mercury/config/*.lua",
    "Mercury/entities/*.lua",
    "Mercury/internal/*.lua",
    "Mercury/lib/*.lua",
    -- Main file
    -- For some reaseon this causes the program to fail if running on certain folders
    -- "Mercury/mercury.lua",
    "mercury.lua"
}

local versionInfo = {
    "FileVersion=" .. version,
    "ProductVersion=" .. version,
    "FileDescription=Halo CE Package Manager",
    "ProductName=Mercury",
    "InternalName=Mercury"
}

local iconPath = "Mercury/assets/icons/mercury.ico"

-- This requires a certain link on the luapower root
local mainLua = "mercury"

local outputPath = "Mercury\\bin\\mercury.exe"

------------ Compilation process ------------
local luapowerArchs = {x64 = "64", x86 = "32"}

local function compileMercury(compilationArch)
    local removeCache = [[rm -rf .bundle-tmp\]]
    os.execute(removeCache)

    if (fs.is([[C:\mingw\]])) then
        local removeSmlink = [[rmdir C:\mingw\]]
        os.execute(removeSmlink)
    end

    local removeMercuryBin = [[rm -rf mercury\bin\mercury.exe]]
    os.execute(removeMercuryBin)

    local makeMingwSmlink = [[mklink /d C:\mingw\ C:\%s\]]
    local x86Flag = ""
    if (compilationArch == "x86") then
        x86Flag = "-m32"
        os.execute(makeMingwSmlink:format("mingw32"))
    else
        os.execute(makeMingwSmlink:format("mingw64"))
    end

    local bundleCmdTemplate =
        "set LUAJIT_PATH=bin/mingw%s/luajit.exe && mgit bundle %s -a \"%s\" -m \"%s\" -M \"%s\" -i \"%s\" -fv %s -vi \"%s\" -o \"%s\" -av %s"

    local bundleCmd = string.format(bundleCmdTemplate, luapowerArchs[compilationArch],x86Flag, table.concat(staticLibs, " "),
                                    table.concat(modules, " "), mainLua, iconPath,
                                    version .. ".0", table.concat(versionInfo, ";"),
                                    outputPath, version)
    print(bundleCmd)
    return os.execute(bundleCmd)
end

local function compileInstaller(compilationArch)
    ---@type string
    local installerTemplate = glue.readfile("mercury\\installerTemplate.iss", "t")
    if (installerTemplate) then
        installerTemplate = installerTemplate:gsub("$VNUMBER", version)
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
        os.execute(installerCmd)
    end
end

compileMercury("x86")
compileInstaller("x86")
compileMercury("x64")
compileInstaller("x64")
