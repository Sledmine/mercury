------------------------------------------------------------------------------
-- Merc module tests
-- Sledmine
-- Tests for merc module methods
------------------------------------------------------------------------------
package.path = package.path .. ";Mercury/?.lua"
luna = require "modules.luna"
local lu = require "luaunit"
inspect = require "inspect"

require "modules.utils"
config = require "cli.config"
local paths = config.paths()
IsDebugModeEnabled = true

local luabundler = require "modules.luabundle"
local analyzeDependencies = luabundler.analyzeDependencies
local getModulePath = luabundler.getModulePath

testBundler = {}

-- Before every unit test
function testBundler:setUp()
end

function testBundler:testAnalyseDependencies()
    local bundlerPath = "Mercury/tests/bundler/"

    local dependencies = assert(analyzeDependencies(bundlerPath .. "main.lua"))
    lu.assertEquals(dependencies, {"single", "subfolder.another", "subfolder.common"})

    local modulePath = getModulePath("subfolder.another", {bundlerPath .. "modules"})
    lu.assertEquals(modulePath, bundlerPath .. "modules/subfolder/another.lua")

    for _, dependency in pairs(dependencies) do
        local modulePath = assert(getModulePath(dependency, {"Mercury/tests/bundler/modules"}))
        if exists(modulePath) then
            print("Module exists with path: ", modulePath)
            local moduleDependencies = analyzeDependencies(modulePath)
            print("Requires: ")
            print(inspect(moduleDependencies))
        end
    end
end

local function runTests()
    local runner = lu.LuaUnit.new()
    runner:runSuite()
end

if not arg then
    return runTests
else
    runTests()
end
