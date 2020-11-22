------------------------------------------------------------------------------
-- Remove action
-- Authors: Sledmine
-- Remove any mercury package
------------------------------------------------------------------------------
local json = require "cjson"
local glue = require "glue"

local search = require("Mercury.actions.search")

--- Remove/uninstall a package from the game
---@param packageLabel string
---@param noRestore boolean
---@param eraseBackups boolean
---@param recursive boolean
local function remove(packageLabel, noRestore, eraseBackups, recursive)
    ---@type packageMercury[]
    if (search(packageLabel)) then
        local installedPackages = environment.packages()
        cprint("Removing package '" .. packageLabel .. "'...")
        ---@type packageMercury
        local packageMercury = installedPackages[packageLabel]
        -- Remove dependencies recursively
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
            dprint("Erasing '" .. fileName .. "'... ", true)
            local result, description, errorCode = delete(filePath)
            if (result) then
                dprint("Done, file erased.")
                if (exist(filePath .. ".bak") and not noRestore) then
                    if (not noRestore) then
                        cprint("Warning, restoring '" .. fileName .. "' backup file... ", true)
                        move(filePath .. ".bak", filePath)
                        if (exist(filePath)) then
                            cprint("done.")
                        else
                            cprint("Error, at trying to restore backup file.")
                        end
                    end
                    if (eraseBackups) then
                        cprint("Warning, Backups erase enabled deleting file now... ", true)
                        delete(filePath .. ".bak")
                        if (exist(filePath)) then
                            cprint("Error, at trying to delete backup file.")
                        else
                            cprint("done.")
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
        -- Get current instance packages
        local installedPackages = environment.packages() or {}
        -- Erase data for this package
        installedPackages[packageLabel] = nil
        -- Update current environment packages data with the new one
        environment.packages(installedPackages)
        cprint("Done, package '" .. packageLabel .. "' has been removed.")
        return true
    end
    cprint("Warning, package '" .. packageLabel .. "' is not installed.")
    return false
end

return remove
