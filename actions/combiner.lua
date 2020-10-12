------------------------------------------------------------------------------
-- Combiner module
-- Sledmine
-- Function combiner for Mercury actions
------------------------------------------------------------------------------
local combiner = {}

local errorSummary = require "Mercury.entities.errorSummary"

combiner.search = require "Mercury.actions.search"
combiner.list = require "Mercury.actions.list"
combiner.bundle = require "Mercury.actions.bundler"
combiner.download = require "Mercury.actions.download"
combiner.insert = require "Mercury.actions.insert"
combiner.unpack = require "Mercury.actions.unpack"
combiner.remove = require "Mercury.actions.remove"
combiner.mitosis = require "Mercury.actions.mitosis"
combiner.set = require "Mercury.actions.set"

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
    return downloadResult

end

function combiner.update(packageLabel)
    local installedPackage = combiner.search(packageLabel)
    if (installedPackage) then
        combiner.install(packageLabel)
    end
end

return combiner
