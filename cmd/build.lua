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
---@field extra_tags string[]

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
    local spec = yaml.parse(yamlFile)
    verify(spec.version, "Spec version must be defined")
    verify(spec.version == 1, "Spec version must be equal to 1")
    -- verify(buildspec.game_engine, "Game engine must be defined")
    -- verify(buildspec.game_engine == "gbx-custom", "Game engine must be gbx-custom")
    if command then
        verify(spec.commands[command], "Command is not defined")
        for _, cmd in ipairs(spec.commands[command]) do
            if not os.execute(cmd) then
                cprint("Error at executing command: " .. cmd)
                return false
            end
        end
        return true
    end
    if not spec.scenarios and not spec.commands then
        cprint("Error No scenarios or commands found in the buildspec file, nothing to build!")
        return false
    end
    if not spec.commands then
        verify(spec.scenarios and #spec.scenarios > 0, "List of scenarios must be defined")
    end
    if not command and not spec.scenarios then
        cprint("Error No scenarios found in the buildspec file")
        return false
    end
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
    if not spec.script_source then
        flag("script-source", "tags")
    else
        flag("script-source", spec.script_source)
    end
    if spec.auto_forge then
        flag("auto-forge")
    end
    if spec.extend_limits then
        flag("extend-file-limits")
    end
    if spec.tag_space then
        flag("tag-space", spec.tag_space)
    end
    if spec.resource_usage then
        flag("resource-usage", spec.resource_usage)
    end
    if spec.with_index then
        flag("with-index", spec.with_index)
    end
    flag("game-engine", spec.game_engine or "gbx-custom")
    if forgeCrc then
        flag("forge-crc", forgeCrc)
    end
    if spec.extra_tags then
        for _, tag in ipairs(spec.extra_tags) do
            flag("tags", tag)
        end
    end

    -- Validate provided scenarios exist in the buildspec
    if scenarios then
        spec.scenarios = table.filter(spec.scenarios, function(scenario)
            local scenarioName = path.file(scenario)
            local found = table.find(scenarios, function(scenarioToCompile)
                return scenarioToCompile == scenarioName
            end)
            return found ~= nil
        end)
        verify(#spec.scenarios > 0, "No scenarios found to compile")
    end

    -- Compile every scenario in the spec file
    local projectBuildMapCmd = buildMapCmd
    for _, scenarioPath in pairs(spec.scenarios) do
        buildMapCmd = projectBuildMapCmd
        local scenarioName = path.file(scenarioPath)
        if isRelease and scenarioPath:endswith "_dev" then
            -- Remove the _dev suffix from the scenario name
            local releaseScenarioName = scenarioName:sub(1, scenarioName:len() - 4)
            flag("rename-scenario", releaseScenarioName)
        end
        local scenarioDir = path.dir(scenarioPath)
        flag("tags", gpath("tags", "/", scenarioDir, "/custom_tags"))
        flag("tags", "tags")
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
