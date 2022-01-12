------------------------------------------------------------------------------
-- Merc module
-- Sledmine
-- Different methods to handle merc packages
------------------------------------------------------------------------------
local merc = {}

-- TODO Migrate this to minizip2
local minizip = require "minizip"
local zip = require "minizip2"
local glue = require "glue"
local json = require "cjson"
local pjson = require "pretty.json"
local v = require "semver"
local path = require "path"

local paths = environment.paths()

local constants = require "Mercury.modules.constants"

--- Unpack a merc package
---@param mercPath string Path to the merc package that will be unpacked
---@param unpackDir string Path of the output files unpacked from the merc package
---@return boolean result
function merc.unpack(mercPath, unpackDir)
    local dir, fileName, ext = splitPath(mercPath)
    dprint("Unpacking: " .. mercPath .. "...")
    dprint("To Dir: " .. unpackDir)
    local packageZip = minizip.open(mercPath, "r")

    -- Set current file as first file
    packageZip:first_file()

    -- Quantity of files in the zip
    -- FIXME I'm suspectig something around here is causing a memory leak
    local totalEntries = packageZip:get_global_info().entries

    local entriesCount = 0

    -- Iterate over all entries
    for entryIndex = 1, totalEntries do
        -- Store current file name
        local fileName = packageZip:get_file_info().filename
        local filePath = gpath(unpackDir, "/", fileName)

        -- Ignore manifest.json entry file and process all the other entries
        if (fileName ~= "manifest.json") then
            dprint("Entry: " .. entryIndex - 1 .. " / " .. totalEntries - 1)
            dprint("Decompressing \"" .. fileName .. "\"...")
        end

        -- Current entry is not a file, create a folder
        if (not isFile(fileName)) then
            dprint("Creating folder: '" .. fileName .. "'")
            createFolder(filePath)
        else
            -- Current file is indeed a file, just write it
            dprint("To path: " .. filePath)
            local dir = path.dir(filePath)
            if (not exists(dir)) then
                createFolder(dir)
            end
            glue.writefile(filePath, packageZip:extract(fileName), "b")
        end

        -- Step into next entry
        entriesCount = entriesCount + 1
        packageZip:next_file()
    end

    -- Close zip file
    packageZip:close()

    -- File count equals the number of files to unpack
    if (entriesCount >= totalEntries) then
        dprint("Done, " .. fileName .. " has been unpacked!")
        return true
    end
    cprint("Error, there was a problem at unpacking \"" .. mercPath .. "\".")
    return false
end

function merc.unzip(filepath, unpackPath)
    if (exists(filepath)) then
        local unzipCmd = constants.unzipCmdLine:format(filepath, unpackPath)
        if (IsDebugModeEnabled) then
            unzipCmd = constants.unzipCmdDebugLine:format(filepath, unpackPath)
        end
        local result = run(unzipCmd)
        return result
    end
    cprint("Error, there was a problem at unpacking \"" .. filepath .. "\".")
    return false
end

--- Pack a folder into a merc package
---@param packDir string
---@param mercPath string
function merc.pack(packDir, mercPath, breaking, feature, fix)
    if (packDir and mercPath and exists(packDir .. "/manifest.json")) then
        -- Read base manifest file
        local manifest = json.decode(glue.readfile(packDir .. "/manifest.json", "t"))
        if (manifest) then
            cprint("Automatically indexing manifest files from package folder... ", true)
            local packageFiles = filesIn(packDir, true)
            for _, filePath in ipairs(packageFiles) do
                if (not filePath:find("manifest.json")) then
                    local fileType = "binary"
                    local fileExtension = path.ext(filePath)
                    if (fileExtension == "json" or fileExtension == "ini" or fileExtension == "yml" or
                        fileExtension == "txt") then
                        fileType = "optional"
                    end
                    --local relativePath = filePath:gsub(packDir, "")
                    local relativePath = path.rel(filePath, packDir)
                    glue.append(manifest.files,
                                {path = relativePath, type = fileType, outputPath = relativePath})
                end
            end

            -- TODO Add manifest base files extension
            local finalManifestPath = paths.mercuryTemp .. "/manifest.json"
            glue.writefile(finalManifestPath, json.encode(manifest), "t")
            cprint("done.")

            -- Start package zip creation
            cprint("Packing given directory... ")
            local packageZip = zip.open(
                                   mercPath .. "/" .. manifest.label .. "-" .. manifest.version ..
                                       ".zip", "w")
            if (packageZip) then
                -- Allow sym links, append manifest file
                packageZip.store_links = false
                packageZip.follow_links = true
                packageZip:add_file(finalManifestPath)

                -- Add files from manifest
                for _, file in ipairs(manifest.files) do
                    cprint("-> " .. file.outputPath .. "... ", true)
                    local filePath = packDir .. "/" .. file.outputPath
                    packageZip:add_file(filePath, file.outputPath)
                    cprint("done.")
                end
                packageZip:close()

                cprint("Success, package has been created succesfully.")
                return true
            end
            cprint("Error, at creating Mercury package.")
        end
        cprint("Error, at trying to open manifest.json.")
    end
    cprint("Error, creating package from specified folder, verify manifest.json and paths.")
    return false
end

--- Attempt to create a template package folder
function merc.template()
    if (not exists("manifest.json")) then
        local manifest = {
            label = "",
            name = "",
            description = "",
            version = "",
            author = "",
            category = ""
        }
        for property, value in pairs(manifest) do
            print("-> Set " .. property .. ":")
            local value = io.read("l")
            if (value and value ~= "") then
                manifest[property] = value
            end
        end
        manifest.files = {}
        manifest.manifestVersion = "1.1.0"
        glue.writefile("manifest.json", pjson.stringify(manifest, nil, 4), "t")
        cprint("Success, package folder with manifest template has been created.")
        return true
    end
    cprint("Warning, there is already a manifest in this folder!")
    return false
end

function merc.diff(oldpackagePath, newPackagePath, diffPackagePath)
    local diffPackagePath = diffPackagePath or path.dir(newPackagePath) .. "/" ..
                                path.nameext(newPackagePath) .. ".mercu"
    local oldExtractionPath = paths.mercuryTemp .. "/old"
    local newExtractionPath = paths.mercuryTemp .. "/new"
    local diffExtractionPath = paths.mercuryTemp .. "/diff"

    cprint("Extracting zip files... ", true)
    local oldPackageZip = zip.open(oldpackagePath, "r")
    if (oldPackageZip) then
        createFolder(oldExtractionPath)
        oldPackageZip:extract_all(oldExtractionPath)
    else
        cprint("Error, at attempting to extract old package.")
        return false
    end
    local newPackageZip = zip.open(newPackagePath, "r")
    if (newPackageZip) then
        createFolder(newExtractionPath)
        newPackageZip:extract_all(newExtractionPath)
    else
        cprint("Error, at attempting to extract new package.")
    end
    cprint("done.")
    ---@type packageMercury
    local oldManifest = json.decode(glue.readfile(oldExtractionPath .. "/manifest.json", "t"))
    ---@type packageMercury
    local newManifest = json.decode(glue.readfile(newExtractionPath .. "/manifest.json", "t"))
    if (oldManifest and newManifest and oldManifest.label == newManifest.label) then
        -- Create diff files
        for oldFileIndex, oldFile in pairs(oldManifest.files) do
            local isFileOnNewPackage
            for newFileIndex, newFile in pairs(newManifest.files) do
                if (oldFile.path == newFile.path) then
                    isFileOnNewPackage = true
                    -- File should be updated
                    if (newFile.type == "binary") then
                        local oldFilePath = upath(oldExtractionPath .. "/" .. oldFile.path)
                        local newFilePath = upath(newExtractionPath .. "/" .. newFile.path)
                        local diffFilePath = upath(
                                                 diffExtractionPath .. "/" .. newFile.path .. ".xd3")

                        cprint("Searching, for differences in " .. oldFile.path)
                        if (SHA256(oldFilePath) ~= SHA256(newFilePath)) then
                            cprint("\tWarning, " .. oldFile.path ..
                                       " has differences between packages, creating xd3 diff!")

                            local diffFileFolderPath = path.dir(diffFilePath)
                            if (not exists(diffFileFolderPath)) then
                                if (not createFolder(diffFileFolderPath)) then
                                    cprint("Error, at trying to create output diff file folder: " ..
                                               diffFileFolderPath)
                                end
                            end
                            -- TODO: Add diff file creation verificaton
                            print("\tOld file: " .. oldFilePath)
                            print("\tNew file : " .. newFilePath)
                            print("\tDiff file: " .. diffFilePath)

                            local xd3Cmd = upath(constants.xd3CmdDiffLine:format(oldFilePath,
                                                                                 newFilePath,
                                                                                 diffFilePath))
                            dprint("xd3Cmd: " .. xd3Cmd)

                            local xd3Result = os.execute(xd3Cmd)
                            if (xd3Result) then
                                if (not newManifest.updates) then
                                    newManifest.updates = {}
                                end
                                -- Add xd3 file to updates
                                glue.append(newManifest.updates, {
                                    path = upath(newFile.path),
                                    diffPath = upath(
                                        diffFilePath:gsub(diffExtractionPath .. "/", "")),
                                    type = newFile.type,
                                    outputPath = upath(newFile.outputPath)
                                })
                            end
                        end
                        -- File is an update so remove file from installation files
                        -- newManifest.files[newFileIndex] = nil
                        table.remove(newManifest.files, newFileIndex)
                    elseif (newFile.type == "optional") then
                        -- File is optional we need to remove it from installation files
                        -- newManifest.files[newFileIndex] = nil
                        table.remove(newManifest.files, newFileIndex)
                    end
                end
            end
            if (not isFileOnNewPackage) then
                cprint("Warning, file " .. oldFile.path .. " is not present on the new package.")
            end
        end

        for fileIndex, file in pairs(newManifest.files) do
            if (exists(newExtractionPath .. "/" .. file.path)) then
                createFolder(diffExtractionPath .. "/" .. path.dir(file.path))
                copyFile(newExtractionPath .. "/" .. file.path,
                         diffExtractionPath .. "/" .. file.path)
            else
                cprint("Warning, file \"" .. file.path .. "\" does not exist!")
                table.remove(newManifest.files, fileIndex)
            end
        end
        newManifest.targetVersion = oldManifest.version
        glue.writefile(diffExtractionPath .. "/manifest.json", json.encode(newManifest), "t")

        if (exists(diffPackagePath)) then
            delete(diffPackagePath)
        end

        -- Zip new package
        cprint("Packing update diff... ", true)
        local diffPackageZip = zip.open(diffPackagePath, "w")
        if (diffPackageZip) then
            diffPackageZip:add_all(diffExtractionPath)
            diffPackageZip:close()
            cprint("done.")
            return true
        end
    end
    cprint("Error, at attempting to create diff package.")
    return false
end

return merc
