local glue = require "glue"
local ends = glue.string.ends
local path = require "path"
local fs = require "fs"
local yaml = require "tinyyaml"
local paths = config.paths()

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

--- Build a project using a buildspec.yml file
---@param yamlFilePath string
---@param command string
---@param verbose boolean
---@param isRelease boolean
---@param outputPath string
---@param scenarios? string[]
---@param forgeCrc string?
local function build(yamlFilePath, command, verbose, isRelease, outputPath, scenarios, forgeCrc)
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
    if forgeCrc then
        flag("forge-crc", forgeCrc)
    end

    -- Validate provided scenarios exist in the buildspec
    if scenarios then
        buildspec.scenarios = table.filter(buildspec.scenarios, function(scenario)
            local scenarioName = path.file(scenario)
            local found = table.find(scenarios, function(scenarioToCompile)
                return scenarioToCompile == scenarioName
            end)
            return found ~= nil
        end)
        verify(#buildspec.scenarios > 0, "No scenarios found to compile")
    end

    -- Compile every scenario in the spec file
    local projectBuildMapCmd = buildMapCmd
    for _, scenarioPath in pairs(buildspec.scenarios) do
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
                cprint("Error building scenario: " .. scenarioPath)
                return false
            end
        end
        ::continue::
    end
    cprint("Success project built.")
    return true
end

local templateSpec = [[version: 1
tag_space: 64M
extend_limits: false
scenarios:
  - levels/test/test
commands:
  release:
    - mercury build --release --output package/game-maps/]]

local function template()
    cprint("Bootstrapping project...")
    createFolder("data")
    createFolder("tags")
    createFolder("hek")

    local hekDataSymlink = gpath(pwd(), "/", "hek", "/", "data")
    local hekTagsSymlink = gpath(pwd(), "/", "hek", "/", "tags")
    -- Use absolute paths for symlinks?
    local relativeDataPath = gpath("..", "/", "data")
    local relativeTagsPath = gpath("..", "/", "tags")

    local created, reason = createSymlink(hekDataSymlink, relativeDataPath, true)
    if not created then
        cprint("Warning data symlink can not be created: " .. (reason or "unknown"))
    end

    local created, reason = createSymlink(hekTagsSymlink, relativeTagsPath, true)
    if not created then
        cprint("Warning tags symlink can not be created: " .. (reason or "unknown"))
    end

    if not exists("buildspec.yml") and not exists("buildspec.yaml") then
        writeFile("buildspec.yaml", templateSpec)
        cprint("Success project build template created.")
        return true
    end

    cprint("Warning buildspec file already exists")
    return false
end

return {build = build, template = template}
