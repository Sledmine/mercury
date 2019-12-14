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
local depackage = require "Mercury.actions.depackage"
local remove = require "Mercury.actions.remove"
local mitosis = require "Mercury.actions.mitosis"
local set = require "Mercury.actions.set"

local install = function (packageName, packageVersion, forceInstallation, noBackups)
    if (search(packageName)) then
        if (forceInstallation) then
            remove(packageName, true, true)
        else
            cprint("%{red bright}WARNING!!!: %{reset}Package '" .. packageName .. "' is already installed.\n")
            return false
        end
    end
    local success, description, downloadedMercs = download(packageName, packageVersion)
    if (not success) then
        cprint("\n%{red bright}ERROR!!!! %{reset}Error at trying to install '" .. packageName .. "', " .. tostring(description))
        
    else
        foreach(downloadedMercs, insert, noBackups)
    end
    return success
end

_M.search = search
_M.list = list
_M.download = download
_M.depackage = depackage
_M.install = install
_M.remove = remove

_M.mitosis = mitosis
_M.set = set

return _M