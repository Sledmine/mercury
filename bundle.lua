------------------------------------------------------------------------------
-- Bundle script for Mercury
-- Author: Sledmine
-- Script to simplify mercury bundle process
------------------------------------------------------------------------------
local staticLibs = {
    "socket_core",
    "mime_core",
    "ssl",
    "libssl",
    "libcrypto",
    "lfs",
    "cjson",
    "z",
    "minizip",
}

local modules = {
    -- Luapower libs
    "socket.lua",
    "socket/*.lua",
    "ltn12.lua",
    "mime.lua",
    "fs*.lua",
    "path.lua",
    "inspect.lua",
    "ssl.lua",
    "glue.lua",
    -- Project libs
    "mercury.lua",
    "registry.lua",
    "argparse.lua",
    "middleclass.lua",
    "Mercury/actions/*.lua",
    "Mercury/config/*.lua",
    "Mercury/entities/*.lua",
    "Mercury/internal/*.lua",
    "Mercury/lib/*.lua",
}

local versionInfo = {
    "FileVersion=3.0",
    "ProductVersion=3.0",
    "FileDescription=Halo CE Package Manager",
    "ProductName=Mercury",
    "InternalName=Mercury",
}

local iconPath = "Mercury/assets/icons/mercury.ico"

local mainLua = "mercury"

local outputPath = "Mercury\\mercury.exe"

local bundleLine = "mgit bundle -a '%s' -m '%s' -M '%s' -i '%s' -vi '%s' -o '%s'"

local bundleBuild = string.format(bundleLine, table.concat(staticLibs, " "),
                                  table.concat(modules, " "), mainLua, iconPath,
                                  table.concat(versionInfo, ";"), outputPath)
print(bundleBuild)
os.execute(bundleBuild)
