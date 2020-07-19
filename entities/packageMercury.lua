------------------------------------------------------------------------------
-- Merc Package Entity
-- Author: Sledmine
-- Package entity for merc files
------------------------------------------------------------------------------
local json = require "cjson"

local class = require("middleclass")

---@class packageMercury
local packageMercury = class("packageMercury")

--- Parse and format version number strings
---@param version string
local function parseVersionNumber(version)
    return tonumber(version)
end

--- Replace all the environment related paths
---@param files
local function replaceEnvironmentPaths(files)
    local paths = {}
    for file, path in pairs(files) do
        local replacedPath = path:gsub("_HALOCE", _HALOCE):gsub( "_MYGAMES", _MYGAMES)
        paths[file] = replacedPath
    end
    return paths
end

--- Entity constructor
---@param jsonString string
function packageMercury:initialize(jsonString)
    local properties = json.decode(jsonString or "{}")
    ---@type string
    self.name = properties.name
    ---@type string
    self.label = properties.label
    ---@type string
    self.author = properties.author
    ---@type number
    self.version = parseVersionNumber(properties.version)
    ---@type table
    self.files = replaceEnvironmentPaths(properties.files)
end

function packageMercury:getProperties()
    return {
        name = self.name,
        label = self.label,
        author = self.author,
        version = self.version,
        files = self.files,
    }
end

return packageMercury

