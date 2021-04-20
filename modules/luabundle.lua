-------------------------------------------------------------------------------
-- Lua bundler module
-- Sledmine
-- Bundle features for modular lua projects
-------------------------------------------------------------------------------
local glue = require "glue"
local json = require "cjson"
local pjson = require "pretty.json"
local bundle = require "bundle"
local fs = require "fs"

local codeBundler = require "lib.codeBundler"

local luabundler = {}

---@class bundle
---@field name string
---@field requires table
---@field include table
---@field main string
---@field output string

--- Bundle a modular lua project using luacc implementation
function luabundler.bundle(bundleName, compile)
    --  TODO Add compilation feature based on the lua target
    if (bundleName) then
        bundleName = bundleName .. "Bundle.json"
    end
    local bundleFileName = bundleName or "bundle.json"
    if (bundleFileName and exist(bundleFileName)) then
        ---@type bundle
        local project = json.decode(glue.readfile(bundleFileName, "t"))
        if (project) then
            cprint("Bundling project " .. project.name .. "... ", true)
            local error = codeBundler({
                main = project.main,
                include = project.include,
                modules = project.modules,
                output = project.output
            })
            if (not error) then
                cprint("done.")
                if (compile) then
                    cprint("Compiling project... ", true)
                    local compile = project.target:gsub("lua", "luac") .. " -o " ..
                                        project.output
                    compile = compile .. " " .. project.output
                    local compileResult = os.execute(compile)
                    if (compileResult) then
                        cprint("done.")
                    else
                        cprint(
                            "Error, compilation process encountered one or more errors!")
                    end
                end
            else
                cprint("Error, " .. error)
                return false
            end
        end
        return true
    end
    cprint("Warning, there is not a " .. bundleFileName ..
               " in this folder, be sure to create one.")
    return false
end

--- Attempt to create a manifest file template
function luabundler.template()
    if (not fs.is("manifest.json")) then
        local template = {
            name = "",
            target = "lua53",
            include = {"modules\\"},
            modules = {""},
            main = "",
            output = "dist\\.lua"
        }
        glue.writefile("manifest.json", pjson.stringify(template, nil, 4), "t")
        cprint("Success, manifest.json template has been created successfully.")
    else
        cprint("Warning, there is already a manifest in this folder!")
    end
end

return luabundler
