-- http://lua-users.org/lists/lua-l/2010-04/msg00005.html

-----------------------------------------------------------
-- load an mo file and return a lua table
-- @param mo_file name of the file to load
-- @return translating function on success
-- @return on failure trivial function returning its argument, plus error string
-- @copyright J.JÃrgen von Bargen
-- @licence I provide this as public domain
-- @see http://www.gnu.org/software/hello/manual/gettext/MO-Files.html
-----------------------------------------------------------

local function trivial(text)
    return text
end

return function(mo_file)
    if (type(mo_file) ~= "string") or (mo_file == "") then
        return trivial, "ERROR: Invalid path argument"
    end

    --------------------------------
    -- open file and read data
    --------------------------------
    local fd, err = io.open(mo_file, "rb")
    if not fd then
        return trivial, "ERROR: "..err
    end
    local mo_data = fd:read("*all")
    fd:close()

    --------------------------------
    -- precache some functions
    --------------------------------
    local byte=string.byte
    local sub=string.sub

    --------------------------------
    -- check format
    --------------------------------
    local peek_long --localize
    local magic=sub(mo_data,1,4)
    -- intel magic 0xde120495
    if magic=="\222\018\004\149" then
        peek_long=function(offs)
            local a,b,c,d=byte(mo_data,offs+1,offs+4)
            return ((d*256+c)*256+b)*256+a
        end
    -- motorola magic = 0x950412de
    elseif magic=="\149\004\018\222" then
        peek_long=function(offs)
            local a,b,c,d=byte(mo_data,offs+1,offs+4)
            return ((a*256+b)*256+c)*256+d
        end
    else
        return trivial, "ERROR: Unknown magic number "..tostring(magic)
    end

    --------------------------------
    -- version
    --------------------------------
    local V = peek_long(4)
    if V ~= 0 then
        return trivial, "ERROR: Invalid version number "..tostring(V)
    end

    ------------------------------
    -- get number of offsets of table
    ------------------------------
    local N,O,T=peek_long(8),peek_long(12),peek_long(16)
    ------------------------------
    -- traverse and get strings
    ------------------------------
    local hash={}
    for nstr=1,N do
        local ol,oo=peek_long(O),peek_long(O+4) O=O+8
        local tl,to=peek_long(T),peek_long(T+4) T=T+8
        hash[sub(mo_data,oo+1,oo+ol)]=sub(mo_data,to+1,to+tl)
    end
    return function(text)
        return hash[text] or text
    end
end
