function getProcessNameFromProcessID(iProcessID)
  if iProcessID < 1 then return 0 end
  local plist = createStringlist()
  getProcesslist(plist)
  for i=1, strings_getCount(plist)-1 do
    local process = strings_getString(plist, i)
    local offset = string.find(process,'-')
    local pid = tonumber('0x'..string.sub(process,1,offset-1))
    local pname = string.sub(process,offset+1)
    if pid == iProcessID then return pname end
  end
  return 0
end

function getOpenedProcessName()
  local process = getOpenedProcessID()
  if process ~= 0 and getProcessIDFromProcessName(DefaultProccessName) == getOpenedProcessID() then
    if checkOpenedProcess(DefaultProccessName) == true then return DefaultProccessName end
    return 0
  end
  return getProcessNameFromProcessID(getOpenedProcessID())
end

function deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
      copy = {}
      for orig_key, orig_value in next, orig, nil do
          copy[deepcopy(orig_key)] = deepcopy(orig_value)
      end
      setmetatable(copy, deepcopy(getmetatable(orig)))
  else -- number, string, boolean, etc
      copy = orig
  end
  return copy
end

function delete_directory(dir)
  execute_cmd(string.format('rmdir /s /q "%s"', dir))
end

function getfield (f)
  if DEBUG_MODE then
    do_log("getfield - f: " .. f)
  end
  local v = _G    -- start with the table of globals
  for w in string.gmatch(f, "[%w_]+") do
    if v == nil then
      do_log(string.format("No globals... field: %s", f), "ERROR")
      assert(false)
    end
    v = v[w]
  end
  return v
end

function setfield (f, v)
  if DEBUG_MODE then
    do_log("setfield - f: " .. f .. " v: " .. v)
  end
  local t = _G    -- start with the table of globals
  for w, d in string.gmatch(f, "([%w_]+)(.?)") do
    if d == "." then      -- not last field?
      
      t[w] = t[w] or {}   -- create table if absent
      t = t[w]            -- get the table

      if (type(t) == "string") then return end
    else                  -- last field
      t[w] = v            -- do the assignment
    end
  end
end

function split(s, delimiter)
  local result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
      table.insert(result, match);
  end
  return result;
end

function toBits(num)
  local t={} -- will contain the bits
  local bits=32
  for b=bits,1,-1 do
      rest=math.floor((math.fmod(num,2)))
      t[b]=rest
      num=(num-rest)/2
  end
  return string.reverse(table.concat(t))
end

function file_exists(name)
  local f, err = io.open(name,"r")
  if f then
    io.close(f)
    sleep(250)
    return true
  else
    if err ~= nil then
      do_log("file_exists err: " .. err)
    end
    return false
  end
end