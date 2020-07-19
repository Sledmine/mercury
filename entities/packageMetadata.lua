------------------------------------------------------------------------------
-- Package Metadata Entity
-- Author: Sledmine
-- Entity to reflect response from package librarian fetch
------------------------------------------------------------------------------
local json = require "cjson"

local class = require("middleclass")

---@class packageMetadata
local packageMetadata = class("packageMetadata")

function packageMetadata:initialize(jsonString)
    local properties = json.decode(jsonString or "{}")
    ---@type string
    self.name = properties.name
    ---@type string
    self.package = properties.package
    ---@type string
    self.author = properties.author
    ---@type number
    self.version = tonumber(properties.version or 0)
    ---@type string
    self.url = properties.url
end

return packageMetadata

