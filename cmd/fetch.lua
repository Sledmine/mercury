local json = require "cjson"
local glue = require "glue"

local function fetch(isJsonOutput)
    local code, response = api.fetch()
    dprint(code)
    dprint(response)
    if code == 200 and response then
        if response then
            if isJsonOutput then
                print(response)
                return true
            end
            local availablePackages = json.decode(response)
            dprint(availablePackages)
            print("Packages available for installation on the Mercury repository:")
            glue.map(availablePackages, function(_, package)
                print(("- %s-%s"):format(package.label, package.version))
            end)
        end
    else
        cprint("Error at getting the latest package index from the from the repository.")
    end
    return false
end

return fetch
