------------------------------------------------------------------------------
-- Utils methods test
-- Sledmine
-- Tests for utils lib
------------------------------------------------------------------------------
local lu = require "luaunit"
local glue = require "glue"
inspect = require "inspect"

-- Global modules
require "modules.utils"

testUtils = {}

function testUtils:setUp()
    self.testFilePath = "C:/Test/Filename.txt"
    self.testPath = "C:/Test/"
    self.testPathNoSlash = "C:/Test"
    self.testFile = "Filename.txt"
end

function testUtils:testSplitPath()
    -- Force Windows test cases
    jit.os = "Windows"
    local directory, fileName, extension = splitPath(self.testFilePath)
    lu.assertEquals(directory, "C:\\Test")
    lu.assertEquals(fileName, "Filename")
    lu.assertEquals(extension, "txt")
    -- Test only path string type
    directory, fileName, extension = splitPath(self.testPath)
    lu.assertEquals(directory, "C:\\Test")
    lu.assertIsNil(fileName)
    lu.assertIsNil(extension)
    -- Test only file string type
    directory, fileName, extension = splitPath(self.testFile)
    lu.assertIsNil(directory)
    lu.assertEquals(fileName, "Filename")
    lu.assertEquals(extension, "txt")

    -- Force Linux test cases
    jit.os = "Linux"
    directory, fileName, extension = splitPath(self.testFilePath)
    lu.assertEquals(directory, "C:/Test")
    lu.assertEquals(fileName, "Filename")
    lu.assertEquals(extension, "txt")
    -- Test only path string type
    directory, fileName, extension = splitPath(self.testPath)
    lu.assertEquals(directory, "C:/Test")
    lu.assertIsNil(fileName)
    lu.assertIsNil(extension)
    -- Test only file string type
    directory, fileName, extension = splitPath(self.testFile)
    lu.assertIsNil(directory)
    lu.assertEquals(fileName, "Filename")
    lu.assertEquals(extension, "txt")

end

function testUtils:testGeneratePath()
    jit.os = "Windows"
    lu.assertEquals(gpath("/home/sledmine/Documents/"), "\\home\\sledmine\\Documents\\")
    lu.assertEquals(gpath("/home/sledmine", "/Downloads", "/Music/"), "\\home\\sledmine\\Downloads\\Music\\")

    jit.os = "Linux"
    lu.assertEquals(gpath("\\home\\sledmine\\Documents"), "/home/sledmine/Documents")
    lu.assertEquals(gpath("\\home\\sledmine", "\\Downloads", "\\Music\\"), "/home/sledmine/Downloads/Music/")
end

function testUtils:testCopyFile()
    local filePath = "test.dat"
    local copyFilePath = filePath .. ".copy"
    copyFile(filePath, copyFilePath)

    local sha256FilePath = SHA256(filePath)
    local sha256CopyFilePath = SHA256(copyFilePath)
    lu.assertNotIsNil(sha256FilePath)
    lu.assertNotIsNil(sha256CopyFilePath)
    lu.assertEquals(sha256FilePath, sha256FilePath, "Checksum verification must be equal")
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
