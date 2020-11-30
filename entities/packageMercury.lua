------------------------------------------------------------------------------
-- Merc Package Entity
-- Sledmine
-- Package entity for merc files
------------------------------------------------------------------------------
local json = require "cjson"
local glue = require "glue"

local class = require "middleclass"

---@class packageMercury
local packageMercury = class "packageMercury"

--- Replace all the environment related paths
---@param files table
local function replaceEnvironmentPaths(files)
    if (files) then
        local paths = {}
        for file, path in pairs(files) do
            local replacedPath = path:gsub("_HALOCE", GamePath):gsub("_MYGAMES", MyGamesPath)
            paths[file] = replacedPath
        end
        return paths
    end
end

---@class packageMercuryJson
---@field name string
---@field label string
---@field author string
---@field version string
---@field internalVersion string
---@field files table
---@field dependencies string[]

--- Entity constructor
---@param jsonString packageMercuryJson
function packageMercury:initialize(jsonString)
    local properties = json.decode(jsonString)
    ---@type string
    self.name = properties.name
    ---@type string
    self.label = properties.label
    ---@type string
    self.author = properties.author
    ---@type number
    self.version = properties.version
    ---@type number
    self.internalVersion = properties.internalVersion
    ---@type table
    self.files = replaceEnvironmentPaths(properties.files)
    ---@type table
    self.updates = replaceEnvironmentPaths(properties.updates)
    ---@type string[]
    self.dependencies = properties.dependencies
end

--- Return the public/raw properties of the package
---@return packageMercuryJson
function packageMercury:getProperties()
    return {
        name = self.name,
        label = self.label,
        author = self.author,
        version = self.version,
        internalVersion = self.internalVersion,
        files = self.files,
        dependencies = self.dependencies
    }
end

return packageMercury

