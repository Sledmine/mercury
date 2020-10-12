------------------------------------------------------------------------------
-- Error Summary Entity
-- Author: Sledmine
-- Object to share common errors and useful data
------------------------------------------------------------------------------
local json = require "cjson"

local class = require "middleclass"

---@class errorSummary
local errorSummary = class "packageMercury"

---@class errorSummaryJson
---@field severity string
---@field message string
---@field data table

--- Entity constructor
---@param severity string
---@param message string
---@param data table
function errorSummary:initialize(severity, message, data)
    ---@type string
    self.severity = severity
    ---@type string
    self.message = message
    ---@type table
    self.data = data
end

--- Return entity as a json
---@return errorSummaryJson
function errorSummary:toJson()
    return json.encode({
        severity = self.severity,
        message = self.message,
        data = self.data
    })
end

return errorSummary

