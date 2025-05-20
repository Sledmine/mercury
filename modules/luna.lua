local luna = {_VERSION = "2.7.1"}

luna.string = {}

local unpack = table.unpack or unpack
local find = string.find
local insert = table.insert
local format = string.format
local char = string.char
local floor = math.floor

--- Split a string into a table of substrings by `sep`, or by each character if `sep` is not provided.
---@param s string
---@param sep? string
---@return string[]
---@nodiscard
function string.split(s, sep)
    assert(s ~= nil, "string.split: s must not be nil")
    local elements = {}
    -- Support splitting by any character or string.
    if sep == nil or sep == "" then
        for i = 1, #s do
            elements[i] = s:sub(i, i)
        end
    else
        -- Avoid using a pattern
        local position = 0
        for st, sp in function()
            return s:find(sep, position, true)
        end do
            insert(elements, s:sub(position, st - 1))
            position = sp + 1
        end
        insert(elements, s:sub(position))
    end
    return elements
end

--- Return a string with all leading whitespace removed.
---@param s string
---@return string
---@nodiscard
function string.ltrim(s)
    assert(s ~= nil, "string.ltrim: s must not be nil")
    return s:match "^%s*(.-)$"
end

--- Return a string with all trailing whitespace removed.
---@param s string
---@return string
---@nodiscard
function string.rtrim(s)
    assert(s ~= nil, "string.rtrim: s must not be nil")
    return s:match "^(.-)%s*$"
end

--- Return a string with all leading and trailing whitespace removed.
---@param s string
---@return string
---@nodiscard
function string.trim(s)
    assert(s ~= nil, "string.trim: s must not be nil")
    -- return s:match "^%s*(.-)%s*$"
    return string.ltrim(string.rtrim(s))
end

--- Return a string with all ocurrences of `pattern` replaced with `replacement`.
---
--- **NOTE**: Pattern is a plain string, not a Lua pattern. Use `string.gsub` for Lua patterns.
---@param s string
---@param pattern string
---@param replacement string
---@return string
---@nodiscard
function string.replace(s, pattern, replacement)
    assert(s ~= nil, "string.replace: s must not be nil")
    assert(pattern ~= nil, "string.replace: pattern must not be nil")
    assert(replacement ~= nil, "string.replace: replacement must not be nil")
    local pattern = pattern:escapep()
    local replaced, _ = s:gsub(pattern, replacement:escapep())
    return replaced
end

--- Return a hex encoded string.
---@param s string | number
---@return string
---@nodiscard
function string.tohex(s)
    assert(s ~= nil, "string.hex: s must not be nil")
    if type(s) == "number" then
        return format("%08.8x", s)
    end
    return (s:gsub(".", function(c)
        return format("%02x", string.byte(c))
    end))
end

--- Return a hex decoded string.
---@param s string
---@return string
---@nodiscard
function string.fromhex(s)
    assert(s ~= nil, "string.fromhex: s must not be nil")
    return (s:gsub("..", function(cc)
        return char(tonumber(cc, 16))
    end))
end

--- Resturn if a string starts with a given substring.
---@param s string
---@param start string
---@return boolean
---@nodiscard
function string.startswith(s, start)
    assert(s ~= nil, "string.startswith: s must not be nil")
    assert(start ~= nil, "string.startswith: start must not be nil")
    return string.sub(s, 1, string.len(start)) == start
end

--- Resturn if a string ends with a given substring.
---@param s string
---@param ending string
---@return boolean
---@nodiscard
function string.endswith(s, ending)
    assert(s ~= nil, "string.endswith: s must not be nil")
    assert(ending ~= nil, "string.endswith: ending must not be nil")
    return ending == "" or string.sub(s, -string.len(ending)) == ending
end

--- Return a string with template variables replaced with values from a table.
---@param s string
---@param t table<string, string | number | boolean>
---@return string
---@nodiscard
function string.template(s, t)
    assert(s ~= nil, "string.template: s must not be nil")
    assert(t ~= nil, "string.template: t must not be nil")
    return (s:gsub("{(.-)}", function(k)
        return t[k] or ""
    end))
end

--- Return if a string includes a given substring.
---@param s string
---@param substring string
---@return boolean
---@nodiscard
function string.includes(s, substring)
    assert(s ~= nil, "string.includes: s must not be nil")
    assert(substring ~= nil, "string.includes: substring must not be nil")
    return find(s, substring, 1, true) ~= nil
end

--- Return a string with all lua pattern characters escaped.
---@param s string
---@return string
---@nodiscard
function string.escapep(s)
    assert(s ~= nil, "string.escape: s must not be nil")
    return (s:gsub("%%", "%%%%"):gsub("%z", "%%z"):gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1"))
end

--- Return how many times a substring appears in a string.
---@param s string
---@param substring string
---@return number
---@nodiscard
function string.count(s, substring)
    assert(s ~= nil, "string.count: s must not be nil")
    assert(substring ~= nil, "string.count: substring must not be nil")
    local count = 0
    for _ in s:gmatch(string.escapep(substring)) do
        count = count + 1
    end
    return count
end

luna.string.split = string.split
luna.string.ltrim = string.ltrim
luna.string.rtrim = string.rtrim
luna.string.trim = string.trim
luna.string.replace = string.replace
luna.string.tohex = string.tohex
luna.string.fromhex = string.fromhex
luna.string.startswith = string.startswith
luna.string.endswith = string.endswith
luna.string.template = string.template
luna.string.includes = string.includes
luna.string.escapep = string.escapep
luna.string.count = string.count

luna.table = {}

--- Return a deep copy of a table.
---
--- If the table contains other tables, they are copied as well, even metatables.
---@generic T
---@param t T
---@return T
---@nodiscard
function table.copy(t)
    assert(t ~= nil, "table.copy: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.copy: t must be a table")
    local u = {}
    ---@diagnostic disable-next-line: param-type-mismatch
    for k, v in pairs(t) do
        u[k] = type(v) == "table" and table.copy(v) or v
    end
    return setmetatable(u, getmetatable(t))
end

--- Find and return first index of `value` in `t`.
---@generic V
---@param t table<number, V>: { [number]: V }
---@param value V
---@return number?
---@nodiscard
function table.indexof(t, value)
    assert(t ~= nil, "table.find: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.find: t must be a table")
    ---@diagnostic disable-next-line: param-type-mismatch
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
end

--- Return a table with all keys and values swapped.
---@generic K, V
---@param t table<K, V>
---@return {[V]: K}
---@nodiscard
function table.flip(t)
    assert(t ~= nil, "table.flip: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.flip: t must be a table")
    local u = {}
    ---@diagnostic disable-next-line: param-type-mismatch
    for k, v in pairs(t) do
        u[v] = k
    end
    return u
end

--- Returns the first element of `t` that satisfies the predicate `f`.
--- If `f` is a value, it will return the first element that is equal to `f`.
---@generic K, V
---@param t table<K, V>
---@param f fun(v: V, k: K): boolean || `V`
---@return V?
---@nodiscard
function table.find(t, f)
    assert(t ~= nil, "table.find: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.find: t must be a table")
    assert(f ~= nil, "table.find: f must not be nil")
    if type(f) ~= "function" then
        local value = f
        f = function(v)
            return v == value
        end
    end
    ---@diagnostic disable-next-line: param-type-mismatch
    for k, v in pairs(t) do
        if f(v, k) then
            return v
        end
    end
end

--- Returns an array of all keys in `t`.
---@generic K, V
---@param t table<K, V>
---@return K[]
---@nodiscard
function table.keys(t)
    assert(t ~= nil, "table.keys: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.keys: t must be a table")
    local keys = {}
    ---@diagnostic disable-next-line: param-type-mismatch
    for k in pairs(t) do
        keys[#keys + 1] = k
    end
    return keys
end

--- Returns an array of all values in `t`.
---@generic K, V
---@param t table<K, V>
---@return V[]
---@nodiscard
function table.values(t)
    assert(t ~= nil, "table.values: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.values: t must be a table")
    local values = {}
    ---@diagnostic disable-next-line: param-type-mismatch
    for _, v in pairs(t) do
        values[#values + 1] = v
    end
    return values
end

--- Returns a table with all elements of `t` that satisfy the predicate `f`.
---@generic K, V
---@param t table<K, V>
---@param f fun(v: V, k: K): boolean
---@return {[K]: V}
---@nodiscard
function table.filter(t, f)
    assert(t ~= nil, "table.filter: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.filter: t must be a table")
    assert(f ~= nil, "table.filter: f must not be nil")
    assert(type(f) == "function", "table.filter: f must be a function")
    local filtered = {}
    ---@diagnostic disable-next-line: param-type-mismatch
    for k, v in pairs(t) do
        if f(v, k) then
            filtered[#filtered + 1] = v
        end
    end
    return filtered
end

--- Returns a table with all elements of `t` that satisfy the predicate `f`.
---
--- **NOTE**: It keeps original keys in the new table.
---@generic K, V
---@param t table<K, V>
---@param f fun(v: V, k: K): boolean
---@return {[K]: V}
---@nodiscard
function table.kfilter(t, f)
    assert(t ~= nil, "table.kfilter: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.kfilter: t must be a table")
    assert(f ~= nil, "table.kfilter: f must not be nil")
    assert(type(f) == "function", "table.kfilter: f must be a function")
    local filtered = {}
    ---@diagnostic disable-next-line: param-type-mismatch
    for k, v in pairs(t) do
        if f(v, k) then
            filtered[k] = v
        end
    end
    return filtered
end

--- Returns a table with all elements of `t` mapped by function `f`.
---
--- **NOTE**: It keeps original keys in the new table.
---@generic K, V
---@generic R
---@param t table<K, V>
---@param f fun(v: V, k: K): R
---@return {[K]: R}
-- @return R[]
---@nodiscard
function table.map(t, f)
    assert(t ~= nil, "table.map: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.map: t must be a table")
    assert(f ~= nil, "table.map: f must not be nil")
    assert(type(f) == "function", "table.map: f must be a function")
    local mapped = {}
    ---@diagnostic disable-next-line: param-type-mismatch
    for k, v in pairs(t) do
        mapped[k] = f(v, k)
    end
    return mapped
end

--- Returns a table merged from all tables passed as arguments.
---@generic K, V
---@vararg table<K, V>
---@return {[K]: V}
---@nodiscard
function table.merge(...)
    local merged = {}
    for _, t in ipairs {...} do
        for k, v in pairs(t) do
            merged[k] = v
        end
    end
    return merged
end

--- Returns a table with all values extended from all tables passed as arguments.
---@generic K, V
---@param t table<K, V>
---@vararg table<K, V>
---@return V[]
---@nodiscard
function table.extend(t, ...)
    assert(t ~= nil, "table.extend: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.extend: t must be a table")
    local extended = table.copy(t)
    for _, t in ipairs {...} do
        for _, v in pairs(t) do
            extended[#extended + 1] = v
        end
    end
    ---@diagnostic disable-next-line: return-type-mismatch
    return extended
end

--- Append values to a table.
--- It will append all given values to the end of the table.
---@generic V
---@param t V[]
---@vararg V
---@return V[]
function table.append(t, ...)
    assert(t ~= nil, "table.append: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.append: t must be a table")
    local appended = table.copy(t)
    for _, v in ipairs {...} do
        appended[#appended + 1] = v
    end
    ---@diagnostic disable-next-line: return-type-mismatch
    return appended
end

--- Returns a table with all elements in reversed order.
---@generic T
---@param t T
---@return T
---@nodiscard
function table.reverse(t)
    assert(t ~= nil, "table.reverse: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.reverse: t must be a table")
    local reversed = {}
    for i = #t, 1, -1 do
        reversed[#reversed + 1] = t[i]
    end
    return reversed
end

--- Return a slice of a table, from `start` to `stop`
---
--- If `stop` is not provided, it will slice to the end of the table.
---@generic K, V
---@param t table<K, V>
---@param start number Index to start slice from.
---@param stop? number Index to stop slice at.
---@return {[K]: V}
---@nodiscard
function table.slice(t, start, stop)
    assert(t ~= nil, "table.slice: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.slice: t must be a table")
    assert(start ~= nil, "table.slice: start must not be nil")
    assert(type(start) == "number", "table.slice: start must be a number")
    if stop then
        assert(type(stop) == "number", "table.slice: stop must be a number")
    end
    local sliced = {}
    for i = start, stop or #t do
        sliced[#sliced + 1] = t[i]
    end
    return sliced
end

--- Return an array of chunks from a table, each chunk containing `size` elements.
---
--- If `t` is not evenly divisible by `size`, last chunk will contain the remaining elements.
---@generic K, V
---@param t table<K, V>
---@param size number
---@return {[K]: V[]}
---@nodiscard
function table.chunks(t, size)
    assert(t ~= nil, "table.chunks: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.chunks: t must be a table")
    assert(size ~= nil, "table.chunks: size must not be nil")
    assert(type(size) == "number", "table.chunks: size must be a number")
    local chunks = {}
    for i = 1, #t, size do
        ---@diagnostic disable-next-line: param-type-mismatch
        chunks[#chunks + 1] = table.slice(t, i, i + size - 1)
    end
    return chunks
end

--- Return the number of elements in a table.
--- Optionally `v` can be provided to count the number of occurrences of `v` in `t`.
---@generic T, V
---@param t T
---@param v? V
---@return number
function table.count(t, v)
    assert(t ~= nil, "table.count: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.count: t must be a table")
    if v == nil then
        return #t
    end
    local count = 0
    ---@diagnostic disable-next-line: param-type-mismatch
    for _, value in pairs(t) do
        if value == v then
            count = count + 1
        end
    end
    return count
end

--- Return the key of a value in a table.
--- If the value is not found, it will return `nil`.
---@generic K, V
---@param t table<K, V>
---@param v V
---@return K?
---@nodiscard
function table.keyof(t, v)
    assert(t ~= nil, "table.keyof: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.keyof: t must be a table")
    ---@diagnostic disable-next-line: param-type-mismatch
    for k, value in pairs(t) do
        if value == v then
            return k
        end
    end
end

--- Return a flattened table from a nested table.
--- All nested tables will be flattened into a single table.
--- If `t` is not a table, it will return `t`.
--- If `t` is a table with no nested tables, it will return `t`.
---@generic K, V
---@param t table<K, V>
---@return V[]
---@nodiscard
function table.flatten(t)
    assert(t ~= nil, "table.flatten: t must not be nil")
    assert(type(t) == "table" or type(t) == "userdata", "table.flatten: t must be a table")
    local flattened = {}
    ---@diagnostic disable-next-line: param-type-mismatch
    for _, v in pairs(t) do
        if type(v) == "table" then
            for _, value in pairs(table.flatten(v)) do
                flattened[#flattened + 1] = value
            end
        else
            flattened[#flattened + 1] = v
        end
    end
    return flattened
end

luna.table.copy = table.copy
luna.table.indexof = table.indexof
luna.table.flip = table.flip
luna.table.find = table.find
luna.table.keys = table.keys
luna.table.values = table.values
luna.table.filter = table.filter
luna.table.map = table.map
luna.table.merge = table.merge
luna.table.reverse = table.reverse
luna.table.slice = table.slice
luna.table.chunks = table.chunks
luna.table.count = table.count
luna.table.keyof = table.keyof
luna.table.flatten = table.flatten
luna.table.extend = table.extend
luna.table.append = table.append

luna.math = {}

--- Return a rounded number, optionally to a precision.
---
--- If `p` is not provided, it will round to the nearest integer.
---@param n number
---@param p? number
---@return number
---@nodiscard
function math.round(n, p)
    assert(n ~= nil, "math.round: n must not be nil")
    assert(type(n) == "number", "math.round: n must be a number")
    assert(p == nil or type(p) == "number", "math.round: p must be a number")
    p = p or 1
    return floor(n / p + .5) * p
end

luna.math.round = math.round

luna.file = {}

--- Read a file into a string.
---@param path string
---@return string?
---@nodiscard
function luna.file.read(path)
    assert(path ~= nil, "file.read: path must not be nil")
    local file = io.open(path, "r")
    if file then
        local content = file:read "*a"
        file:close()
        return content
    end
end

--- Write a file from a string.
---@param path string
---@param content string
---@return boolean
function luna.file.write(path, content)
    assert(path ~= nil, "file.write: path must not be nil")
    assert(content ~= nil, "file.write: content must not be nil")
    local file = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
        return true
    end
    return false
end

--- Append a string to a file.
---@param path string
---@param content string
---@return boolean
function luna.file.append(path, content)
    assert(path ~= nil, "file.append: path must not be nil")
    assert(content ~= nil, "file.append: content must not be nil")
    local file = io.open(path, "a")
    if file then
        file:write(content)
        file:close()
        return true
    end
    return false
end

--- Return if a file exists.
---@param path string
---@return boolean
---@nodiscard
function luna.file.exists(path)
    assert(path ~= nil, "file.exists: path must not be nil")
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

--- Attempt to remove a file.
---@param path string
---@return boolean
function luna.file.remove(path)
    assert(path ~= nil, "file.remove: path must not be nil")
    return os.remove(path)
end

--- Write file from a byte array.
---@param path string
---@param bytes number[]
---@return boolean
function luna.file.frombytes(path, bytes)
    assert(path ~= nil, "file.frombytes: path must not be nil")
    assert(bytes ~= nil, "file.frombytes: bytes must not be nil")
    local file = io.open(path, "wb")
    if file then
        for i = 1, #bytes do
            file:write(char(bytes[i]))
        end
        file:close()
        return true
    end
    return false
end

--- Return a byte array from a file.
---@param path string
---@return number[]?
---@nodiscard
function luna.file.tobytes(path)
    assert(path ~= nil, "file.tobytes: path must not be nil")
    local file = io.open(path, "rb")
    if file then
        local bytes = {}
        local content = file:read "*a"
        for i = 1, #content do
            bytes[i] = content:byte(i)
        end
        file:close()
        return bytes
    end
end

luna.binary = {}

--- Read a binary file into a string.
---@param path string
---@return string?
---@nodiscard
function luna.binary.read(path)
    assert(path ~= nil, "binary.read: path must not be nil")
    local file = io.open(path, "rb")
    if file then
        local content = file:read "*a"
        file:close()
        return content
    end
end

--- Write a binary file from a string.
---@param path string
---@param content string
---@return boolean
function luna.binary.write(path, content)
    assert(path ~= nil, "binary.write: path must not be nil")
    assert(content ~= nil, "binary.write: content must not be nil")
    local file = io.open(path, "wb")
    if file then
        file:write(content)
        file:close()
        return true
    end
    return false
end

luna.url = {}

--- Return a table with all query parameters from a URL.
--- If the URL has no query parameters, it will return an empty table.
---@param url string
---@return {[string]: string}
---@nodiscard
function luna.url.params(url)
    assert(url ~= nil, "url.query: url must not be nil")
    local query = {}
    for key, value in url:gmatch "([^&=?]-)=([^&=?]*)" do
        query[key] = value
    end
    return query
end

--- Return a URL string with all characters encoded to be an RFC compatible URL.
---@param s string
---@return string
---@nodiscard
function luna.url.encode(s)
    assert(s ~= nil, "url.encode: s must not be nil")
    return (s:gsub("[^%w%-_%.~]", function(c)
        return format("%%%02X", c:byte())
    end))
end

--- Return a URL string with all encoded characters decoded.
---@param s string
---@return string
---@nodiscard
function luna.url.decode(s)
    assert(s ~= nil, "url.decode: s must not be nil")
    return (s:gsub("%%(%x%x)", function(hex)
        return char(tonumber(hex, 16))
    end))
end

--- Return a boolean from `v` if it is a boolean like value.
---@param v string | boolean | number
---@return boolean
function luna.bool(v)
    assert(v ~= nil, "bool: v must not be nil")
    return v == true or v == "true" or v == 1 or v == "1"
end

--- Return a bit (number as 0 or 1) from `v` if it is a boolean like value.
---@param v string | boolean | number
---@return integer
---@nodiscard
function luna.bit(v)
    assert(v ~= nil, "bit: v must not be nil")
    return luna.bool(v) and 1 or 0
end

--- Return an integer from `v` if possible.
---
--- If `v` is not a number, it will return `fail`.
---@param v string
---@return integer
function tointeger(v)
    assert(v ~= nil, "int: v must not be nil")
    return tonumber(v, 10)
end
luna.int = tointeger

return luna
