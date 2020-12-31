------------------------------------------------------------------------------
-- Compile script for Mercury
-- Sledmine
-- Script to simplify mercury bundle process
------------------------------------------------------------------------------
local glue = require "glue"

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
    -- Project libs
    "mercury.lua",
    "registry.lua",
    "argparse.lua",
    "middleclass.lua",
    "semver.lua",
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

local bundleCmdLine = "mgit bundle -a '%s' -m '%s' -M '%s' -i '%s' -fv %s -vi '%s' -o '%s' -av " ..
                          version

local bundleCmd = string.format(bundleCmdLine, table.concat(staticLibs, " "),
                                table.concat(modules, " "), mainLua, iconPath, version .. ".0",
                                table.concat(versionInfo, ";"), outputPath)
print(bundleCmd)
os.execute(bundleCmd)

---@type string
local installerTemplate = glue.readfile("mercury\\installerTemplate.iss", "t")
if (installerTemplate) then
    installerTemplate = installerTemplate:gsub("$VNUMBER", version)
    glue.writefile("mercury\\installer.iss", installerTemplate, "t")
    local installerCmd = "cd mercury\\ & ISCC installer.iss && cd .."
    print(installerCmd)
    os.execute(installerCmd)
end
