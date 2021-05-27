local json = require "cjson"
local template = require "resty.template"

local f = io.open(ngx.config.prefix() .. "packagesList.json", "r")
local jsonContent = f:read("*all")

ngx.say(jsonContent)