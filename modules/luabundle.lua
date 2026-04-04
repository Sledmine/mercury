-------------------------------------------------------------------------------
-- Lua bundler module
-- Sledmine
-- Bundle features for modular lua projects
-------------------------------------------------------------------------------
local glue = require "glue"
local json = require "cjson"
local pjson = require "pretty.json"
local bundle = require "bundle"
local paths = config.paths()

local codeBundler = require "modules.codeBundler"

local luabundler = {}

---@class bundle
---@field name string
---@field target string
---@field include string[]
---@field modules string[]
---@field main string
---@field output string

---Analyze dependencies of a lua file
---@param filePath string
---@return string[]
function luabundler.analyzeDependencies(filePath)
    --print("Analyzing: ", filePath)
    local file = readFile(filePath)
    local dependencies = {}
    for line in file:gmatch("[^\r\n]+") do
        line = line:replace("'", "\"")
        -- Consider ONLY next cases:
        -- require("dependency")
        -- require ("dependency")
        -- require "dependency"
        -- require"dependency"
        local dependency = line:match("require%s*%(%s*\"(.-)\"%s*%)") or
                               line:match("require%s*\"(.-)\"") or line:match("require%s*(.-)%s*")
        -- TODO Add support for protected require calls
        -- pcall(require, "dependency")
        if dependency and dependency ~= "" then
            local isDependencyDynamic = dependency:includes("..")
            if not table.indexof(dependencies, dependency) and not isDependencyDynamic then
                table.insert(dependencies, dependency)
            end
        end
    end
    return dependencies
end

---Get the first file from a module path and a list of include paths
---@param modulePath string
---@param includePaths string[]
---@return string?
local function getFirstFileFromInclude(modulePath, includePaths)
    local modulePath = modulePath .. ".lua"
    for _, includePath in pairs(includePaths) do
        local path = gpath(includePath, "/", modulePath)
        --dprint("Attempting to get module at path: " .. path)
        if exists(path) then
            dprint("Resolved module path: " .. path)
            return path
        end
    end
    return nil
end

---Get a module file path from a module name and a list of include paths
---@param moduleName string
---@param includePaths string[]
---@return string?
function luabundler.getModulePath(moduleName, includePaths)
    --dprint("Finding module path for: " .. moduleName)
    moduleName = moduleName:replace(".", "/")
    return getFirstFileFromInclude(moduleName, includePaths)
end

--- Bundle a modular lua project trough Mercury bundle process
---@param bundleName? string
---@param compileBundle boolean
---@param hotReload boolean
---@param projectPath? string
function luabundler.bundle(bundleName, compileBundle, hotReload, projectPath)
    if projectPath and bundleName then
        bundleName = projectPath .. "/" .. bundleName
    end

    local bundleFile = bundleName or "bundle"
    local validBundlePaths = {
        bundleFile,
        bundleFile .. "Bundle",
        bundleFile .. "_bundle"
    }
    local bundleExists = false
    for _, path in pairs(validBundlePaths) do
        local path = path .. ".json"
        cprint("Checking \"" .. path .. "\"...")
        if exists(path) then
            bundleFile = path
            bundleExists = true
            break
        end
    end
    verify(bundleExists, "No valid bundle file in current directory")

    ---@type boolean, bundle?
    local _, project = pcall(json.decode, readFile(bundleFile))
    if not project then
        cprint("Error bundle file is not valid!")
        return false
    end

    verify(project.output, "Output path not defined in bundle file")
    verify(project.include, "Include paths not defined in bundle file")

    project.main = project.main or "main"

    -- TODO We might not want to look for main in the include paths
    -- This can lead to picking the wrong file if there are multiple files with the same name
    local mainPath = getFirstFileFromInclude(project.main, project.include) or project.main .. ".lua"
    assert(exists(mainPath), "Main file not found in include paths")
    local requiredModules = {}
    local pathsAnalyzed = {}
    local function gatherDependencies(filePath)
        if table.indexof(pathsAnalyzed, filePath) then
            return
        end
        table.insert(pathsAnalyzed, filePath)
        dprint("Getting dependencies for: " .. filePath)
        local dependencies = luabundler.analyzeDependencies(filePath)
        for _, dependency in pairs(dependencies) do
            local modulePath = luabundler.getModulePath(dependency, project.include)
            if modulePath and not table.indexof(requiredModules, dependency) then
                table.insert(requiredModules, dependency)
                gatherDependencies(modulePath)
            end
        end
    end
    
    -- Get all dependencies from main file
    cprint("Gathering lua modules... ")
    gatherDependencies(mainPath)

    -- Resolve all static modules paths
    project.modules = project.modules or {}

    -- Remove all static modules from resolved required modules
    project.modules = table.filter(project.modules, function(module)
        return table.indexof(requiredModules, module) == nil
    end)
    project.modules = table.extend(requiredModules, project.modules)
    
    -- Print all required modules
    print("Required modules: ")
    for _, module in pairs(project.modules) do
        print("-", module)
        -- Match module name with module path and print
        local modulePath = luabundler.getModulePath(module, project.include)
        if modulePath then
            dprint("-", modulePath)
        else
            cprint("WARNING " .. module .. " (not found in include paths)")
        end
    end

    cprint("--------------------------------------")
    cprint("Bundling project " .. (project.name or "unnamed") .. "... ")
    local error = codeBundler {
        main = project.main,
        include = project.include or {},
        modules = table.map(project.modules, function(modulePath)
            --return modulePath:replace(".lua", ""):replace("/", ".")
            return modulePath:replace("/", ".")
        end),
        output = project.output
    }
    if error then
        cprint("Error, " .. error)
        return false
    end

    cprint("Done Project bundled successfully")

    if compileBundle then
        cprint("Compiling project... ", true)
        local compileCmd = project.target:replace("lua", "luac") .. " -o " .. project.output
        compileCmd = compileCmd .. " " .. project.output
        local compiled = os.execute(compileCmd)
        if compiled then
            cprint("done.")
        else
            cprint("Error, compilation process encountered one or more errors!")
        end
    end

    if hotReload then
        cprint("Hot reload enabled, creating hot reload file.... ", true)
        if writeFile(paths.myGamesPath .. "/chimera/hot_reload", "") then
            cprint("done.")
        else
            cprint("Error hot reload file could not be created!")
            return false
        end
    end
    return true
end

--- Attempt to create a bundle file template
function luabundler.template()
    if not exists("bundle.json") then
        createFolder("lua/modules")
        local template = {
            name = "Name Project Here",
            target = "lua53",
            include = {"lua", "lua/modules"},
            modules = {},
            main = "lua/main",
            output = "dist/output.lua"
        }
        local jsonFile = pjson.stringify(template, nil, 4)
        jsonFile = jsonFile:replace("\\", "")
        writeFile("bundle.json", jsonFile)
        cprint("Success, bundle.json template has been created successfully.")
        return true
    end
    cprint("Warning there is already a bundle file in this folder!")
    return false
end

return luabundler
