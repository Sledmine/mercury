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
    local file = readFile(filePath)
    print("Analyzing: ", filePath)
    local dependencies = {}
    for line in file:gmatch("[^\r\n]+") do
        -- With format 'require "dependency"'
        local dependency = line:match("require \"(.+)\"")
        if dependency then
            -- print("Found:", dependency)
            if not table.indexof(dependencies, dependency) then
                table.insert(dependencies, dependency)
            end
        end
    end
    return dependencies
end

---Get a module file path from a module name and a list of include paths
---@param moduleName string
---@param includePaths string[]
---@return string?
function luabundler.getModulePath(moduleName, includePaths)
    moduleName = moduleName:replace(".", "/")
    for _, includePath in pairs(includePaths) do
        local modulePath = includePath .. moduleName .. ".lua"
        -- if exists(modulePath) then
        return modulePath
        -- end
    end
    return nil
end

local function getFirstFileFromInclude(moduleName, includePaths)
    for _, includePath in pairs(includePaths) do
        if exists(includePath .. moduleName) then
            return includePath .. moduleName
        end
    end
    return nil
end

--- Bundle a modular lua project using luacc implementation
---@param bundleName string
---@param compileBundle boolean
---@param hotReload boolean
---@param projectPath string
function luabundler.bundle(bundleName, compileBundle, hotReload, projectPath)
    --  TODO Add compilation feature based on the lua target
    if bundleName then
        bundleName = bundleName .. "Bundle.json"
    end
    if projectPath then
        bundleName = projectPath .. "/" .. bundleName
    end

    local bundleFile = bundleName or "bundle.json"
    if not bundleFile or not exists(bundleFile) then
        cprint("Warning there is not a " .. bundleFile .. " in this folder, be sure to create one.")
    end

    ---@type boolean, bundle?
    local _, project = pcall(json.decode, readFile(bundleFile))
    if not project then
        cprint("Error bundle file is not valid!")
        return false
    end

    --local mainPath = assert(getFirstFileFromInclude(project.main, project.include), "Main file not found!")
    --local dependencies = luabundler.analyzeDependencies(mainPath)
    --while true do
    --    local newDependencies = {}
    --    for _, dependency in pairs(dependencies) do
    --        local modulePath = assert(luabundler.getModulePath(dependency, project.include), "Module not found!")
    --        local moduleDependencies = luabundler.analyzeDependencies(modulePath)
    --        for _, moduleDependency in pairs(moduleDependencies) do
    --            if not table.indexof(dependencies, moduleDependency) and not table.indexof(newDependencies, moduleDependency) then
    --                table.insert(newDependencies, moduleDependency)
    --            end
    --        end
    --    end
    --    if #newDependencies == 0 then
    --        break
    --    end
    --    table.insert(dependencies, newDependencies)
    --end

    cprint("Bundling project " .. project.name .. "... ", true)
    local error = codeBundler({
        main = project.main,
        include = project.include,
        modules = project.modules,
        output = project.output
    })
    if error then
        cprint("Error, " .. error)
        return false
    end
    cprint("done.")

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
        local template = {
            name = "Template",
            target = "lua53",
            include = {"lua/"},
            modules = {""},
            main = "main",
            output = "dist/.lua"
        }
        writeFile("bundle.json", pjson.stringify(template, nil, 4))
        cprint("Success, bundle.json template has been created successfully.")
        return true
    end
    cprint("Warning there is already a bundle file in this folder!")
    return false
end

return luabundler
