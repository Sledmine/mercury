local glue = require "glue"
local path = require "path"
local fs = require "fs"
local readFile = glue.readfile
local yaml = require "tinyyaml"

---@class buildfile
---@field version number
---@field game_engine string
---@field tag_space string
---@field extend_limits boolean
---@field scenarios string[]
---@field manifest_path string
---@field output_path string
---@field postbuild string[]
---@field commands table<string, string>
---@field cloud_owner string
---@field cloud_path string

--Provide a runner command for each invader command 
local runner = replace((os.getenv("INVADER_RUNNER") or ""), "$PWD", fs.cd())
local resourceMapsPath = os.getenv("INVADER_RESOURCE_MAPS_PATH")
local buildMapCmd = runner .. [[invader-build ]]

local function flag(name, value)
    if not value then
       buildMapCmd = buildMapCmd .. "--" .. name .. " "
       return
    end
    buildMapCmd = buildMapCmd .. "--" .. name .. " " .. value .. " "
end

local function build(yamlFilePath, verbose, isRelease)
    local yamlFile = readFile(yamlFilePath or "buildspec.yaml", "t")
    if not yamlFile then
        cprint("Error, at reading buildspec.yaml")
        return false
    end

    -- Build project using yml definition
    ---@type buildfile
    local buildspec = yaml.parse(yamlFile)
    verify(buildspec.version, "Spec version must be defined")
    verify(buildspec.version == 1, "Spec version must be equal to 1")
    verify(buildspec.game_engine, "Game engine must be defined")
    verify(buildspec.game_engine == "gbx-custom", "Game engine must be gbx-custom")
    verify(buildspec.scenarios and #buildspec.scenarios > 0, "List of scenarios must be defined")
    if not verbose then
        flag("hide-pedantic-warnings")
    end
    if buildspec.extend_limits then
        flag("extend-file-limits")
    end
    if buildspec.tag_space then
        flag("tag-space", buildspec.tag_space)
    end
    if resourceMapsPath then
        flag("resource-maps", resourceMapsPath)
    end
    flag("game-engine", buildspec.game_engine)
    -- Compile every scenario in the spec file
    for _, scenarioPath in ipairs(buildspec.scenarios) do
        if isRelease and string.find(scenarioPath, "_dev\0", 1, true) then
            -- Remove the _dev suffix from the scenario name
            local scenarioName = path.file(scenarioPath)
            local scenarioNameRelease = replace(scenarioName, "_dev\0", "")
            flag("rename-scenario", scenarioNameRelease)
        end
        local buildCommand = buildMapCmd .. "\"" .. scenarioPath .. "\""
        cprint("Compiling scenario: " .. scenarioPath)
        if not os.execute(buildCommand) then
            dprint(buildCommand)
            cprint("Error, at building scenario: " .. scenarioPath)
            return false
        end
    end
    cprint("Success, project builded.")
    return true
end

return build
