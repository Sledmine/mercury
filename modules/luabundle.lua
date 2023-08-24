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

--- Bundle a modular lua project using luacc implementation
---@param bundleName string
---@param compileBundle boolean
---@param hotReload boolean
function luabundler.bundle(bundleName, compileBundle, hotReload)
    --  TODO Add compilation feature based on the lua target
    if bundleName then
        bundleName = bundleName .. "Bundle.json"
    end
    local bundleFileName = bundleName or "bundle.json"
    if bundleFileName and exists(bundleFileName) then
        ---@type bundle
        local project = json.decode(readFile(bundleFileName))
        if project then
            cprint("Bundling project " .. project.name .. "... ", true)
            local error = codeBundler({
                main = project.main,
                include = project.include,
                modules = project.modules,
                output = project.output
            })
            if not error then
                cprint("done.")
                if compileBundle then
                    cprint("Compiling project... ", true)
                    local compileCmd = project.target:gsub("lua", "luac") .. " -o " .. project.output
                    compileCmd = compileCmd .. " " .. project.output
                    local compiled = os.execute(compileCmd)
                    if compiled then
                        cprint("done.")
                    else
                        cprint("Error, compilation process encountered one or more errors!")
                    end
                end
            else
                cprint("Error, " .. error)
                return false
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
    end
    cprint("Warning there is not a " .. bundleFileName .. " in this folder, be sure to create one.")
    return false
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
