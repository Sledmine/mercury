------------------------------------------------------------------------------
-- Combiner module
-- Sledmine
-- Function combiner for Mercury actions
------------------------------------------------------------------------------
local combiner = {}

local errorSummary = require "entities.errorSummary"

--[[
combiner.search = require "actions.search"
combiner.list = require "actions.list"
combiner.bundle = require "actions.bundler"
combiner.insert = require "actions.insert"
combiner.remove = require "actions.remove"
combiner.mitosis = require "actions.mitosis"
combiner.set = require "actions.set"
function combiner.install(packageLabel, packageVersion, forceInstallation, noBackups, update)
    if (combiner.search(packageLabel)) then
        if (forceInstallation) then
            remove(packageLabel, true, true)
        else
            cprint("Warning, package '" .. packageLabel .. "' is already installed.")
            return false
        end
    end
    local downloadResult, description, mercPath = combiner.download(packageLabel, packageVersion)
    if (not downloadResult) then
        cprint("Error, at trying to install '" .. packageLabel .. "', " .. tostring(description))
        return false
    else
        local insertResult, description = combiner.insert(mercPath, forceInstallation, noBackups)
        if (not insertResult) then
            cprint("Error, at trying to insert merc '" .. packageLabel .. "'.")
            return false
        end
    end
    -- //TODO Finish the implementation of this error object for interface purposes
    -- local test = errorSummary:new()
    cprint("Done, package '" .. packageLabel .. "' succesfully installed!")
    return true
end

function combiner.update(packageLabel)
    ---@type packageMercury
    local installedPackage = combiner.search(packageLabel)
    if (installedPackage) then
        local downloadResult, description, mercPath =
            combiner.download(installedPackage.label, installedPackage.version, true)
        if (downloadResult) then
            local insertResult, description = combiner.insert(mercPath, true)
            return insertResult
        else
            cprint("Error, at trying to update '" .. packageLabel .. "', " .. tostring(description))
            return false
        end
    end
    return false
end]]

return combiner
