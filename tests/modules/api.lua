------------------------------------------------------------------------------
-- API consumer tests
-- Sledmine
-- Tests for api consumer
------------------------------------------------------------------------------
local lu = require "luaunit"
inspect = require "inspect"

-- Global modules
require "Mercury.lib.utils"

local api = require "Mercury.modules.api"

testApi = {}

function testApi:setUp()
    api.repositoryHost = "localhost:3000"
    api.protocol = "http"

    self.expectedPackage =
        [[{"name":"test","label":"test","author":"Sledmine","version":"1.0.0","fullVersion":"1.0.0","mirrors":["http://localhost:3000/repository/test/1.0.0/test.merc"],"nextVersion":"2.0.0"}]]
end

function testApi:testGetPackage()
    local error, response = api.getPackage("test", "1.0.0")
    lu.assertEquals(error, 200)
    lu.assertEquals(response, self.expectedPackage)
end

function testApi:testGetPackageFailureResponse()
    local error, response = api.getPackage("nopackage", "1.0.0")
    lu.assertEquals(error, 404)
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
