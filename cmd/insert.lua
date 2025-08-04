------------------------------------------------------------------------------
-- Insert
-- Sledmine
-- Insert all the files from a Mercury Package into the game
------------------------------------------------------------------------------
local glue = require "glue"
local v = require "semver"

local constants = require "modules.constants"
local merc = require "modules.merc"
local paths = config.paths()

local search = require "cmd.search"
local remove = require "cmd.remove"

local PackageMercury = require "entities.packageMercury"

local errors = {
    eraseFileError = "an error ocurred at erasing some files",
    backupCreationError = "an error ocurred at creating a backup file",
    installationError = "at trying to install a package",
    updateError = "at trying to update a file",
    depedencyError = "at trying to install a package dependency",
    mercFileDoesNotExist = "mercury local package does not exist",
    noManifest = "at trying to read manifest.json from the package",
    updatingPackagesIndex = "at trying to update the packages index",
    unpackingMercFile = "at trying to unpack mercury package",
    moveError = "at trying to move a file"
}

-- Install any mercury package
---@param mercPath string Path to mercury package
---@param forced? boolean Force installation
---@param skipOptionals? boolean Skip optional files
---@param skipDependencies? boolean Skip dependencies
local function insert(mercPath, forced, skipOptionals, skipDependencies)
    if not exists(mercPath) then
        cprint("Error, " .. mercPath .. " does not exist.")
        return false, errors.mercFileDoesNotExist
    end
    local _, mercFilename = splitPath(mercPath)
    -- Unpack merc file
    local unpackPath = gpath(paths.mercuryUnpacked, "/", mercFilename)
    if not exists(unpackPath) then
        createFolder(unpackPath)
    end
    if not merc.unpack(mercPath, unpackPath, "7z") then
        cprint("Error at unpacking " .. mercFilename .. " zip.")
        return false, errors.unpackingMercFile
    end

    -- Load package manifest data
    local manifestPath = gpath(unpackPath, "/manifest.json")
    local manifestJson = readFile(manifestPath)
    if not manifestJson then
        return false, errors.noManifest
    end

    ---@type packageMercury
    local package = PackageMercury:new(manifestJson)
    dprint("Package:")
    dprint(package)

    if not skipDependencies then
        local dependenciesToGet = package.dependencies or {}
        -- Get other package dependencies
        dependenciesToGet = table.filter(dependenciesToGet, function(dependency)
            return not search(dependency.label)
        end)
        local dependencyTree = table.map(dependenciesToGet, function(dependency)
            return dependency.label .. (dependency.version and ("-" .. dependency.version) or "")
        end)
        if #dependenciesToGet > 0 then
            cprint("Getting " .. package.label .. " dependencies:")
            printTree(dependencyTree)
        end

        -- Use another ref for dependencies to avoid replacing metadata from package
        local dependencies = package.dependencies or {}
        for dependencyIndex, dependency in pairs(dependencies) do
            local existingDependency = search(dependency.label)
            -- Check if we have this package dependency already installed
            if not existingDependency then
                -- Dependency is not installed, go and get it
                if not install.package(dependency.label, dependency.version, false, false) then
                    return false, errors.depedencyError
                end
                goto continue
            end
            -- Specific version was specified
            if existingDependency and dependency.version then
                local vExisting = v(existingDependency.version)
                local vRequired = v(dependency.version)
                -- Specific dependency was specified, check semantic version
                local isDependencyRequired = (vExisting < vRequired) or dependency.forced
                if isDependencyRequired then
                    cprint("Upgrading " .. dependency.label .. " " .. existingDependency.version ..
                               " -> " .. dependency.version)
                    if not remove(dependency.label, true, false, false, false, true) then
                        -- Try to remove dependency by force/index
                        remove(dependency.label, false, false, false, true)
                    end
                    if not install.package(dependency.label, dependency.version, false, true) then
                        return false, errors.depedencyError
                    end
                end
            end
            ::continue::
        end
    end

    -- Insert new files into the game
    if package.files then
        dprint("Copying files to game folders... ")
        for fileIndex, file in pairs(package.files) do
            if file.type == "optional" and skipOptionals then
                cprint("Warning skipping optional file: \"" .. file.path .. "\".")
                goto continue
            end

            -- Source file path from mercury unpack path
            local inputFilePath = gpath(unpackPath, "/", file.path)
            -- Normalized final insert output file path
            local outputFile = file.outputPath
            -- Final output file folder
            local outputFileFolder = splitPath(outputFile) --[[@as string]]
            -- Create folder for current file
            if not exists(outputFileFolder) then
                dprint("Creating folder \"" .. outputFileFolder .. "\"")
                createFolder(outputFileFolder)
            end
            dprint("Inserting file \"" .. file.path .. "\"\n")
            dprint("Input -> \"" .. inputFilePath .. "\"")
            dprint("Output -> \"" .. outputFile .. "\"")

            -- File already exists, check if we need to erase it or backup it
            if exists(outputFile) then
                if forced or package.updates then
                    if not package.updates then
                        cprint("Warning erasing conflict file: \"" .. file.path .. "\"... ", true)
                    end
                    local isDeleted, description, error = delete(outputFile)
                    if not isDeleted then
                        cprint("Error erasing \"" .. file.path .. "\"")
                        cprint("Reason: " .. tostring((description or error or "unknown")))
                        return false, errors.eraseFileError
                    end
                    if not package.updates then
                        cprint("done.")
                    end
                else
                    cprint("Backup conflict file \"" .. file.path .. "\"... ", true)
                    local isMoved, description, error = move(outputFile, outputFile .. ".bak")
                    if not isMoved then
                        cprint("Error creating backup for: \"" .. file.path .. "\"")
                        cprint("Reason: " .. tostring((description or error or "unknown")))
                        return false, errors.backupCreationError
                    end
                    cprint("done.")
                end
            end

            -- Copy file into game folder
            local isCopied, reason = copyFile(inputFilePath, outputFile)
            if not isCopied then
                cprint("Error at trying to install file: \"" .. file.path .. "\"")
                if reason then
                    cprint("Reason: " .. reason)
                end
                return false, errors.installationError
            end
            dprint("Done, file succesfully installed.")
            ::continue::
        end
    end

    -- Apply updates to files if available
    if package.updates then
        cprint("Updating files from game folders... ")
        for fileIndex, file in pairs(package.updates) do
            cprint("Updating \"" .. file.path .. "\"... ", true)
            -- File update from mercury unpack path
            local diffFilePath = gpath(unpackPath, "/", file.diffPath)
            -- Normalized final insert output file path
            local sourceFilePath = file.outputPath

            -- File path for temp updated file
            dprint("sourceFilePath: " .. sourceFilePath)
            dprint("diffFilePath: " .. diffFilePath)
            local updatedFilePath = sourceFilePath .. ".updated"
            dprint("updatedFilePath: " .. updatedFilePath)

            if file.type == "binary" or file.type == "text" then
                -- Update file using xdelta3
                local xd3CmdLine = constants.xd3CmdLine
                local xd3Cmd = xd3CmdLine:format(sourceFilePath, diffFilePath, updatedFilePath)
                dprint("xd3Cmd: " .. xd3Cmd)

                local isFileUpdated = run(xd3Cmd)
                if not (isFileUpdated and exists(updatedFilePath)) then
                    cprint("Error, at updating \"" .. file.path .. "\"")
                    return false, errors.updateError
                end

                -- TODO Move this to the end of the process so we can move updated files to
                -- source file path and delete old files if all other files were updated succesfully

                -- Prepare a temp file name to replace it with the updated one
                local oldFilePath = sourceFilePath .. ".old"
                -- Move updated file to source file path
                if not (move(sourceFilePath, oldFilePath) and move(updatedFilePath, sourceFilePath) and
                    delete(oldFilePath)) then
                    cprint("Error removing old files")
                    return false, errors.eraseFileError
                end
                cprint("done.")
            end
        end
    end

    if package.moves then
        cprint("Moving files from game folders... ")
        for _, file in pairs(package.moves) do
            if exists(file.fromPath) then
                local directory = splitPath(file.toPath)
                dprint("directory: " .. directory)
                assert(directory, "Error getting directory from path: " .. file.toPath)
                createFolder(directory)
                cprint("Moving \"" .. file.fromPath .. "\" to \"" .. file.toPath .. "\"... ")
                if not move(file.fromPath, file.toPath) then
                    if file.required then
                        cprint("Error moving \"" .. file.fromPath .. "\" to \"" .. file.toPath)
                        return false, errors.moveError
                    else
                        cprint("Warning file \"" .. file.fromPath .. "\" was not moved")
                    end
                end
            end
        end
    end

    if package.deletes then
        cprint("Deleting non-required files from game folders... ")
        for _, file in pairs(package.deletes) do
            if not delete(file.path) then
                if file.required then
                    cprint("Error deleting required file \"" .. file.path .. "\"")
                    return false, errors.eraseFileError
                end
            end
        end
    end

    -- Get current instance packages
    local installedPackages = config.packages() or {}

    if package.removes then
        cprint("Attempting to remove conflicting packages... ")
        for _, package in pairs(package.removes) do
            local packageLabel
            if type(package) == "string" then
                packageLabel = package
            else
                packageLabel = package.label
            end
            if installedPackages[packageLabel] then
                if not remove(packageLabel, true, false, false, false, true) then
                    cprint("Error removing \"" .. package .. "\"")
                    return false, errors.depedencyError
                end
            end
        end
    end

    -- Refresh installed packages data
    installedPackages = config.packages() or installedPackages

    -- Substract required package properties and store them
    if package.updates then
        -- TODO Check out this, there are probably better ways to do it
        local updateProps = package:getProperties()
        updateProps.updates = package.updates

        local oldProps = installedPackages[package.label]

        if updateProps.files then
            glue.extend(oldProps.files, updateProps.files)
        end

        -- Remove updates property from the final package properties
        updateProps.updates = nil
        installedPackages[package.label] = glue.update(oldProps, updateProps)
    else
        installedPackages[package.label] = package:getProperties()
    end
    -- Update current environment packages data with the new one
    if not config.packages(installedPackages) then
        return false, errors.updatingPackagesIndex
    end
    return true
end

return insert
