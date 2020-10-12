------------------------------------------------------------------------------
-- Task entity test
-- Author: Sledmine
-- Tests for task entity
------------------------------------------------------------------------------
local lu = require "luaunit"
local glue = require "glue"
inspect = require "inspect"

-- Global libraries
require "Mercury.lib.utils"

-- Local function imports
local environment = require "Mercury.config.environment"

-- Get all environment variables and configurations
environment.get()

-- Entities
local PackageMercury = require("Mercury.entities.packageMercury")

testPackageMercury = {}

function testPackageMercury:setUp()
    ---@language JSON
    self.testPackage1 = [[{
        "label": "test",
        "name": "Mercury Test Package",
        "version": "1.0.0.r667.5769751",
        "author": "Sled",
        "files": {
            "test.txt": "_HALOCE\\merctest\\",
            "test2.txt": "_HALOCE\\merctest\\"
        },
        "dependencies": [
            {"label": "test2", "version":1}
        ]
    }]]
    self.expectedPackage1 = {
        label = "test",
        name = "Mercury Test Package",
        version = "1.0.0.r667.5769751",
        internalVersion = 1006675769751,
        author = "Sled",
        files = {
            ["test.txt"] = GamePath .. "\\merctest\\",
            ["test2.txt"] = GamePath .. "\\merctest\\"
        },
        dependencies = {
            {label = "test2", version = 1}
        }
    }
    ---@language JSON
    self.testPackage2 = [[{
        "label": "test",
        "name": "Mercury Test Package",
        "version": "1234",
        "author": "Sled",
        "files": {
            "test.txt": "_HALOCE\\merctest\\",
            "test2.txt": "_HALOCE\\merctest\\"
        },
        "dependencies": [
            {"label": "test2", "version":1}
        ]
    }]]
    self.expectedPackage2 = {
        label = "test",
        name = "Mercury Test Package",
        version = "1234",
        internalVersion = 1234,
        author = "Sled",
        files = {
            ["test.txt"] = GamePath .. "\\merctest\\",
            ["test2.txt"] = GamePath .. "\\merctest\\"
        },
        dependencies = {
            {label = "test2", version = 1}
        }
    }
end

-- Test correct entity constructor
function testPackageMercury:testEntityConstructor()
    ---@type packageMercury
    local packageInstance = PackageMercury:new(self.testPackage1)
    local packageProperties = packageInstance:getProperties()
    lu.assertEquals(packageProperties.author, self.expectedPackage1.author)
    lu.assertEquals(packageProperties.label, self.expectedPackage1.label)
    lu.assertEquals(packageProperties.version, self.expectedPackage1.version)
    lu.assertEquals(packageProperties.name, self.expectedPackage1.name)
    lu.assertEquals(packageProperties.files, self.expectedPackage1.files)
    lu.assertEquals(packageProperties.dependencies, self.expectedPackage1.dependencies)
end

function testPackageMercury:testEntityInternalVersion()
    ---@type packageMercury
    local packageInstance = PackageMercury:new(self.testPackage1)
    lu.assertEquals(packageInstance.internalVersion, self.expectedPackage1.internalVersion)
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
