local function fetch()
    local code, response = api.fetch()
    if (code == 200 and response) then
        print(response)
    else
        cprint("Error, at getting the latest package index from the from the repository.")
    end
end

return fetch