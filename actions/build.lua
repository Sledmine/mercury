local glue = require "glue"
local ends = glue.string.ends
local path = require "path"
local fs = require "fs"
local yaml = require "tinyyaml"
local paths = environment.paths()

---@class buildfile
---@field version number
---@field game_engine string
---@field tag_space string
---@field extend_limits boolean
---@field scenarios string[]
---@field auto_forge boolean
---@field resource_usage string
---@field with_index string
---@field script_source "data" | "tags"
---@field commands table<string, string[]>

-- Provide a runner command for each invader command 
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

local function build(yamlFilePath, command, verbose, isRelease, outputPath, scenarios)
    local yamlFile = readFile(yamlFilePath) or readFile("buildspec.yml") or
                         readFile("buildspec.yaml")
    verify(yamlFile, "No buildspec.yml or buildspec.yaml file found")

    -- Build project using yml definition
    ---@type buildfile
    local buildspec = yaml.parse(yamlFile)
    verify(buildspec.version, "Spec version must be defined")
    verify(buildspec.version == 1, "Spec version must be equal to 1")
    -- verify(buildspec.game_engine, "Game engine must be defined")
    -- verify(buildspec.game_engine == "gbx-custom", "Game engine must be gbx-custom")
    if command then
        verify(buildspec.commands[command], "Command is not defined")
        for _, cmd in ipairs(buildspec.commands[command]) do
            if not os.execute(cmd) then
                cprint("Error, at executing command: " .. cmd)
                return false
            end
        end
        return true
    end
    verify(buildspec.scenarios and #buildspec.scenarios > 0, "List of scenarios must be defined")
    if not verbose then
        flag("hide-pedantic-warnings")
    end
    -- Specify outputh path, game maps path by default
    if outputPath then
        if runner ~= "" then
            buildMapCmd = replace(buildMapCmd, "$OUTPUT_PATH", outputPath)
        else
            flag("maps", "\"" .. outputPath .. "\"")
        end
    else
        if runner ~= "" then
            buildMapCmd = replace(buildMapCmd, "$OUTPUT_PATH", paths.gameMaps)
        else
            flag("maps", "\"" .. paths.gameMaps .. "\"")
        end
    end
    if not buildspec.script_source then
        flag("script-source", "tags")
    else
        flag("script-source", buildspec.script_source)
    end
    if buildspec.auto_forge then
        flag("auto-forge")
    end
    if buildspec.extend_limits then
        flag("extend-file-limits")
    end
    if buildspec.tag_space then
        flag("tag-space", buildspec.tag_space)
    end
    if buildspec.resource_usage then
        flag("resource-usage", buildspec.resource_usage)
    end
    if buildspec.with_index then
        flag("with-index", buildspec.with_index)
    end
    flag("game-engine", buildspec.game_engine or "gbx-custom")
    -- Compile every scenario in the spec file
    local projectBuildMapCmd = buildMapCmd
    for _, scenarioPath in ipairs(buildspec.scenarios) do
        if scenarios then
            local scenarioName = path.file(scenarioPath)
            if not table.indexof(scenarios, scenarioName) then
                goto continue
            end
        end
        buildMapCmd = projectBuildMapCmd
        if isRelease and ends(scenarioPath, "_dev") then
            local scenarioName = path.file(scenarioPath)
            -- Remove the _dev suffix from the scenario name
            scenarioName = scenarioName:sub(1, scenarioName:len() - 4)
            flag("rename-scenario", scenarioName)
        end
        local buildCommand = buildMapCmd .. "\"" .. scenarioPath .. "\""
        cprint("Compiling scenario: " .. scenarioPath)
        dprint(buildCommand)
        if not IsDebugModeEnabled then
            if not os.execute(buildCommand) then
                cprint("Error, at building scenario: " .. scenarioPath)
                return false
            end
        end
        ::continue::
    end
    cprint("Success, project built.")
    return true
end

return build
