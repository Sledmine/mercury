------------------------------------------------------------------------------
-- Compile script for Mercury
-- Sledmine
-- Script to simplify mercury bundle process
------------------------------------------------------------------------------
local version = "1.0.0"

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
    -- Project libs
    "mercury.lua",
    "registry.lua",
    "argparse.lua",
    "middleclass.lua",
    -- Luaunit is just for testing purposes, not required for release
    -- Anyway, keep it here for tracking...
    -- "luaunit.lua",
    "Mercury/actions/*.lua",
    "Mercury/modules/*.lua",
    "Mercury/config/*.lua",
    "Mercury/entities/*.lua",
    "Mercury/internal/*.lua",
    "Mercury/lib/*.lua"
}

local versionInfo = {
    "FileVersion=" .. version,
    "ProductVersion=" .. version,
    "FileDescription=Halo CE Package Manager",
    "ProductName=Mercury",
    "InternalName=Mercury"
}

local iconPath = "Mercury/assets/icons/mercury.ico"

local mainLua = "mercury"

local outputPath = "Mercury\\bin\\mercury.exe"

local bundleCmd = "mgit bundle -a '%s' -m '%s' -M '%s' -i '%s' -fv %s -vi '%s' -o '%s' -av " .. version

local bundleBuild = string.format(bundleCmd, table.concat(staticLibs, " "),
                                  table.concat(modules, " "), mainLua, iconPath, version,
                                  table.concat(versionInfo, ";"), outputPath)
print(bundleBuild)
os.execute(bundleBuild)
