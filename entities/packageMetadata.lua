------------------------------------------------------------------------------
-- Package Metadata Entity
-- Author: Sledmine
-- Entity to reflect response from package librarian fetch
------------------------------------------------------------------------------
local json = require "cjson"

local class = require("middleclass")

---@class packageMetadata
local packageMetadata = class("packageMetadata")

--- Entity constructor
---@param jsonString string
function packageMetadata:initialize(jsonString)
    local properties = json.decode(jsonString or "{}")
    -- Some times certain api versions can return an array as the package, like the json-server
    if (properties[1]) then
        properties = properties[1]
    end
    ---@type string
    self.name = properties.name
    ---@type string
    self.label = properties.label
    ---@type string
    self.author = properties.author
    ---@type number
    -- TO DO: Check if this valus is required as number
    self.version = properties.version
    ---@type string
    self.url = properties.url
end

return packageMetadata

