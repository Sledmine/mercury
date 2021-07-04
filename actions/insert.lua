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
    manifestError = "error at trying to read manifest.json from the package"
}

-- Install any mercury package
local function insert(mercPath, forced, skipOptionals)
    local _, mercFilename = splitPath(mercPath)
    if (exist(mercPath)) then
        -- Unpack merc file
        dprint("Trying to unpack \"" .. mercFilename .. ".merc\" ...")
        local unpackPath = gpath(paths.mercuryUnpacked, "/", mercFilename)
        if (not exist(unpackPath)) then
            
            createFolder(unpackPath)
        end
        local unpackResult = merc.unpack(mercPath, unpackPath)
        if (unpackResult) then
            -- Load package manifest data
            local manifestJson = glue.readfile(unpackPath .. "/manifest.json")
            if (not manifestJson) then
                return false, errors.manifestError
            end
            ---@type packageMercury
            local mercuryPackage = PackageMercury:new(manifestJson)

            -- Get other package dependencies
            if (mercuryPackage.dependencies) then
                cprint("Checking for package dependencies...")
                for dependencyIndex, dependency in pairs(mercuryPackage.dependencies) do
                    local existingDependency = search(dependency.label)
                    -- Check if we have this package dependency already installed
                    if (existingDependency) then
                        -- A specific package dependency was specified
                        if (dependency.version) then
                            -- Check semantic version
                            if (v(existingDependency.version) < v(dependency.version)) then
                                --  TODO Allow user to decide for this step
                                cprint(
                                    "Warning, removing older dependency to install newer required dependency \"" ..
                                        dependency.label .. "-" .. dependency.version ..
                                        "\"")
                                --  TODO Add skip optionals to remove action
                                local result, error = remove(dependency.label, true)
                                if (not result) then
                                    remove(dependency.label, false, false, false, true)
                                end
                                result, error =
                                    install.package(dependency.label, dependency.version)
                                if (not result) then
                                    return false, errors.depedencyError
                                end
                            else
                                cprint("Warning, dependency installation for \"" ..
                                           dependency.label .. "-" .. dependency.version ..
                                           "\" is being skipped because there is a newer or equal version already installed.")
                            end
                        end
                    else
                        local result, error =
                            install.package(dependency.label, dependency.version, false,
                                            false)
                        if (not result) then
                            return false, errors.depedencyError
                        end
                    end
                end
            end

            -- Insert new files into the game
            if (mercuryPackage.files) then
                cprint("Inserting " .. mercFilename .. " files... ")
                for fileIndex, file in pairs(mercuryPackage.files) do
                    if (file.type == "optional" and skipOptionals) then
                        cprint("Warning, skipping optional file: \"" .. file.path .. "\".")
                        goto continue
                    end

                    -- File path from mercury unpack path
                    local inputFile = unpackPath .. "/" .. file.path
                    -- File path for insertion
                    local outputFile = file.outputPath .. file.path
                    local outputFilePath = splitPath(outputFile)

                    -- Create folder for current file
                    if (not exist(outputFilePath)) then
                        createFolder(outputFilePath)
                    end

                    dprint("Inserting file \"" .. file.path .. "\" ...")
                    dprint("Output: \"" .. outputFile .. "\" ...")

                    if (exist(outputFile)) then
                        if (forced or mercuryPackage.updates) then
                            if (not mercuryPackage.updates) then
                                cprint(
                                    "Warning, forced mode was enabled, erasing conflict file: \"" ..
                                        file.path .. "\"... ", true)
                            end
                            local result, desc, error = delete(outputFile)
                            if (result) then
                                if (not mercuryPackage.updates) then
                                    cprint("done.")
                                end
                            else
                                cprint("Error, at trying to erase file: '" .. file.path ..
                                           "'")
                                return false, errors.eraseFileError
                            end
                        else
                            cprint("Warning, creating backup for conflict file: \"" ..
                                       file.path .. "\"... ", true)
                            local result, desc, error =
                                move(outputFile, outputFile .. ".bak")
                            if (result) then
                                cprint("done.")
                            else
                                cprint("Error, at trying to create a backup for: '" ..
                                           file.path)
                                return false, errors.backupCreationError
                            end
                        end
                    end

                    -- Copy file into game folder
                    if (copyFile(inputFile, outputFile)) then
                        dprint("File succesfully installed.")
                        dprint(outputFile)
                    else
                        cprint("Error, at trying to install file: '" .. file.path .. "'")
                        return false, errors.installationError
                    end
                    ::continue::
                end
            end

            -- Apply updates to files if available
            if (mercuryPackage.updates) then
                for fileIndex, file in pairs(mercuryPackage.updates) do
                    cprint("Updating " .. file.path .. " ... ", true)
                    -- File update from mercury unpack path
                    local diffFilePath = unpackPath .. "\\" .. file.diffPath
                    -- File path for insertion
                    local sourceFilePath = file.outputPath .. file.path
                    -- File path for temp updated file
                    local updatedFilePath = sourceFilePath .. ".updated"

                    dprint("diffFilePath: " .. diffFilePath)
                    dprint("sourceFilePath: " .. sourceFilePath)
                    dprint("updatedFilePath: " .. updatedFilePath)

                    if (file.type == "binary" or file.type == "text") then
                        -- Update file using xdelta3
                        local xd3CmdLine = constants.xd3CmdLine
                        local xd3Cmd = xd3CmdLine:format(sourceFilePath, diffFilePath,
                                                         updatedFilePath)
                        dprint("xd3Cmd: " .. xd3Cmd)

                        --  TODO Append validation for update command
                        local xd3Result = os.execute(xd3Cmd)
                        if (exist(updatedFilePath)) then
                            --  TODO Add validation for these operations
                            -- Rename updated file to source file
                            local oldFilePath = sourceFilePath .. ".old"
                            move(sourceFilePath, oldFilePath)
                            move(updatedFilePath, sourceFilePath)
                            delete(oldFilePath)
                            cprint("done.")
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
            if (mercuryPackage.updates) then
                -- TODO Check out this, there are probably better ways to do this
                local updateProps = mercuryPackage:getProperties()
                updateProps.updates = mercuryPackage.updates

                local oldProps = installedPackages[mercuryPackage.label]

                if (updateProps.files) then
                    glue.extend(oldProps.files, updateProps.files)
                end

                -- Remove updates property from the final package properties
                updateProps.updates = nil
                installedPackages[mercuryPackage.label] =
                    glue.update(oldProps, updateProps)
            else
                installedPackages[mercuryPackage.label] = mercuryPackage:getProperties()
            end
            -- Update current environment packages data with the new one
            environment.packages(installedPackages)
            return true
        end
    end
    cprint("Error, " .. mercPath .. " does not exist.")
    return false, errors.mercFileDoesNotExist
end

return insert
