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
    self.inputMerc = "./Mercury/tests/modules/merc/package/unpack.merc"
    self.outputMercPath = "./Mercury/tests/modules/merc/unpack"
    
    self.packDir = "./Mercury/tests/modules/merc/packDir"
    self.outputDir = "./Mercury/tests/modules/merc/package/pack.merc"
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

function testMerc:testPack() 
    delete(self.outputDir)
    if(exist(self.packDir)) then
        lu.assertIsTrue(merc.pack(self.packDir, self.outputDir))
        lu.assertIsTrue(exist(self.outputDir))
        delete(self.outputDir)
    else
        lu.fail("packDir does not exist")
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
