------------------------------------------------------------------------------
-- Merc Package Entity
-- Sledmine
-- Package entity for merc files
------------------------------------------------------------------------------
local json = require "cjson"
local paths = config.paths()

local class = require "middleclass"

local packageMercury = class "packageMercury"

---@class mercDependencies
---@field label string
---@field version? string
---@field forced? boolean

---@alias mercDependenciesString string

---@class mercFiles
---@field path string
---@field type string
---@field outputPath string

---@class mercUpdates
---@field path string
---@field diffPath string
---@field type string
---@field outputPath string

---@class mercDeletes
---@field path string
---@field required? boolean

---@class mercMoves
---@field fromPath string
---@field toPath string
---@field required? boolean

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
---@field deletes mercDeletes[]
---@field moves mercMoves[]
---@field removes mercDependencies[] | mercDependenciesString[]

local invalidCharacters = {":", "*", "?", "<", ">", "|", ";", "="}

--- Check if a path is valid
---@param path string
---@return boolean
local function validatePath(path)
    for _, character in pairs(invalidCharacters) do
        if path:includes(character) then
            return false
        end
    end
    return true
end

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
    ["balltze-plugins"] = paths.balltzePlugins
}

--- Replace path variables
---@param path string
local function replacePathVariables(path)
    for variable, value in pairs(pathVariables) do
        path = path:replace(variable, value)
    end
    return path
end

--- Update manifest version
---@param manifestVersion string
---@return string
local function updateManifestVersion(manifestVersion)
    if manifestVersion == "1.0" then
        return "1.1.0"
    end
    return manifestVersion
end

--- Replace and normalize file paths
---@param files mercFiles[]
---@param manifestVersion string
---@return mercFiles[]
local function normalizeMercFiles(files, manifestVersion)
    return table.map(files, function(file)
        if not validatePath(file.path) and not validatePath(file.outputPath) then
            error("Invalid path specified in package file: " .. tostring(file.path))
        end

        file.path = gpath(file.path)
        file.outputPath = replacePathVariables(gpath(file.outputPath))

        -- Upgrade manifest version properties to latest
        if manifestVersion == "1.0" then
            file.outputPath = gpath(file.outputPath .. file.path)
            -- TODO Add validation for upcoming manifest versions, not just hardcoded ones
        elseif manifestVersion == "1.1.0" or manifestVersion == "2.0.0" then
            file.outputPath = gpath(file.outputPath)
        else
            error("Error uknown manifest package version (" .. tostring(manifestVersion) .. ")")
        end

        return file
    end)
end

--- Normalize package deletes
---@param deletes mercDeletes[]
---@return mercDeletes[]
local function normalizeMercDeletes(deletes)
    return table.map(deletes, function(delete)
        if not validatePath(delete.path) then
            error("Invalid path specified in package delete: " .. tostring(delete.path))
        end

        delete.path = replacePathVariables(gpath(delete.path))

        return delete
    end)
end

--- Normalize package moves
---@param moves mercMoves[]
---@return mercMoves[]
local function normalizeMercMoves(moves)
    return table.map(moves, function(move)
        if not validatePath(move.fromPath) and not validatePath(move.toPath) then
            error("Invalid path specified in package move: " .. tostring(move.fromPath))
        end

        move.fromPath = replacePathVariables(gpath(move.fromPath))
        move.toPath = replacePathVariables(gpath(move.toPath))
        move.required = move.required or true

        return move
    end)
end

--- Entity constructor
---@param data string | packageMercury
function packageMercury:initialize(data)
    ---@type packageMercury
    local properties
    if type(data) == "string" then
        properties = json.decode(data)
    elseif type(data) == "table" then
        properties = data
    else
        error("Specified package constructor parameter is not valid")
    end
    self.label = properties.label
    self.name = properties.name
    self.description = properties.description
    self.author = properties.author
    self.version = properties.version
    self.targetVersion = properties.targetVersion
    self.internalVersion = properties.internalVersion
    self.manifestVersion = properties.manifestVersion
    self.category = properties.category
    if properties.files then
        self.files = normalizeMercFiles(properties.files, self.manifestVersion)
    end
    if properties.updates then
        self.updates = normalizeMercFiles(properties.updates, self.manifestVersion) --[[@as mercUpdates[]]
    end
    if properties.deletes then
        self.deletes = normalizeMercDeletes(properties.deletes)
    end
    if properties.moves then
        self.moves = normalizeMercMoves(properties.moves)
    end
    self.dependencies = properties.dependencies
    self.removes = properties.removes
    -- Update manifest
    self.manifestVersion = updateManifestVersion(self.manifestVersion)
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
    return "2.0.0"
end

return packageMercury
