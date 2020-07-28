------------------------------------------------------------------------------
-- Remove action
-- Authors: Sledmine
-- Remove any mercury package
------------------------------------------------------------------------------
local json = require("cjson")
local glue = require("glue")

local search = require "Mercury.actions.search"

--- Remove/uninstall a package from the game
---@param packageLabel string
---@param noRestore boolean
---@param eraseBackups boolean
---@param recursive boolean
local function remove(packageLabel, noRestore, eraseBackups, recursive)
    ---@type packageMercury[]
    local installedPackages = environment.packages()
    if (installedPackages and search(packageLabel)) then
        cprint("Removing package '" .. packageLabel .. "'...")
        ---@type packageMercury
        local packageMercury = installedPackages[packageLabel]
        if (recursive) then
            cprint("Warning, remove is in recursive mode.")
            local packageDependencies = packageMercury.dependencies
            if (packageDependencies and #packageDependencies > 0) then
                for dependency in each(packageDependencies) do
                    remove(dependency.label, noRestore, eraseBackups, recursive)
                end
            end
        end
        for fileName, path in pairs(packageMercury.files) do
            local filePath = path .. fileName
            -- Start erasing proccess
            dprint("Erasing '" .. fileName .. "'...")
            local result, description, errorCode = deleteFile(filePath)
            if (result) then
                dprint("Done, file erased.")
                if (fileExist(filePath .. ".bak") and not noRestore) then
                    if (not noRestore) then
                        cprint("Warning, backup file found, restoring file now...")
                        move(filePath .. ".bak", filePath)
                        if (fileExist(filePath)) then
                            cprint("Done, file succesfully restored.")
                        else
                            cprint("Error, at trying to restore backup file.")
                        end
                    end
                    if (eraseBackups) then
                        cprint("Warning, Backups erase enabled, deleting file now...")
                        deleteFile(filePath .. ".bak")
                        if (fileExist(filePath)) then
                            cprint("Error, at trying to delete backup file.")
                        else
                            cprint("Done, file succesfully deleted.")
                        end
                    end
                end
            else
                if (errorCode == 2 or errorCode == 3) then
                    cprint("Warning, erase file not found, probably misplaced or previously removed")
                else
                    cprint("Error, at trying to erase file.")
                    cprint("Reason, '" .. description .. "' aborting uninstallation now!")
                    return false
                end
            end
        end
        installedPackages[packageLabel] = nil
        environment.packages(installedPackages)
        cprint("Done, package '" .. packageLabel .. "' has been removed.")
        return true
    end
    cprint("Warning, package '" .. packageLabel .. "' is not installed.")
    return false
end

return remove
