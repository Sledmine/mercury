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
local merc = require "modules.merc"
local unpack = merc.unpack
local pack = merc.pack
IsDebugModeEnabled = true

testMerc = {}

-- Before every unit test
function testMerc:setUp()
    self.packagePath = gpath("Mercury/tests/package.zip")
    self.unpackedPath = gpath(paths.mercuryUnpacked, "/", "package")

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

    if not exists(self.packagePath) then
        lu.fail("Input merc package does not exist")
    end
    lu.assertIsTrue(unpack(self.packagePath, self.unpackedPath, "7z"), "Unpack method failed")
    local manifestPath = gpath(self.unpackedPath .. "/manifest.json")
    dprint("Manifest path: " .. manifestPath)
    lu.assertIsTrue(exists(manifestPath))
    delete(self.unpackedPath, true)
end

function testMerc:testPack()
    delete(self.packedPath)

    if exists(self.packPath) then
        lu.assertIsTrue(pack(self.packPath, self.packedPath))
        lu.assertIsTrue(exists(self.packedPath))
        delete(self.packedPath .. "unpacked-1.0.0.zip")
    else
        lu.fail("packDir does not exist")
    end
end

function testMerc:testDiff()
    config.clean()
    delete(self.diffUnpackedFolder)
    delete(self.diffPackageFolder .. "test-1.0.1.mercu")
    lu.assertIsTrue(merc.diff(self.oldPackagePath, self.newPackagePath, self.diffPackageFolder))
    lu.assertIsTrue(merc.unpack(self.diffPackageFolder .. "test-1.0.1.mercu",
                                self.diffUnpackedFolder))
    lu.assertEquals(SHA256(self.diffUnpackedFolder .. "game-maps/newfile.map"),
                    SHA256(self.diffPackageFolder .. "newfile.map"))
    delete(self.diffUnpackedFolder)
    delete(self.diffPackageFolder .. "test-1.0.1.mercu")
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
