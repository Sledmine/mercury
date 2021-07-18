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

-- Before every unit test
function testMerc:setUp()
    self.inputPack = "./Mercury/tests/modules/merc/unpack/unpack.merc"
    self.unpackDir = "./Mercury/tests/modules/merc/unpackDir"
    
    self.packDir = "./Mercury/tests/modules/merc/pack"
    self.outputPack = "./Mercury/tests/modules/merc/pack/pack.merc"
end

-- Specifically test unpack method
function testMerc:testUnpack()
    delete(self.unpackDir, true)
    createFolder(self.unpackDir)
    if (exist(self.inputPack)) then
        lu.assertIsTrue(merc.unpack(self.inputPack, self.unpackDir))
        lu.assertIsTrue(exist(self.unpackDir .. "/manifest.json"))
        delete(self.unpackDir, true)
    else
        lu.fail("Input merc package does not exist")
    end
end

function testMerc:testPack() 
    delete(self.outputPack)
    if(exist(self.packDir)) then
        lu.assertIsTrue(merc.pack(self.packDir, self.outputPack))
        lu.assertIsTrue(exist(self.outputPack))
        delete(self.outputPack)
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
