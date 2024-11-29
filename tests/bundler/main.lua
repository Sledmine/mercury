local single = require'single'
-- Custom requires
local another = try_require("subfolder.another")
-- Common requires
local common = require "subfolder.common"
local anotherWithPropertAccess = require"subfolder.another".new
local dynamic = require("dynamic" .. test)

console_out "Hello from main.lua!"
