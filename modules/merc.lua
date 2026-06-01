------------------------------------------------------------------------------
-- Merc module
-- Sledmine
-- Different methods to handle merc packages
------------------------------------------------------------------------------
local merc = {}

local zip = require "minizip2"
local glue = require "glue"
local packageMercury = require "entities.packageMercury"
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
        cprint("Error creating package from specified folder, verify manifest.json and paths.")
        return false
    end

    -- Read base manifest file
    local manifest = json.decode(readFile(packDir .. "/manifest.json"))
    if not manifest then
        cprint("Error at trying to open manifest.json.")
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
            -- local relativePath = path.rel(fpath, packDir)
            local relativePath = upath(path.rel(fpath, packDir))
            table.insert(manifest.files,
                         {path = relativePath, type = type, outputPath = relativePath})
        end
    end

    -- TODO Add manifest base files extension
    local finalManifestPath = gpath(paths.mercuryTemp .. "/manifest.json")
    writeFile(finalManifestPath, json.encode(manifest))
    cprint("done.")

    -- Start package zip creation
    cprint("Packing given directory... ")
    local packageZip = zip.open(mercPath .. "/" .. manifest.label .. "-" .. manifest.version ..
                                    ".zip", "w")
    if not packageZip then
        cprint("Error at creating Mercury package.")
    end
    -- Allow sym links, append manifest file
    packageZip.store_links = false
    packageZip.follow_links = true
    packageZip:add_file(finalManifestPath)

    -- Add files from manifest
    for _, file in ipairs(manifest.files) do
        -- Use print instead of cprint due to weird bug with stdout using zip open
        local filePath = gpath(packDir .. "/" .. file.outputPath)
        -- Try to resolve symlinks on Linux systems
        -- This prevents a weird bug at extracting files that were once symlinks
        if not isHostWindows() then
            local readlink = io.popen("readlink -f -n " .. filePath)
            assert(readlink)
            filePath = readlink:read("*a"):trim()
        end
        local outputPath = upath(file.outputPath)
        print("-> " .. outputPath)
        packageZip:add_file(filePath, outputPath)
    end
    packageZip:close()

    cprint("Success package has been created succesfully.")
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
        manifest.manifestVersion = packageMercury:getExpectedVersion()
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

--- Run multiple shell commands in parallel and wait for all to complete.
--- On Linux/macOS uses shell background jobs and the built-in `wait` builtin.
--- On Windows launches each command via `start /B` inside a temp batch file and
--- polls per-job completion marker files so the main process blocks until all
--- jobs finish or the optional timeout is reached.
---@param commands string[] List of shell commands to execute in parallel
---@param timeout? number Maximum seconds to wait on Windows (default 600)
---@return boolean success True when every command completed, false on timeout
local function runParallel(commands, timeout)
    if #commands == 0 then
        return true
    end
    if #commands == 1 then
        return run(commands[1]) ~= nil
    end

    if isHostWindows() then
        timeout = timeout or 600
        -- Build a batch file that starts every command in the background.
        -- Each job appends a line to a unique marker file on completion so we
        -- can poll for it without needing external utilities.
        local markers = {}
        local batLines = {"@echo off"}
        for i, cmd in ipairs(commands) do
            local marker = gpath(paths.mercuryTemp, "/pardone_" .. i .. ".tmp")
            table.insert(markers, marker)
            if exists(marker) then
                delete(marker)
            end
            -- `type nul >` creates/truncates the marker file (cmd built-in, no extra exe)
            table.insert(batLines,
                         'start /B "" cmd /C "' .. cmd .. ' && type nul > "' .. marker .. '""')
        end
        local batPath = gpath(paths.mercuryTemp, "/parallel_run.bat")
        writeFile(batPath, table.concat(batLines, "\r\n"))
        os.execute('"' .. batPath .. '"')

        -- Poll until every marker file is present or timeout is reached.
        -- `ping -n 2 127.0.0.1` sleeps ~1 second without needing extra tools.
        local elapsed = 0
        local allDone = false
        while elapsed < timeout do
            allDone = true
            for _, marker in ipairs(markers) do
                if not exists(marker) then
                    allDone = false
                    break
                end
            end
            if allDone then
                break
            end
            os.execute("ping -n 2 127.0.0.1 > nul")
            elapsed = elapsed + 1
        end

        -- Cleanup temp files regardless of outcome
        for _, marker in ipairs(markers) do
            if exists(marker) then
                delete(marker)
            end
        end
        delete(batPath)
        return allDone
    else
        -- Linux/macOS: wrap every command in a subshell, fork all with `&`,
        -- then use the shell built-in `wait` to block until every job exits.
        local parts = {}
        for _, cmd in ipairs(commands) do
            table.insert(parts, "(" .. cmd .. ")")
        end
        local compound = table.concat(parts, " & ") .. "; wait"
        local result = os.execute("sh -c " .. string.format("%q", compound))
        return result and true or false
    end
end

--- Compare two Mercury packages and create a diff package.
--- xdelta3 diff generation for all changed binary files is performed in
--- parallel to reduce wall-clock time on packages with many files.
---@param oldpackagePath string Path to the old package
---@param newPackagePath string Path to the new package
---@param diffPackagePath? string Path to the diff package
---@param backend? "minizip" | "unzip" | "7z" Backend to use for packing
---@return boolean
function merc.diff(oldpackagePath, newPackagePath, diffPackagePath, backend)
    local diffPackagePath = (diffPackagePath or (path.dir(newPackagePath)) .. "/") ..
                                path.nameext(newPackagePath) .. ".mercu"
    local oldExtractionPath = gpath(paths.mercuryTemp, "/", "old")
    local newExtractionPath = gpath(paths.mercuryTemp, "/", "new")
    local diffExtractionPath = gpath(paths.mercuryTemp, "/", "diff")

    local backend = backend or "minizip"
    dprint("Using backend: " .. backend)
    local implementation = backends[backend]
    if not implementation then
        error("Error invalid backend \"" .. backend .. "\".")
    end

    cprint("Extracting zip files... ", true)

    local result = implementation(oldpackagePath, oldExtractionPath, "extract")
    if not result then
        cprint("Error, at attempting to extract old package.")
        return false
    end

    result = implementation(newPackagePath, newExtractionPath, "extract")
    if not result then
        cprint("Error, at attempting to extract new package.")
        return false
    end

    cprint("done.")

    ---@type packageMercury
    local oldManifest = json.decode(readFile(oldExtractionPath .. "/manifest.json"))

    ---@type packageMercury
    local newManifest = json.decode(readFile(newExtractionPath .. "/manifest.json"))

    if not (oldManifest and newManifest and oldManifest.label == newManifest.label) then
        cprint("Error, at attempting to create diff package.")
        return false
    end

    -- Phase 1: compare files and collect xdelta3 tasks.
    -- SHA256 comparisons are sequential (fast, I/O-light); we just build the
    -- work list here so all xd3 processes can start together in Phase 2.
    ---@class DiffTask
    ---@field cmd string xdelta3 command to execute
    ---@field newFile table File entry from the new manifest
    ---@field diffFilePath string Absolute path to the expected .xd3 output

    ---@type DiffTask[]
    local diffTasks = {}

    for _, oldFile in pairs(oldManifest.files) do
        local isFileOnNewPackage = false
        for newFileIndex, newFile in pairs(newManifest.files) do
            local oldPath = gpath(oldFile.path)
            local newPath = gpath(newFile.path)
            if oldPath == newPath then
                isFileOnNewPackage = true
                if newFile.type == "binary" then
                    local oldFilePath = gpath(oldExtractionPath, "/", oldFile.path)
                    local newFilePath = gpath(newExtractionPath, "/", newFile.path)
                    local diffFilePath = gpath(diffExtractionPath, "/", newFile.path, ".xd3")

                    cprint("Searching for differences in " .. oldFile.path)
                    if SHA256(oldFilePath) ~= SHA256(newFilePath) then
                        cprint("\tWarning " .. oldPath ..
                                   " has differences between packages, queuing xd3 diff.")

                        local diffFileFolderPath = path.dir(diffFilePath)
                        if not exists(diffFileFolderPath) and
                            not createFolder(diffFileFolderPath) then
                            cprint("Error, at trying to create output diff file folder: " ..
                                       diffFileFolderPath)
                        end

                        print("\tOld file : " .. oldFilePath)
                        print("\tNew file : " .. newFilePath)
                        print("\tDiff file: " .. diffFilePath)

                        if IsDebugModeEnabled and exists(diffFilePath) then
                            dprint("Diff file already exists, skipping diff creation.")
                        else
                            local xd3Cmd = upath(constants.xd3CmdDiffLine:format(oldFilePath,
                                                                                  newFilePath,
                                                                                  diffFilePath))
                            dprint("xd3Cmd: " .. xd3Cmd)
                            table.insert(diffTasks, {
                                cmd = xd3Cmd,
                                newFile = newFile,
                                diffFilePath = diffFilePath
                            })
                        end
                    end
                    -- Remove from install files; this file will be an update entry
                    table.remove(newManifest.files, newFileIndex)
                elseif newFile.type == "optional" then
                    -- Optional files are skipped in diff packages
                    table.remove(newManifest.files, newFileIndex)
                end
                break
            end
        end
        if not isFileOnNewPackage then
            cprint("Warning file " .. oldFile.path .. " is not present on the new package.")
        end
    end

    -- Phase 2: run all collected xdelta3 diff commands in parallel.
    if #diffTasks > 0 then
        cprint("Running " .. #diffTasks .. " xdelta3 diff(s) in parallel... ", true)
        local xd3Commands = {}
        for _, task in ipairs(diffTasks) do
            table.insert(xd3Commands, task.cmd)
        end

        local parallelResult = runParallel(xd3Commands)
        if not parallelResult then
            cprint("Error, at attempting to run xd3 diff processes.")
            return false
        end
        cprint("done.")

        -- Phase 3: collect results and populate manifest updates.
        if not newManifest.updates then
            newManifest.updates = {}
        end
        for _, task in ipairs(diffTasks) do
            if exists(task.diffFilePath) then
                dprint("diffFilePath: " .. task.diffFilePath)
                dprint("diffExtractionPath: " .. diffExtractionPath)
                local relativeFilePath =
                    task.diffFilePath:replace(gpath(diffExtractionPath, "/"), "")
                dprint("relative diffFilePath: " .. relativeFilePath)
                table.insert(newManifest.updates, {
                    path = upath(task.newFile.path),
                    diffPath = upath(relativeFilePath),
                    type = task.newFile.type,
                    outputPath = upath(task.newFile.outputPath)
                })
            else
                cprint("Warning, diff file was not created for: " .. task.newFile.path)
            end
        end
    end

    -- Make sure all remaining install files use unix paths
    newManifest.files = table.map(newManifest.files, function(file)
        return {path = upath(file.path), type = file.type, outputPath = upath(file.outputPath)}
    end)

    for fileIndex, file in pairs(newManifest.files) do
        if exists(newExtractionPath .. "/" .. file.path) then
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

    if exists(diffPackagePath) then
        delete(diffPackagePath)
    end

    -- Zip the assembled diff package
    cprint("Packing update diff... ", true)
    local diffPackageZip = zip.open(diffPackagePath, "w")
    if diffPackageZip then
        diffPackageZip:add_all(diffExtractionPath)
        diffPackageZip:close()
        cprint("done.")
        return true
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
