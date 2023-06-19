------------------------------------------------------------------------------
-- Merc Package Entity
-- Sledmine
-- Package entity for merc files
------------------------------------------------------------------------------
local json = require "cjson"
local glue = require "glue"
local paths = config.paths()

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
---@field category string
---@field files mercFiles[]
---@field updates mercUpdates[]
---@field dependencies mercDependencies[]

--- Replace and normalize file paths
---@param files mercFiles[]
local function normalizePaths(files, manifestVersion)
    if (files and #files > 0) then
        local pathVariables = {
            ["$haloce"] = paths.gamePath,
            ["game-root"] = paths.gamePath,
            ["$mygames"] = paths.myGamesPath,
            ["my-games-data-path"] = paths.myGamesPath,
            ["lua-global"] = paths.luaScriptsGlobal,
            ["lua-map"] = paths.luaScriptsMap,
            ["lua-sapp"] = paths.luaScriptsSAPP,
            ["lua-data-global"] = paths.luaDataGlobal,
            ["lua-data-map"] = paths.luaDataMap,
            ["game-maps"] = paths.gameMaps,
            ["game-mods"] = paths.gameDLLMods,
        }
        local paths
        for fileIndex, file in pairs(files) do
            if (not paths) then
                paths = {}
            end
            local normalizedOutputPath = file.outputPath
            for variable, value in pairs(pathVariables) do
                local plainVariable = variable:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]','%%%1')
                normalizedOutputPath = normalizedOutputPath:gsub(plainVariable, value)
            end
            file.path = gpath(file.path)
            if (manifestVersion == "1.0") then
                file.outputPath = gpath(normalizedOutputPath .. file.path)
            elseif (manifestVersion == "1.1.0") then
                file.outputPath = gpath(normalizedOutputPath)
            else
                cprint("Error, uknown manifest version (" .. tostring(manifestVersion) .. ")")
                error("Error at trying to read manifest.json version", 2)
            end
            paths[fileIndex] = file
        end
        return paths
    end
    return nil
end

--- Entity constructor
---@param jsonStringOrTable string | packageMercury
function packageMercury:initialize(jsonStringOrTable)
    local properties
    if (type(jsonStringOrTable) == "string") then
        properties = json.decode(jsonStringOrTable)
    elseif (type(jsonStringOrTable) == "table") then
        properties = jsonStringOrTable
    else
        error("Specified package constructor parameter is not valid", 2)
    end
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

    ---@type string
    self.category = properties.category

    ---@type mercFiles[]
    self.files = normalizePaths(properties.files, self.manifestVersion)

    ---@type mercUpdates[]
    self.updates = normalizePaths(properties.updates, self.manifestVersion)

    ---@type mercDependencies[]
    self.dependencies = properties.dependencies

    -- Update manifest
    if (self.manifestVersion == "1.0") then
        self.manifestVersion = "1.1.0"
    end
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
        category = self.category,
        files = self.files,
        dependencies = self.dependencies
    }
end

function packageMercury:getExpectedVersion()
    return "1.1.0"
end

return packageMercury

