------------------------------------------------------------------------------
-- Insert
-- Sledmine
-- Insert all the files from a Mercury Package into the game
------------------------------------------------------------------------------
local json = require "cjson"
local glue = require "glue"
local v = require "semver"

local constants = require "Mercury.modules.constants"
local merc = require "Mercury.modules.merc"
local paths = environment.paths()

local search = require "Mercury.actions.search"
local remove = require "Mercury.actions.remove"

local PackageMercury = require "Mercury.entities.packageMercury"

local errors = {
    eraseFileError = "an error ocurred at erasing some files",
    backupCreationError = "an error ocurred at creating a backup file",
    installationError = "at trying to install a package",
    updateError = "at trying to update a file",
    depedencyError = "at trying to install a package dependency",
    mercFileDoesNotExist = "mercury local package does not exist",
    noManifest = "at trying to read manifest.json from the package",
    updatingPackagesIndex = "at trying to update the packages index",
}

-- Install any mercury package
local function insert(mercPath, forced, skipOptionals)
    if exists(mercPath) then
        local _, mercFilename = splitPath(mercPath)
        -- Unpack merc file
        dprint("Trying to unpack \"" .. mercFilename .. ".merc\" ...")
        local unpackPath = gpath(paths.mercuryUnpacked, "/", mercFilename)
        if (not exists(unpackPath)) then
            createFolder(unpackPath)
        end
        if (merc.unpack(mercPath, unpackPath)) then
            -- Load package manifest data
            local manifestPath = gpath(unpackPath, "/manifest.json")
            local manifestJson = readFile(manifestPath)
            if (not manifestJson) then
                return false, errors.noManifest
            end
            ---@type packageMercury
            local package = PackageMercury:new(manifestJson)
            dprint("Package:")
            dprint(package)
            -- Get other package dependencies
            if (package.dependencies) then
                cprint("Checking package dependencies...")
                for dependencyIndex, dependency in pairs(package.dependencies) do
                    local existingDependency = search(dependency.label)
                    -- Check if we have this package dependency already installed
                    if (existingDependency) then
                        -- Specific dependency was specified, check semantic version
                        if (dependency.version and v(existingDependency.version) <
                            v(dependency.version)) then
                            --  TODO Allow user to decide for this step
                            cprint("Warning, newer dependency is required, removing old one \"" ..
                                       dependency.label .. "-" .. dependency.version .. "\"")
                            --  TODO Add skip optionals to remove action
                            local result, error = remove(dependency.label, true)
                            if (not result) then
                                remove(dependency.label, false, false, false, true)
                            end
                            result, error = install.package(dependency.label, dependency.version)
                            if (not result) then
                                return false, errors.depedencyError
                            end
                        else
                            if (dependency.version) then
                                cprint("Warning, dependency \"" .. dependency.label .. "-" ..
                                           dependency.version ..
                                           "\" is being skipped, newer or equal dependency is already installed.")
                            else
                                -- FIXME This can be innacurate sometimes depending on dependency version required
                                cprint("Warning, dependency \"" .. dependency.label ..
                                           "\" is already installed.")
                            end
                        end
                    else
                        -- Dependency is not installed, go and get it
                        local result, error = install.package(dependency.label, dependency.version,
                                                              false, false)
                        if (not result) then
                            return false, errors.depedencyError
                        end
                    end
                end
            end

            -- Insert new files into the game
            if (package.files) then
                cprint("Inserting " .. mercFilename .. " files... ")
                for fileIndex, file in pairs(package.files) do
                    if (file.type == "optional" and skipOptionals) then
                        cprint("Warning, skipping optional file: \"" .. file.path .. "\".")
                        goto continue
                    end

                    -- Source file path from mercury unpack path
                    local inputFilePath = gpath(unpackPath, "/", file.path)
                    -- Normalized final insert output file path
                    local outputFile = file.outputPath
                    -- Final output file folder
                    local outputFileFolder = splitPath(outputFile)
                    -- Create folder for current file
                    if (not exists(outputFileFolder)) then
                        createFolder(outputFileFolder)
                    end
                    dprint("Inserting file \"" .. file.path .. "\" ...")
                    dprint("Input, \"" .. inputFilePath .. "\" ...")
                    dprint("Output, \"" .. outputFile .. "\" ...")
                    if (exists(outputFile)) then
                        if (forced or package.updates) then
                            if (not package.updates) then
                                cprint(
                                    "Warning, forced mode was enabled, erasing conflict file: \"" ..
                                        file.path .. "\"... ", true)
                            end
                            local result, desc, error = delete(outputFile)
                            if (result) then
                                if (not package.updates) then
                                    cprint("done.")
                                end
                            else
                                cprint("Error, at trying to erase \"" .. file.path .. "\"")
                                return false, errors.eraseFileError
                            end
                        else
                            cprint("Warning, creating backup for conflict file: \"" .. file.path ..
                                       "\"... ", true)
                            local result, desc, error = move(outputFile, outputFile .. ".bak")
                            if (result) then
                                cprint("done.")
                            else
                                cprint("Error, at trying to create a backup for: \"" .. file.path .. "\"")
                                return false, errors.backupCreationError
                            end
                        end
                    end

                    -- Copy file into game folder
                    local copied, reason = copyFile(inputFilePath, outputFile)
                    if copied then
                        dprint("Done, file succesfully installed.")
                    else
                        cprint("Error, at trying to install file: \"" .. file.path .. "\"")
                        if reason then
                            cprint("Reason: " .. reason)
                        end
                        return false, errors.installationError
                    end
                    ::continue::
                end
            end

            -- Apply updates to files if available
            if (package.updates) then
                for fileIndex, file in pairs(package.updates) do
                    cprint("Updating \"" .. file.path .. "\" ... ", true)
                    -- File update from mercury unpack path
                    local diffFilePath = gpath(unpackPath, "/", file.diffPath)
                    -- Normalized final insert output file path
                    local sourceFilePath = file.outputPath

                    -- File path for temp updated file
                    dprint("sourceFilePath: " .. sourceFilePath)
                    dprint("diffFilePath: " .. diffFilePath)
                    local updatedFilePath = sourceFilePath .. ".updated"
                    dprint("updatedFilePath: " .. updatedFilePath)

                    if (file.type == "binary" or file.type == "text") then
                        -- Update file using xdelta3
                        local xd3CmdLine = constants.xd3CmdLine
                        local xd3Cmd = xd3CmdLine:format(sourceFilePath, diffFilePath,
                                                         updatedFilePath)
                        dprint("xd3Cmd: " .. xd3Cmd)

                        --  TODO Add validation for update command
                        local xd3Result = run(xd3Cmd)
                        if (exists(updatedFilePath)) then
                            -- Prepare a temp file name to replace it with the updated one
                            local oldFilePath = sourceFilePath .. ".old"
                            -- Move updated file to source file path
                            if (move(sourceFilePath, oldFilePath) and
                                move(updatedFilePath, sourceFilePath) and delete(oldFilePath)) then
                                cprint("done.")
                            else
                                cprint("Error, at performing old files removal")
                                return false, errors.eraseFileError
                            end
                        else
                            cprint("Error, at updating \"" .. file.path .. "\"")
                            return false, errors.updateError
                        end
                    end
                end
            end

            -- Get current instance packages
            local installedPackages = environment.packages() or {}
            -- Substract required package properties and store them
            if (package.updates) then
                -- TODO Check out this, there are probably better ways to do it
                local updateProps = package:getProperties()
                updateProps.updates = package.updates

                local oldProps = installedPackages[package.label]

                if (updateProps.files) then
                    glue.extend(oldProps.files, updateProps.files)
                end

                -- Remove updates property from the final package properties
                updateProps.updates = nil
                installedPackages[package.label] = glue.update(oldProps, updateProps)
            else
                installedPackages[package.label] = package:getProperties()
            end
            -- Update current environment packages data with the new one
            if not environment.packages(installedPackages) then
                return false, errors.updatingPackagesIndex
            end
            return true
        end
    end
    cprint("Error, " .. mercPath .. " does not exist.")
    return false, errors.mercFileDoesNotExist
end

return insert
