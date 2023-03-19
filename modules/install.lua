local json = require "cjson"

local install = {}

-- Actions
local search = require "actions.search"
local remove = require "actions.remove"
local insert = require "actions.insert"

-- Modules
local download = require "modules.download"

local errors = {
    ["404"] = "file, package or update not found for download",
    ["403"] = "access denied, you do not have required permissions",
    ["connection refused"] = "no connection to repository",
    ["download error"] = "an error occurred while downloading",
    ["invalid host"] = "package host is invalid",
    ["no update warning"] = "there are no updates available for this package"
}

local function getError(status)
    if (type(status) == "table") then
        status = table.concat(status, ", ")
    end
    local errorDescription = errors[tostring(status)] or status or "unknown error"
    dprint(status)
    if (type(status) == "string" and status:find("warning")) then
        cprint("Warning " .. errorDescription .. ".")
    else
        cprint("Error " .. errorDescription .. ".")
    end
    return false, errorDescription
end

--- Attempt to install a package with the requrired operations
---@param packageLabel string Label of the package to install
---@param packageVersion string Version of the package to install
---@param forced boolean Forced mode installation
---@param skipOptionals boolean Ignore optional files at installation
---@param skipDependencies boolean Ignore dependencies at installation
---@return boolean, string? result
function install.package(packageLabel,
                         packageVersion,
                         forced,
                         skipOptionals,
                         skipDependencies)
    if (search(packageLabel)) then
        if (forced) then
            remove(packageLabel, true, true)
        else
            cprint("Warning package \"" .. packageLabel .. "\" is already installed.")
            return false
        end
    end
    -- Create local variables before implementation, it can be used to avoid too much else if
    local result
    local meta = api.getPackage(packageLabel, packageVersion)
    if meta and meta.mirrors then
        cprint("Downloading " .. packageLabel .. "-" .. meta.version .. "...")
        local packagePath
        status, packagePath = download.package(meta)
        if status == 200 then
            result, status = insert(packagePath, forced, skipOptionals)
            if result then
                cprint("Done package " .. packageLabel .. " has been installed.")
                return true
            end
        end
    end
    return getError(status)
end

function install.update(packageLabel, silent)
    local currentPackage = search(packageLabel)
    if not currentPackage then
        cprint("Error package \"" .. packageLabel .. "\" is not installed.")
        return false
    end
    -- Create local variables before implementation, it can be used to avoid too much else if
    local status, result
    local meta = api.getUpdate(packageLabel, currentPackage.version)
    if meta and meta.mirrors then
        cprint("Downloading update to " .. packageLabel .. "-" .. meta.version .. "...")
        local updatePath
        status, updatePath = download.package(meta)
        if status == 200 then
            result, status = insert(updatePath)
            if result then
                if not install.update(packageLabel, true) then
                    cprint("Done package " .. packageLabel .. " updated to version " ..
                               meta.version .. ".")
                end
                return true
            end
        end
    else
        status = "no update warning"
    end
    if silent then
        return false, status
    end
    return false, getError(status)
end

return install
