------------------------------------------------------------------------------
-- Merc Package Entity
-- Sledmine
-- Package entity for merc files
------------------------------------------------------------------------------
local json = require "cjson"
local glue = require "glue"

local class = require "middleclass"

local packageMercury = class "packageMercury"

---@class mercDependencies
---@field label string
---@field version string

---@class mercFiles
---@field path string
---@field type string
---@field outputPath string

---@class mercUpdates
---@field path string
---@field diffPath string
---@field type string
---@field outputPath string

---@class packageMercury
---@field name string
---@field label string
---@field description string
---@field author string
---@field version string
---@field targetVersion string
---@field internalVersion string
---@field manifestVersion string
---@field files mercFiles[]
---@field updates mercUpdates[]
---@field dependencies mercDependencies[]

--- Replace all the environment related paths
---@param files mercFiles[]
local function replacePathVariables(files)
    if (files and #files > 0) then
        local pathVariables = {
            ["$haloce"] = GamePath,
            ["$mygames"] = MyGamesPath
        }
        local paths
        for fileIndex, file in pairs(files) do
            if (not paths) then
                paths = {}
            end
            local outputPath = file.outputPath
            for variable, value in pairs(pathVariables) do
                outputPath = outputPath:gsub(variable, value)
            end
            file.outputPath = outputPath
            paths[fileIndex] = file
        end
        return paths
    end
    return nil
end

--- Entity constructor
---@param jsonString string
function packageMercury:initialize(jsonString)
    local properties = json.decode(jsonString)
    ---@type string
    self.label = properties.label
    
    ---@type string
    self.name = properties.name

    ---@type string
    self.description = properties.description

    ---@type string
    self.author = properties.author

    ---@type string
    self.version = properties.version

    ---@type string
    self.targetVersion = properties.targetVersion

    ---@type string
    self.internalVersion = properties.internalVersion

    ---@type string
    self.manifestVersion = properties.manifestVersion

    ---@type mercFiles[]
    self.files = replacePathVariables(properties.files)

    ---@type mercUpdates[]
    self.updates = replacePathVariables(properties.updates)

    ---@type mercDependencies[]
    self.dependencies = properties.dependencies
end

--- Return the public/raw properties of the package
---@return packageMercury
function packageMercury:getProperties()
    return {
        name = self.name,
        label = self.label,
        description = self.description,
        author = self.author,
        version = self.version,
        internalVersion = self.internalVersion,
        manifestVersion = self.manifestVersion,
        files = self.files,
        dependencies = self.dependencies
    }
end

return packageMercury

