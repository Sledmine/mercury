------------------------------------------------------------------------------
-- Combiner: Function combiner for Mercury actions
-- Authors: Sledmine
-- Version: 1.0
------------------------------------------------------------------------------
local _M = {}

require "Mercury.lib.utilis"

local search = require "Mercury.actions.search"
local list = require "Mercury.actions.list"
local download = require "Mercury.actions.download"
local insert = require "Mercury.actions.insert"
local unpack = require "Mercury.actions.unpack"
local remove = require "Mercury.actions.remove"
local mitosis = require "Mercury.actions.mitosis"
local set = require "Mercury.actions.set"

local install = function(packageLabel, packageVersion, forceInstallation, noBackups)
    if (search(packageLabel)) then
        if (forceInstallation) then
            remove(packageLabel, true, true)
        else
            cprint("Package '" .. packageLabel .. "' is ALREADY installed.\n")
            return false
        end
    end
    local success, description, downloadedMercs = download(packageLabel, packageVersion)
    if (not success) then
        cprint("Error at trying to install '" .. packageLabel .. "', " .. tostring(description))
    else
        local installationResults = foreach(downloadedMercs, insert, forceInstallation, noBackups)
        for k, v in pairs(installationResults) do
            if (not v) then
                cprint("Error at installing files for '" .. packageLabel .. "'")
                cprint("Error at trying to install '" .. packageLabel .. "'")
                return false
            end
        end
        cprint("Package '" .. packageLabel .. "' succesfully installed!!")
    end
    return success
end

_M.search = search
_M.list = list
_M.download = download
_M.unpack = unpack
_M.install = install
_M.remove = remove

_M.mitosis = mitosis
_M.set = set

return _M
