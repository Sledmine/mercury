local install = {}

-- Actions
local search = require "actions.search"
local remove = require "actions.remove"
local insert = require "actions.insert"

-- Modules
local download = require "modules.download"

-- Entities
local PackageMetadata = require "entities.packageMetadata"

local errorTable = {
    ["404"] = "package not found",
    ["connection refused"] = "no connection to repository",
    ["download error"] = "an error occurred while downloading",
    ["invalid host"] = "package host is invalid"
}

local function getError(error)
    -- // TODO: Add better error array handling
    if (type(error) == "table") then
        error = error[1]
    end
    local errorDescription = errorTable[tostring(error)] or error or "unknown error"
    dprint(error)
    cprint("Error, " .. errorDescription .. ".")
    return false, errorDescription
end

function install.package(packageLabel, packageVersion, forced, noBackups)
    if (search(packageLabel)) then
        if (forced) then
            remove(packageLabel, true, true)
        else
            cprint("Warning, package \"" .. packageLabel .. "\" is already installed.")
            return false
        end
    end
    cprint("Searching for '" .. packageLabel .. "' in repository... ", true)
    local error, response = api.getPackage(packageLabel, packageVersion)
    if (error == 200 and response) then
        cprint("done.")
        local packageMeta = PackageMetadata:new(response)
        if (packageMeta and packageMeta.mirrors) then
            local result, packagePath = download.package(packageMeta)
            if (result) then
                local result, error = insert(packagePath, forced, noBackups)
                if (result) then
                    cprint("Success, package \"" .. packageLabel .. "\" has been installed.")
                    return true
                else
                    return getError(error)
                end
            end
        else
            return getError(error)
        end
    else
        return getError(error)
    end
end

function install.update(packageLabel)
    local currentPackage = search(packageLabel)
    if (not currentPackage) then
        cprint("Error, package \"" .. packageLabel .. "\" is not installed.")
        return false
    end
    cprint("Searching for '" .. packageLabel .. "' in repository... ", true)
    local error, response = api.getPackage(packageLabel, currentPackage.version)
    if (error == 200 and response) then
        cprint("done.")
        local packageMeta = PackageMetadata:new(response)
        if (packageMeta and packageMeta.nextVersion) then
            local error, response = api.getUpdate(packageLabel, packageMeta.nextVersion)
            if (error == 200 and response) then
                local packageMeta = PackageMetadata:new(response)
                local result, packagePath = download.package(packageMeta)
                if (result) then
                    local result, error = insert(packagePath)
                    if (result) then
                        cprint("Success, package \"" .. packageLabel .. "\" has been updated.")
                        return true
                    else
                        return getError(error)
                    end
                else
                    return getError(error)
                end
            else
                return getError(error)
            end
        else
            return getError(error)
        end
    else
        return getError(error)
    end
end

return install
