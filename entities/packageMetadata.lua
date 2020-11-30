------------------------------------------------------------------------------
-- Package Metadata Entity
-- Author: Sledmine
-- Entity to reflect response from package librarian fetch
------------------------------------------------------------------------------
local json = require "cjson"

local class = require "middleclass"

---@class packageMetadata
local packageMetadata = class "packageMetadata"

--- Entity constructor
---@param jsonString string
function packageMetadata:initialize(jsonString)
    local properties = json.decode(jsonString)
    ---@type string
    self.label = properties.label
    ---@type string
    self.name = properties.name
    ---@type string
    self.author = properties.author
    ---@type number
    self.version = properties.version
    ---@type string
    self.internalVersion = properties.internalVersion
    ---@type string
    self.category = properties.category
    ---@type string[]
    self.conflicts = properties.conflicts
    ---@type string
    self.mirrors = properties.mirrors
    ---@type number
    self.nextVersion = properties.nextVersion
    --[[@type table
    self.dependencies = properties.dependencies]]
end

return packageMetadata

