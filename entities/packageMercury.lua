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

--- Parse and format version number strings
---@param version string
local function parseVersionNumber(version)
    --[[
        Mercury is expecting to handle versions that look like this
        2.4.3.1

        So when parsed they need to be like this:

        2431

        To provide a simple version aritmetic comparasion with

        internalVersion > 2431
    ]]
    local versionDetails = glue.string.split(version, ".")
    if (#versionDetails > 1) then
        local parsedVersion = ""
        for versionLevel in each(versionDetails) do
            parsedVersion = parsedVersion .. versionLevel:gsub("[%a%p%c%s]", "")
        end
        return tonumber(parsedVersion)
    end
    return tonumber(version)
end

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
---@field internalVersion number
---@field files table
---@field dependencies table

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
    self.internalVersion = parseVersionNumber(properties.version)
    ---@type table
    self.files = replaceEnvironmentPaths(properties.files)
    ---@type table
    self.updates = replaceEnvironmentPaths(properties.updates)
    ---@type table
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

