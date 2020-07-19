------------------------------------------------------------------------------
-- Task entity test
-- Author: Sledmine
-- Tests for task entity
------------------------------------------------------------------------------
local lu = require("luaunit")
local glue = require("glue")

-- Local libraries
local utils = require "Mercury.lib.utilis"

-- Local function imports
local environment = require "Mercury.config.environment"

-- Get all environment variables and configurations
environment.get()

-- Entities
local PackageMercury = require("Mercury.entities.packageMercury")

test_PackageMercury = {}

function test_PackageMercury:setUp()
    self.jsonString = [[{
        "label": "test",
        "name": "Mercury Test Package",
        "version": "1.0",
        "author": "Sled",
        "files": {
            "test.txt": "_HALOCE\\MERCURY_TEST\\",
            "test2.txt": "_HALOCE\\MERCURY_TEST\\"
        }
    }]]
    self.expectedEntity = {
        label = "test",
        name = "Mercury Test Package",
        version = 1.0,
        author = "Sled",
        files = {
            ["test.txt"] = _HALOCE .. "\\MERCURY_TEST\\",
            ["test2.txt"] = _HALOCE .. "\\MERCURY_TEST\\",
        },
    }
end

-- Test correct entity constructor
function test_PackageMercury:test_EntityConstructor()
    ---@type packageMercury
    local packageInstance = PackageMercury:new(self.jsonString)
    local packageProperties = packageInstance:getProperties()
    lu.assertEquals(packageProperties.author, self.expectedEntity.author)
    lu.assertEquals(packageProperties.label, self.expectedEntity.label)
    lu.assertEquals(packageProperties.version, self.expectedEntity.version)
    lu.assertEquals(packageProperties.name, self.expectedEntity.name)
    lu.assertEquals(packageProperties.files, self.expectedEntity.files)
end

local function runTests()
    local runner = lu.LuaUnit.new()
    runner:runSuite()
end

if (not arg) then
    return runTests
else
    runTests()
end
