-------------------------------------------------------------------------------
--- Updater service for Mercury
--- Sledmine
--- Script to provide updates between Mercury packages
-------------------------------------------------------------------------------
local path = require "path"

local argparse = require "argparse"
local glue = require "glue"
local json = require "ljson"
local pjson = require "pretty.json"
local inspect = require "inspect"
local v = require "semver"

-- Script configuration
---@class mercDependencies
---@field label string
---@field version string

---@class mercFiles
---@field path string
---@field type string
---@field outputPath string

---@class mercUpdates
---@field path string
---@field diffPath string
---@field type string
---@field outputPath string

---@class packageMercury
---@field name string
---@field label string
---@field description string
---@field author string
---@field version string
---@field internalVersion string
---@field manifestVersion string
---@field files mercFiles[]
---@field updates mercUpdates[]
---@field dependencies mercDependencies[]

local parser = argparse("Updater", "Create an update package between Mercury packages")
parser:argument("oldPackage", "Old mercury package to update")
parser:argument("newPackage", "New mercury package for creating diff")
parser:argument("updatePackage", "Path for update package")

-- Parsed args
local args = parser:parse()

-- Unzip packages
os.execute("mkdir temp & cd temp & mkdir updatedPackage")
local unzipCmdLine = "unzip -u -d temp/%s %s"
os.execute(unzipCmdLine:format("oldPackage", args.oldPackage))
os.execute(unzipCmdLine:format("newPackage", args.newPackage))

---@type packageMercury
local oldManifest = json.decode(glue.readfile("temp/oldPackage/manifest.json", "t"))

---@type packageMercury
local newManifest = json.decode(glue.readfile("temp/newPackage/manifest.json", "t"))

local function manifestAreCompatible()
    return oldManifest and newManifest and oldManifest.label == newManifest.label and
               v(newManifest.version) >= v(oldManifest.version)
end

if (manifestAreCompatible()) then
    -- Create diff files
    local xd3CmdLine = "xdelta3 -f -e -s \"%s\" \"%s\" \"%s\""
    for oldFileIndex, oldFile in pairs(oldManifest.files) do
        for newFileIndex, newFile in pairs(newManifest.files) do
            if (oldFile.path == newFile.path) then
                -- File should be updated
                if (newFile.type == "binary") then
                    print(newFile.path .. " is candidate for diff creation.")

                    local oldFilePath = "temp/oldPackage/" .. oldFile.path
                    local newFilePath = "temp/newPackage/" .. newFile.path
                    local diffFilePath = "temp/updatedPackage/" .. newFile.path .. ".xd3"
                    local standardDiffFilePath = diffFilePath:gsub("\\", "/")

                    local outputDiffFileFolderPath = standardDiffFilePath:gsub(path.file(standardDiffFilePath), "")
                    local createOutputPathCmd = "mkdir " .. outputDiffFileFolderPath
                    print(createOutputPathCmd)
                    os.execute(createOutputPathCmd:gsub("/", "\\"))

                    print("oldFilePath: " .. oldFilePath)
                    print("newFilePath: " .. newFilePath)
                    print("diffFilePath: " .. diffFilePath)

                    local xd3Cmd = xd3CmdLine:format(oldFilePath, newFilePath, diffFilePath):gsub("\\", "/")
                    print("xd3Cmd: " .. xd3Cmd)

                    local xd3Result = os.execute(xd3Cmd)
                    if (xd3Result) then
                        if (not newManifest.updates) then
                            newManifest.updates = {}
                        end
                        -- Add xd3 file to updates
                        glue.append(newManifest.updates, {
                            path = newFile.path,
                            diffPath = diffFilePath:gsub("temp/updatedPackage/", ""):gsub("/", "\\"),
                            type = newFile.type,
                            outputPath = newFile.outputPath
                        })
                    end

                    -- File is an update so remove file from installation files
                    newManifest.files[newFileIndex] = nil
                elseif (newFile.type == "optional") then
                    -- File is optional we need to remove it from installation files
                    newManifest.files[newFileIndex] = nil
                end
            end
        end
    end

    newManifest.targetVersion = oldManifest.version
    glue.writefile("temp/updatedPackage/manifest.json", pjson.stringify(newManifest, nil, 4), "t")

    -- Zip new package
    local zipCmdLine = "cd temp & cd updatedPackage & zip -r ../../\"%s\" ."
    os.execute(zipCmdLine:format(args.updatePackage))
else
    -- Cleanup
    os.execute("rm -rf ./temp")
    print("Error, manifest files have a problem or are uncompatible!")
    print("Keep in mind that updates can't be created for packages backwards.")
    print("Updates can't be created for totally different packages.")
    os.exit(1)
end

-- Cleanup and safe exit
os.execute("rm -rf ./temp")
os.exit(0)
