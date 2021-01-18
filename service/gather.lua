local argparse = require "argparse"
local json = require "ljson"
local glue = require "glue"

local parser = argparse("Gather", "Create an index json from the packages metadata from Genesis")
parser:argument("path", "")

-- Parsed args
local args = parser:parse()

local packageCount = 6

local packagesList = {}
for packageNumber = 1, packageCount do
    local jsonContent = glue.readfile(args.path .. "\\" .. packageNumber .. ".json", "t")
    local package = json.decode(jsonContent)
    if (package._type == "package") then
        local indexJson = {
            label = package.label,
            version = package.version,
        }
        glue.append(packagesList, indexJson)
    end
end

glue.writefile("packagesList.json", json.encode(packagesList), "t")