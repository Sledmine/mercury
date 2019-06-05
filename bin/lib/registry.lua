---------------------------------------------------------------------------------------
-- Module to fiddle with the Windows registry.
--
-- Version 0.1, [copyright (c) 2013 - Thijs Schreijer](http://www.thijsschreijer.nl)
-- @name registry
-- @class module

local registry = {}
local lua51 = rawget(_G,'setfenv')

--- execute a shell command.
-- This is a compatibility function that returns the same for Lua 5.1 and Lua 5.2
-- @param cmd a shell command
-- @return true if successful
-- @return actual return code
local function execute (cmd)
    local res1,res2,res2 = os.execute(cmd)
    if lua51 then
        return res1==0,res1
    else
        return res1,res2
    end
end

--- execute a shell command and return the output.
-- This function redirects the output to tempfiles and returns the content of those files.
-- @param cmd a shell command
-- @return true if successful
-- @return actual return code
-- @return stdout output (string)
-- @return errout output (string)
local function executeex(cmd)
  local outfile = os.tmpname()
  local errfile = os.tmpname()
	os.remove(outfile)
	os.remove(errfile)
  
  outfile = os.getenv('TEMP')..outfile
  errfile = os.getenv('TEMP')..errfile
  cmd = cmd .. [[ >"]]..outfile..[[" 2>"]]..errfile..[["]]
  
	local success, retcode = execute(cmd)

  local outcontent, errcontent, fh
  
  fh = io.open(outfile)
  if fh then
    outcontent = fh:read("*a")
    fh:close()
  end
  os.remove(outfile)
  
  fh = io.open(errfile)
  if fh then
    errcontent = fh:read("*a")
    fh:close()
  end
  os.remove(errfile)

  return success, retcode, (outcontent or ""), (errcontent or "")
end

-- Splits a string using a pattern
local split = function(str, pat)
  local t = {}
  local fpat = "(.-)" .. pat
  local last_end = 1
  local s, e, cap = str:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
      table.insert(t,cap)
    end
    last_end = e+1
    s, e, cap = str:find(fpat, last_end)
  end
  if last_end <= #str then
    cap = str:sub(last_end)
    table.insert(t, cap)
  end
  return t
end

-- wrap string in double quotes
local dqwrap = function(str)
  assert(type(str)=="string", "Expected string, got "..type(str))
  return '"'..str..'"'
end

-- returns a tree structure with the registry key
-- the key-table has fields:
--   key    : the full key, eg. "HKEY_CLASSES_ROOT\somekey\subkey\subsubkey"
--   keys   : table (indexed by name) with key-table of the sub key (same structure)
--   values : table (indexed by name) with a values-table having fields:
--          value: the value
--          type : the registry value type, eg. REG_SZ, REG_MULTI_SZ, etc.
--          name : the name
local function parsequery(output, i)
  assert(type(output) == "string" or type(output) == "table", "Expected string or table, got "..type(output))
  local lines
  if type(output) == "string" then 
    lines = split(output, "\n")
  else
    lines = output
  end
  local i = i or 1
  local result = { values = {}, keys = {} }
  while i <= #lines do
    if lines[i] ~= "" then
      if result.key then 
        -- key already set, so this is content
        if lines[i]:sub(1,1) == " " then
          -- starts with whitespace, so it is a value
          local n, t, v = lines[i]:match("^%s%s%s%s(.+)%s%s%s%s(REG_.+)%s%(%d%d?%)%s%s%s%s(.*)$")
          result.values[n] = { ["type"] = t, value = v, name = n}
        elseif lines[i]:find(result.key,1,true) == 1 then
          -- the line starts with the same sequence as our key, so it is a sub-key
          local skey
          local name = lines[i]:sub(#result.key + 2, -1)
          skey, i = parsequery(lines, i)
          result.keys[name] = skey
        else
          -- something else, so a key on a higher level
          return result, i-1
        end
      else
        -- key not set, so this is the key
        result.key = lines[i]
      end
    else
      if result.key then
        -- blank line while key already set, so we're done with the values
        while lines[i] == "" and i <= #lines do i = i + 1 end
        if lines[i] then
          if lines[i]:find(result.key,1,true) ~= 1 then
            -- the next key in the list is not a sub key, so we're done
            return result, i
          else
            i = i - 1 
          end
        end
      end
    end    
    i = i + 1
  end
  if result.key then
    return result, i
  else
    return nil
  end
end

--- Returns the contents of a registry key.
--- returns a tree structure with the registry key
-- the key-table has fields:
--   key    : the full key, eg. "HKEY_CLASSES_ROOT\somekey\subkey\subsubkey"
--   keys   : table (indexed by name) with key-table of the sub key (same structure)
--   values : table (indexed by name) with a values-table having fields:
--          value: the value
--          type : the registry value type, eg. REG_SZ, REG_MULTI_SZ, etc.
--          name : the name
-- @param key full key eg. "HKLM\SOFTWARE\xPL"
-- @param recursive if truthy, then a recursive tree will be generated will all sub keys as well
function registry.getkey(key, recursive)
  assert(type(key)=="string", "Expected string, got "..type(key))
  local options = " /z"
  if recursive then options = options.." /s" end
  local ok, ec, out, err = executeex([[reg.exe query ]]..dqwrap(key)..options)
  if not ok then 
    return nil, (split(err,"\n"))[1]  -- return only first line of error
  else
    local result = parsequery(out)
    if not recursive then
      -- when not recursive, then remove empty tables
      for _, v in pairs(result.keys) do
        v.keys = nil
        v.values = nil
      end
    end
    return result
  end
end


--- Creates a key
-- @param key the registry key to create
-- @return `true` on success, `nil+err` on failure
function registry.createkey(key)
  local ok, ec, out, err = executeex([[reg.exe add ]]..dqwrap(key)..[[ /f]])
  if not ok then
    return nil, (split(err,"\n"))[1]  -- return only first line of error
  else
    return true
  end
end

--- Deletes a key (and all of its contents)
-- @param key the registry key to delete
-- @return `true` on success, `nil+err` on failure (deleting a non-existing key returns success)
function registry.deletekey(key)
  local ok, ec, out, err = executeex([[reg.exe delete ]]..dqwrap(key)..[[ /f]])
  if not ok then
    if not registry.getkey(key) then return true end -- it didn't exist in the first place
    return nil, (split(err,"\n"))[1]  -- return only first line of error
  else
    return true
  end
end

--- write a value (will create the key in the process).
-- Will overwrite existing values without prompt
-- use `name = "(Default)"` (or `nil`) for default value
-- @param key the registry key to which to add a value
-- @param name the name of the value to add
-- @param vtype the value type to add
-- @param value the actual value
-- @return `true` on success, `nil+err` on failure
function registry.writevalue(key, name, vtype, value)
  local command
  if name == "(Default)" or name == nil then 
    command = ("reg.exe add %s /ve /t %s /d %s /f"):format(dqwrap(key), vtype, dqwrap(value))
  else
    command = ("reg.exe add %s /v %s /t %s /d %s /f"):format(dqwrap(key),dqwrap(name), vtype, dqwrap(value))
  end
  local ok, ec, out, err = executeex(command)
  if not ok then
    return nil, (split(err,"\n"))[1]  -- return only first line of error
  else
    return true
  end
end

--- Deletes a value.
-- use name = "(Default)" for default value, or name = nil
-- @param key the registry key from which to delete a value
-- @param name the name of the value to delete
-- @return `true` on success, `nil+err` on failure (deleting a non-existing value returns success)
function registry.deletevalue(key, name)
  local command
  if name == "(Default)" or name == nil then 
    command = ("reg.exe delete %s /ve /f"):format(dqwrap(key))
  else
    command = ("reg.exe delete %s /v %s /f"):format(dqwrap(key),dqwrap(name))
  end
  local ok, ec, out, err = executeex(command)
  if not ok then
    if not registry.getvalue(key, name) then return true end -- it didn't exist in the first place
    return nil, (split(err,"\n"))[1]  -- return only first line of error
  else
    return true
  end
end

--- Returns a value.
-- @param key the registry key from which to get the value
-- @param name the name of the value
-- @return `value` + `type` or `nil` if it doesn't exist
function registry.getvalue(key, name)
  local keyt = registry.getkey(key)
  if keyt then
    if keyt[name] then
      -- it exists, return value and type
      return keyt[name].value, keyt[name].type
    end
  end
  return nil
end

return registry