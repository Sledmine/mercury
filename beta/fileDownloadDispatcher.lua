socket = require "socket"

local M = {}

function download (host, file, port)
    port = port or 80
    print (host, file, port)
    local connectStatus, myConnection = pcall (socket.connect,host,port)
    if (connectStatus) then
        myConnection:settimeout(0.01) -- do not block you can play with this value
        local count = 0 -- counts number of bytes read
        -- May be easier to do this LuaSocket's HTTP functions
        myConnection:send("GET " .. file .. " HTTP/1.0\r\n\r\n")
        local lastStatus = nil
        while true do
            local buffer, status, overflow = receive(myConnection, lastStatus)
            -- If buffer is not null the call was a success (changed in LuaSocket 2.0)
            if (buffer ~= nil) then
                 io.write("+")
                 io.flush()
                 count = count + string.len(buffer)
            else
                print ("\n\"" .. status .. "\" with " .. string.len(overflow) .. " bytes of " .. file)
                io.flush()
                count = count + string.len(overflow)
            end
            if status == "closed" then break end
                lastStatus=status
            end
            myConnection:close()
            print(file, count)
        else
            print("Connection failed with error : " .. myConnection)
            io.flush()
        end
    end
    threads = {} -- list of all live threads

    function get (host, file, port)
        -- create coroutine
        local co = coroutine.create(
            function ()
                download(host, file, port)
            end)

        -- insert it in the
        table.insert(threads, co)
    end

function receive (myConnection, status)
    if status == "timeout" then
        print (myConnection, "Yielding to dispatcher")
        io.flush()
        coroutine.yield(myConnection)
    end
    return myConnection:receive(1024)
end

function dispatcher ()
    while true do
        local n = table.getn(threads)
        if n == 0 then break end -- no more threads to run
        local connections = {}
        for i=1,n do
            print (threads[i], "Resuming")
            io.flush()
            local status, res = coroutine.resume(threads[i])
            if not res then -- thread finished its task?
                table.remove(threads, i)
                break
            else -- timeout
                table.insert(connections, res)
            end
        end
        if table.getn(connections) == n then
            socket.select(connections)
        end
    end
end

M.download = download
M.get = get
M.dispatcher = dispatcher

return M