------------------------------------------------------------------------------
-- Combiner module
-- Sledmine
-- Function combiner for Mercury actions
------------------------------------------------------------------------------
local combiner = {}

combiner.search = require "Mercury.actions.search"
combiner.list = require "Mercury.actions.list"
combiner.bundle = require "Mercury.actions.bundler"
combiner.download = require "Mercury.actions.download"
combiner.insert = require "Mercury.actions.insert"
combiner.unpack = require "Mercury.actions.unpack"
combiner.remove = require "Mercury.actions.remove"
combiner.mitosis = require "Mercury.actions.mitosis"
combiner.set = require "Mercury.actions.set"

function combiner.install(packageLabel, packageVersion, forceInstallation, noBackups)
    if (combiner.search(packageLabel)) then
        if (forceInstallation) then
            remove(packageLabel, true, true)
        else
            cprint("Warning, package '" .. packageLabel .. "' is already installed.")
            return false
        end
    else
        local success, description, downloadedMercs =
            combiner.download(packageLabel, packageVersion)
        -- dprint("MERCS: " .. inspect(downloadedMercs))
        if (not success) then
            cprint("Error, at trying to install '" .. packageLabel .. "', " .. tostring(description))
        else
            -- // FIXME This is using the old dependencies implementation
            local installationResults = forEach(downloadedMercs, combiner.insert, forceInstallation,
                                                noBackups)
            dprint(installationResults)
            for index, installData in pairs(installationResults) do
                local result = installData[1]
                if (not result) then
                    cprint("Error, at trying to install '" .. packageLabel .. "' package.")
                    return false
                end
            end
            cprint("Done, package '" .. packageLabel .. "' succesfully installed!")
        end
        return success
    end
end

return combiner
