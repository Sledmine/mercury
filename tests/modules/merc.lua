------------------------------------------------------------------------------
-- Merc module tests
-- Sledmine
-- Tests for merc module methods
------------------------------------------------------------------------------
local lu = require "luaunit"
inspect = require "inspect"
require "modules.utils"
environment = require "config.environment"
local merc = require "modules.merc"

testMerc = {}

-- Before every unit test
function testMerc:setUp()
    self.unpackPackagePath = "Mercury/tests/modules/merc/unpack/package.merc"
    self.unpackedPath = "Mercury/tests/modules/merc/unpack/unpacked/"
    
    self.packPath = "Mercury/tests/modules/merc/pack/"
    self.packedPath = "Mercury/tests/modules/merc/pack/"

    self.oldPackagePath = "Mercury/tests/modules/merc/diff/test-1.0.0.zip"
    self.newPackagePath = "Mercury/tests/modules/merc/diff/test-1.0.1.zip"
    self.diffPackageFolder = "Mercury/tests/modules/merc/diff/"
    self.diffUnpackedFolder = "Mercury/tests/modules/merc/diff/unpacked/"
end

-- Specifically test unpack method
function testMerc:testUnpack()
    delete(self.unpackedPath, true)
    createFolder(self.unpackedPath)
    if (exists(self.unpackPackagePath)) then
        lu.assertIsTrue(merc.unpack(self.unpackPackagePath, self.unpackedPath))
        lu.assertIsTrue(exists(self.unpackedPath .. "/manifest.json"))
        delete(self.unpackedPath, true)
    else
        lu.fail("Input merc package does not exist")
    end
end

function testMerc:testPack()
    delete(self.packedPath)
    if(exists(self.packPath)) then
        lu.assertIsTrue(merc.pack(self.packPath, self.packedPath))
        lu.assertIsTrue(exists(self.packedPath))
        delete(self.packedPath .. "unpacked-1.0.0.zip")
    else
        lu.fail("packDir does not exist")
    end
end

function testMerc:testDiff()
    environment.clean()
    delete(self.diffUnpackedFolder)
    delete(self.diffPackageFolder .. "test-1.0.1.mercu")
    lu.assertIsTrue(merc.diff(self.oldPackagePath, self.newPackagePath, self.diffPackageFolder))
    lu.assertIsTrue(merc.unpack(self.diffPackageFolder .. "test-1.0.1.mercu", self.diffUnpackedFolder))
    lu.assertEquals(SHA256(self.diffUnpackedFolder .. "game-maps/newfile.map"), SHA256(self.diffPackageFolder .. "newfile.map"))
    delete(self.diffUnpackedFolder)
    delete(self.diffPackageFolder .. "test-1.0.1.mercu")
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
