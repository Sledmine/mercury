------------------------------------------------------------------------------
-- Task entity test
-- Author: Sledmine
-- Tests for task entity
------------------------------------------------------------------------------
package.path = package.path .. ";.\\Mercury\\?.lua"

local lu = require "luaunit"
local glue = require "glue"
inspect = require "inspect"

-- Global libraries
require "lib.utils"

-- Local function imports
local environment = require "config.environment"

-- Get all environment variables and configurations
environment.get()

-- Entities
local PackageMercury = require "entities.packageMercury"

testUtils = {}

function testUtils:setUp()
    ---@language JSON
    self.testPackage1 = [[{
        "label": "test",
        "name": "Mercury Test Package",
        "description": "A test package data for Mercury",
        "version": "1.0.0-r667",
        "author": "Sled",
        "internalVersion": "1.0.0-r667",
        "manifestVersion": "1.0",
        "files":  [
            {
                "path": "test.txt",
                "outputPath": "$haloce\\test\\",
                "type": "text"
            },
            {
                "path": "test2.txt",
                "outputPath": "$haloce\\test\\",
                "type": "text"
            }
        ],
        "dependencies": [
            {"label": "test2", "version": "1.0.0"}
        ]
    }]]
    self.expectedPackage1 = {
        label = "test",
        name = "Mercury Test Package",
        description = "A test package data for Mercury",
        version = "1.0.0-r667",
        author = "Sled",
        internalVersion = "1.0.0-r667",
        manifestVersion = "1.0",
        files = {
            {
                path = "test.txt",
                outputPath = GamePath .. "\\test\\",
                type = "text"
            },
            {
                path = "test2.txt",
                outputPath = GamePath .. "\\test\\",
                type = "text"
            }
        },
        dependencies = {
            {label = "test2", version = "1.0.0"}
        }
    }
    ---@language JSON
    self.testPackage2 = [[{
        "label": "test",
        "name": "Mercury Test Package",
        "version": "1.0.0-r667",
        "author": "Sled",
        "files":  [
            {
                "path": "test.txt",
                "outputPath": "$haloce\\test\\",
                "type": "text"
            },
            {
                "path": "test2.txt",
                "outputPath": "$haloce\\test\\",
                "type": "text"
            }
        ],
        "dependencies": [
            {"label": "test2", "version": "1.0.0"}
        ]
    }]]
    self.expectedPackage2 = {
        label = "test",
        name = "Mercury Test Package",
        version = "1.0.0-r667",
        author = "Sled",
        files = {
            {
                path = "test.txt",
                outputPath =   MyGamesPath .. "\\test\\",
                type = "text"
            },
            {
                path = "test2.txt",
                outputPath = MyGamesPath .. "\\test\\",
                type = "text"
            }
        },
        dependencies = {
            {label = "test2", version = "1.0.0"}
        }
    }
end

-- Test correct entity constructor
function testUtils:testEntityConstructor()
    ---@type packageMercury
    local packageInstance = PackageMercury:new(self.testPackage1)
    local packageProperties = packageInstance:getProperties()
    lu.assertEquals(packageProperties.label, self.expectedPackage1.label)
    lu.assertEquals(packageProperties.name, self.expectedPackage1.name)
    lu.assertEquals(packageProperties.description, self.expectedPackage1.description)
    lu.assertEquals(packageProperties.version, self.expectedPackage1.version)
    lu.assertEquals(packageProperties.author, self.expectedPackage1.author)
    lu.assertEquals(packageProperties.files, self.expectedPackage1.files)
    lu.assertEquals(packageProperties.dependencies, self.expectedPackage1.dependencies)
    lu.assertEquals(packageProperties.internalVersion, self.expectedPackage1.internalVersion)
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
