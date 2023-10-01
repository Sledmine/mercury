------------------------------------------------------------------------------
-- Merc module
-- Sledmine
-- Different methods to handle merc packages
------------------------------------------------------------------------------
local merc = {}

local zip = require "minizip2"
local glue = require "glue"
local starts = glue.string.starts
local ends = glue.string.ends
local json = require "cjson"
local pjson = require "pretty.json"
local v = require "semver"
local path = require "path"

local paths = config.paths()

local constants = require "modules.constants"

--- Extract a Mercury package using 7z command
---@param filepath string Package path that will be unziped
---@param unpackDir string Directory path to place output files
---@param action "extract" | "compress" Action to perform
local function sevenZip(filepath, unpackDir, action)
    if exists(filepath) then
        local commandToUse = constants.sevenZipExtractCmdLine
        if action == "compress" then
            commandToUse = constants.sevenZipCompressCmdLine
        end
        local sevenZipCmd = commandToUse:format(filepath, unpackDir)
        dprint("sevenZipCmd: " .. sevenZipCmd)
        local result = run(sevenZipCmd, true)
        return result
    end
    return false
end

--- Extract a Mercury package using minizip library
---@param filepath string Package path that will be unziped
---@param unpackDir string Directory path to place output files
---@param action "extract" | "compress" Action to perform
local function minizip(filepath, unpackDir, action)
    local packageZip = zip.open(filepath, "r")
    if packageZip then
        if exists(unpackDir) or createFolder(unpackDir) then
            packageZip:extract_all(unpackDir)
            packageZip:close()
            return true
        end
        cprint("Error at creating unpack folder \"" .. unpackDir .. "\".")
        return false
    end
    return false
end

local backends = {minizip = minizip, ["7z"] = sevenZip}

--- Unpack a Mercury package
---@param filepath string Package path that will be unpacked
---@param unpackDir string Directory path to place output files
---@param backend? "minizip" | "unzip" | "7z" Backend to use for unpacking
function merc.unpack(filepath, unpackDir, backend)
    dprint("Unpacking " .. filepath .. "...")
    cprint("Unpacking zip...")
    local backend = backend or "minizip"

    local implementation = backends[backend]
    if not implementation then
        cprint("Error invalid backend \"" .. backend .. "\".")
        return false
    end

    local result = implementation(filepath, unpackDir, "extract")
    if result then
        return true
    end

    return false
end

--- Determine if a file is optional
---@param extension string
local function isFileOptional(extension)
    return extension == "json" or extension == "ini" or extension == "yml" or extension == "txt"
end

--- Pack a folder into a Mercury package
---@param packDir string
---@param mercPath string
---@param backend? "minizip" | "unzip" | "7z" Backend to use for packing
function merc.pack(packDir, mercPath, backend)
    local backend = backend or "minizip"

    if not exists(packDir .. "/manifest.json") then
        cprint("Error, creating package from specified folder, verify manifest.json and paths.")
        return false
    end

    -- Read base manifest file
    local manifest = json.decode(readFile(packDir .. "/manifest.json"))
    if not manifest then
        cprint("Error, at trying to open manifest.json.")
    end

    cprint("Automatically indexing manifest files from package folder... ", true)
    local packageFiles = filesIn(packDir, true)
    
    for _, fpath in ipairs(packageFiles) do
        if not fpath:endswith "manifest.json" and not path.file(fpath):startswith "." then
            local type = "binary"
            local extension = path.ext(fpath)
            if isFileOptional(extension) then
                type = "optional"
            end
            local relativePath = path.rel(fpath, packDir)
            table.insert(manifest.files,
                         {path = relativePath, type = type, outputPath = relativePath})
        end
    end

    -- TODO Add manifest base files extension
    local finalManifestPath = gpath(paths.mercuryTemp, "/manifest.json")
    writeFile(finalManifestPath, json.encode(manifest))
    cprint("done.")

    -- Start package zip creation
    cprint("Packing given directory... ")
    local packageZip = zip.open(mercPath .. "/" .. manifest.label .. "-" .. manifest.version ..
                                    ".zip", "w")
    if not packageZip then
        cprint("Error, at creating Mercury package.")
    end
    -- Allow sym links, append manifest file
    packageZip.store_links = false
    packageZip.follow_links = true
    packageZip:add_file(finalManifestPath)

    -- Add files from manifest
    for _, file in ipairs(manifest.files) do
        -- Use print instead of cprint due to weird bug with stdout using zip open
        print("-> " .. file.outputPath)
        local filePath = packDir .. "/" .. file.outputPath
        packageZip:add_file(filePath, file.outputPath)
    end
    packageZip:close()

    cprint("Success, package has been created succesfully.")
    return true

end

--- Attempt to create a template package folder
function merc.template()
    if not exists "manifest.json" then
        local options = {category = {"map", "script", "addon", "config", "fix"}}

        local manifest = {
            label = "",
            name = "",
            description = "",
            version = "",
            author = "",
            category = ""
        }

        for property in pairs(manifest) do
            if options[property] then
                print("-> Set " .. property .. ":",
                      ("(%s) "):format(table.concat(options[property], ", ")))
            else
                print("-> Set " .. property .. ":")
            end
            local value = io.read("l")

            if not (value and value ~= "") then
                cprint("Error, invalid value for " .. property .. ".")
                return false
            end

            if property == "version" then
                -- Verify version is a semver string
                if not value:match("%d+%.%d+%.%d+") then
                    cprint("Error, version must be a valid semver string, see: https://semver.org/")
                    return false
                end
            elseif property == "label" then
                -- Verify label is all lowercase and no spaces or special characters
                if not value:match("%l+") then
                    cprint("Error, label must be all lowercase and no spaces or special characters.")
                    return false
                end
            elseif options[property] then
                -- Verify value is a valid option
                if not table.indexof(options[property], value) then
                    cprint("Error, invalid value for " .. property .. ".")
                    return false
                end
            end

            manifest[property] = value
        end

        manifest.files = {}
        manifest.manifestVersion = "1.1.0"
        createFolder("game-root")
        createFolder("game-maps")
        createFolder("game-mods")
        createFolder("lua-map")
        createFolder("lua-global")
        createFolder("lua-data-global")
        createFolder("lua-data-map")
        writeFile("manifest.json", pjson.stringify(manifest, nil, 4))
        cprint("Success, package folder with manifest template has been created.")
        return true
    end
    cprint("Warning there is already a manifest in this folder!")
    return false
end

function merc.diff(oldpackagePath, newPackagePath, diffPackagePath)
    local diffPackagePath = (diffPackagePath or (path.dir(newPackagePath)) .. "/") ..
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
    local oldManifest = json.decode(readFile(oldExtractionPath .. "/manifest.json"))
    ---@type packageMercury
    local newManifest = json.decode(readFile(newExtractionPath .. "/manifest.json"))
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

                        cprint("Searching for differences in " .. oldFile.path)
                        -- dprint(SHA256(oldFilePath) .. " -> " .. SHA256(newFilePath))
                        if (SHA256(oldFilePath) ~= SHA256(newFilePath)) then
                            cprint("\tWarning " .. oldFile.path ..
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
                cprint("Warning file " .. oldFile.path .. " is not present on the new package.")
            end
        end

        for fileIndex, file in pairs(newManifest.files) do
            if (exists(newExtractionPath .. "/" .. file.path)) then
                createFolder(diffExtractionPath .. "/" .. path.dir(file.path))
                copyFile(newExtractionPath .. "/" .. file.path,
                         diffExtractionPath .. "/" .. file.path)
            else
                cprint("Warning file \"" .. file.path .. "\" does not exist!")
                table.remove(newManifest.files, fileIndex)
            end
        end
        newManifest.targetVersion = oldManifest.version
        writeFile(diffExtractionPath .. "/manifest.json", json.encode(newManifest))

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

function merc.manifest(packagePath)
    local package = zip.open(packagePath, "r")
    if package then
        local manifest
        for entry in package:entries() do
            if entry.filename == "manifest.json" then
                manifest = package:read("*a")
            end
        end
        if manifest then
            print(manifest)
        end
        package:close()
        return true
    end
    cprint("Error, at attempting to read manifest file.")
    return false
end

return merc
