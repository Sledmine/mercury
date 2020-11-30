-------------------------------------------------------------------------------
-- Bundle module
-- Sledmine
-- Bundler for lua mod projects
-------------------------------------------------------------------------------
local glue = require "glue"
local json = require "cjson"
local bundle = require "bundle"

local codeBundler = require "lib.codeBundler"

---@class bundle
---@field name string
---@field requires table
---@field include table
---@field main string
---@field output string

local function bundler(bundleName, compile)
    -- // TODO Add compilation feature based on the lua target
    local bundleFileName = bundleName or "bundle.json"
    if (exist(bundleFileName)) then
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
                    local compile = project.target:gsub("lua", "luac") .. " -o " .. project.output
                    compile = compile .. " " .. project.output
                    local compileResult = os.execute(compile)
                    if (compileResult) then
                        cprint("done.")
                    else
                        cprint("Error, compilation process encountered one or more errors!")
                    end
                end
            else
                cprint("Error, " + error)
                return false
            end
        end
        return true
    end
    cprint("Warning, There is not a " .. bundleFileName .. " in this folder, be sure to create one.")
    return false
end

return bundler
