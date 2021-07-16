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
    ["404"] = "package not found",
    ["connection refused"] = "no connection to repository",
    ["download error"] = "an error occurred while downloading",
    ["invalid host"] = "package host is invalid",
    ["no update"] = "there is no update available for this package"
}

local function getError(error)
    --  TODO: Add better error array handling
    if (type(error) == "table") then
        error = error[1]
    end
    local errorDescription = errors[tostring(error)] or error or "unknown error"
    dprint(error)
    cprint("Error, " .. errorDescription .. ".")
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
    cprint("Searching for \"" .. packageLabel .. "\" in repository... ", true)
    -- Create local variables before implementation, it can be used to avoid too much else if
    local error, result, response
    error, response = api.getPackage(packageLabel, packageVersion)
    if (error == 200 and response) then
        local packageMeta = PackageMetadata:new(response)
        if (packageMeta and packageMeta.mirrors) then
            cprint("done. Found version " .. packageMeta.version .. ".")
            dprint("Package metadata:")
            dprint(packageMeta)
            local result, packagePath = download.package(packageMeta)
            if (result) then
                result, error = insert(packagePath, forced, skipOptionals)
                if (result) then
                    cprint("Success, package \"" .. packageLabel .. "\" has been installed.")
                    return true
                end
            end
        end
    end
    return false, getError(error)
end

function install.update(packageLabel)
    local currentPackage = search(packageLabel)
    if (not currentPackage) then
        cprint("Error, package \"" .. packageLabel .. "\" is not installed.")
        return false
    end
    cprint("Searching for '" .. packageLabel .. "' in repository... ", true)
    -- Create local variables before implementation, it can be used to avoid too much else if
    local error, result, response
    error, response = api.getPackage(packageLabel, currentPackage.version)
    if (error == 200 and response) then
        local packageMeta = PackageMetadata:new(response)
        cprint("done. Found version " .. packageMeta.nextVersion .. ".")
        if (packageMeta and packageMeta.nextVersion) then
            error, response = api.getUpdate(packageLabel, packageMeta.nextVersion)
            if (error == 200 and response) then
                local packageMeta = PackageMetadata:new(response)
                local result, packagePath = download.package(packageMeta)
                if (result) then
                    result, error = insert(packagePath)
                    if (result) then
                        cprint("Success, package \"" .. packageLabel .. "\" has been updated.")
                        return true
                    end
                end
            end
        else
            error = "no update"
        end
    end
    return false, getError(error)
end

return install
