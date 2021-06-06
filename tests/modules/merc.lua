------------------------------------------------------------------------------
-- Merc module tests
-- Sledmine
-- Tests for merc module methods
------------------------------------------------------------------------------
local lu = require "luaunit"
inspect = require "inspect"

require "Mercury.modules.utils"

local merc = require "Mercury.modules.merc"

testMerc = {}

function testMerc:setUp()
    -- Before every unit test
    self.inputMerc = "./Mercury/tests/modules/merc/package/test-1.0.0.merc"
    self.outputMercPath = "./Mercury/tests/modules/merc/unpack"
    
    self.sourceMerc = "./Mercury/tests/modules/merc/src"
end

-- Specifically test unpack method
function testMerc:testUnpack()
    --IsDebugModeEnabled = true
    delete(self.outputMercPath, true)
    createFolder(self.outputMercPath)
    if (exist(self.inputMerc)) then
        lu.assertIsTrue(merc.unpack(self.inputMerc, self.outputMercPath))
        lu.assertIsTrue(exist(self.outputMercPath .. "/manifest.json"))
        delete(self.outputMercPath, true)
    else
        lu.fail("Input merc package does not exist")
    end
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
