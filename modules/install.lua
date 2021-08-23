local install = {}

-- Actions
local search = require "Mercury.actions.search"
local remove = require "Mercury.actions.remove"
local insert = require "Mercury.actions.insert"

-- Modules
local download = require "Mercury.modules.download"

-- Entities
local PackageMetadata = require "Mercury.entities.packageMetadata"

local errors = {
    ["404"] = "file or package not found for download",
    ["403"] = "access denied, you do not have required permissions",
    ["connection refused"] = "no connection to repository",
    ["download error"] = "an error occurred while downloading",
    ["invalid host"] = "package host is invalid",
    ["no update warning"] = "there are no updates available for this package"
}

local function getError(status)
    --  TODO: Add better error array handling
    if (type(status) == "table") then
        status = status[1]
    end
    local errorDescription = errors[tostring(status)] or status or "unknown error"
    dprint(status)
    if (type(status) == "string" and status:find("warning")) then
        cprint("Warning, " .. errorDescription .. ".")
    else
        cprint("Error, " .. errorDescription .. ".")
    end
    return false, errorDescription
end

--- Attempt to install a package with the requrired operations
---@param packageLabel string Label of the package to install
---@param packageVersion string Version of the package to install
---@param forced bool Forced mode installation
---@param skipOptionals bool Ignore optional files at installation
---@param skipDependencies bool Ignore dependencies at installation
---@return boolean result
function install.package(packageLabel,
                         packageVersion,
                         forced,
                         skipOptionals,
                         skipDependencies)
    if (search(packageLabel)) then
        if (forced) then
            remove(packageLabel, true, true)
        else
            cprint("Warning, package \"" .. packageLabel .. "\" is already installed.")
            return false
        end
    end
    -- Create local variables before implementation, it can be used to avoid too much else if
    local status, result, response
    status, response = api.getPackage(packageLabel, packageVersion)
    if (status == 200 and response) then
        local meta = PackageMetadata:new(response)
        if (meta and meta.mirrors) then
            cprint("Found version " .. meta.version .. ".")
            dprint("Package metadata:")
            dprint(meta)
            local packagePath
            status, packagePath = download.package(meta)
            if (status == 200) then
                result, status = insert(packagePath, forced, skipOptionals)
                if (result) then
                    cprint("Success, package \"" .. packageLabel .. "\" has been installed.")
                    return true
                end
            end
        end
    end
    return false, getError(status)
end

function install.update(packageLabel)
    local currentPackage = search(packageLabel)
    if (not currentPackage) then
        cprint("Error, package \"" .. packageLabel .. "\" is not installed.")
        return false
    end
    -- Create local variables before implementation, it can be used to avoid too much else if
    local status, result, response
    status, response = api.getPackage(packageLabel, currentPackage.version)
    if (status == 200 and response) then
        local meta = PackageMetadata:new(response)
        if (meta and meta.nextVersion) then
            cprint("done. Found version " .. meta.nextVersion .. ".")
            dprint("Package metadata:")
            dprint(meta)
            status, response = api.getUpdate(packageLabel, meta.nextVersion)
            if (status == 200 and response) then
                local updateMeta = PackageMetadata:new(response)
                local packagePath
                status, packagePath = download.package(updateMeta)
                if (status == 200) then
                    result, status = insert(packagePath)
                    if (result) then
                        cprint("Success, package \"" .. packageLabel .. "\" has been updated.")
                        return true
                    end
                end
            end
        else
            status = "no update warning"
        end
    end
    return false, getError(status)
end

return install
