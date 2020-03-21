require 'lua/commons';
-- helpers

function _translate(txt)
    if _ == nil then
        return txt
    end

    local translated = _(txt)
    if DEBUG_MODE and CURRENT_LANG ~= "en_US" then
        if translated == txt then
            do_log(string.format('Possible missing translation - %s', txt))
        end
    end
    return translated
end

function is_cm_loaded()
    do_log("Check is_cm_loaded")
    local modules = enumModules()
    for _, module in ipairs(modules) do
        if module.Name == 'FootballCompEng_Win64_retail.dll' then
            -- We are in career mode
            return true
        end
    end

    -- We are outside career mode
    return false
end

function getAddressModule(module_name)
    local modules = enumModules()
    for _, module in ipairs(modules) do
        if module.Name == module_name then
            return module.Address
        end
    end
    return nil
end

function enum_all_modules()
    local modules = enumModules()
    for _, module in ipairs(modules) do
        do_log(
            string.format("%s, %X", module.Name, module.Address)
        )
    end
end

function execute_cmd(cmd)
    do_log(string.format('execute cmd -  %s', cmd))
    local p = assert(io.popen(cmd))
    local result = p:read("*all")
    p:close()
    if result then
        do_log(string.format('execute cmd result -  %s', result))
    end
end

-- After attach
function after_attach()
    update_status_label("Attached to the game process.")
    check_for_le_update()

    -- MM_TAB_HOME
    -- MM_TAB_PLAY
    -- MM_TAB_ONLINE
    local screenid_aob = tonumber(get_validated_address('AOB_screenID'), 16)
    SCREEN_ID_PTR = byteTableToDword(readBytes(screenid_aob+4, 4, true)) + screenid_aob + 8
    logScreenID()

    -- Don't activate too early
    do_log("Waiting for valid screen")
    while getScreenID() == nil do
        ShowMessage('You are not in main menu in game. Enter there and close this window')
        sleep(1500)
    end
    logScreenID()

    -- update_offsets()
    save_cfg()
    autoactivate_scripts()
    load_playernames()

    for i = 1, #FORMS do
        local form = FORMS[i]
        -- remove borders
        form.BorderStyle = bsNone

        -- update opacity
        form.AlphaBlend = true
        form.AlphaBlendValue = CFG_DATA.gui.opacity or 255
    end
    writeInteger("IsCMCached", 0)
    MainFormRemoveLoadingPanel()
    getMainForm().Visible = true

    do_log('Ready to use.', 'INFO')
    update_status_label("Program is ready to use.")
    showMessage("Live Editor is ready to use.")
end

function auto_attach_to_process()
    -- ONLY FOR GUI TESTS
    -- timer_setEnabled(AutoAttachTimer, false)
    -- start()
    -- ONLY FOR GUI TESTS

    local ProcessName = CFG_DATA.game.name
    local ProcIDNormal = getProcessIDFromProcessName(ProcessName)

    -- Trial when FIFA is from Origin Access
    local ProcessName_Trial = CFG_DATA.game.name_trial
    local ProcIDTrial = getProcessIDFromProcessName(ProcessName_Trial)

    if ProcIDNormal ~= nil then
        openProcess(ProcessName)
    elseif ProcIDTrial ~= nil then
        openProcess(ProcessName_Trial)
    end

    local attached_to = getOpenedProcessName()

    local pid = getOpenedProcessID()
    if pid > 0 and attached_to ~= nil then
        timer_setEnabled(AutoAttachTimer, false)
        do_log(string.format("Attached to %s", attached_to), 'INFO')
        FIFA_PROCESS_NAME = getOpenedProcessName()
        BASE_ADDRESS = getAddress(FIFA_PROCESS_NAME)
        FIFA_MODULE_SIZE = getModuleSize(FIFA_PROCESS_NAME)
        after_attach()
    end
end

function start()
    -- First check if we can attach to process
    if getOpenedProcessID() == 0 then
        MainWindowForm.bringToFront()
        AutoAttachTimer = createTimer(nil)
        -- Without timer our GUI will not be displayed
        timer_onTimer(AutoAttachTimer, auto_attach_to_process)
        timer_setInterval(AutoAttachTimer, 1000)
        timer_setEnabled(AutoAttachTimer, true)
    else
        do_log('Restart required, getOpenedProcessID != 0. Dont open process in Cheat Engine. Live Editor will do it for you if you allow for lua code execution.', 'ERROR')
        update_status_label("Restart FIFA and Cheat Engine.")
        assert(false, _translate('Restart required, getOpenedProcessID != 0'))
    end
end

-- Check Cheat Engine Version
function check_ce_version()
    local ce_version = getCEVersion()
    do_log(string.format('Cheat engine version: %f', ce_version))
    if(ce_version == 7.0) then
        -- Bug https://github.com/cheat-engine/cheat-engine/issues/850
        do_log('This tool will not work with Cheat Engine 7.0. Download and install other version. Recommended one is 6.8.1', "ERROR")
        print("Link to download Cheat Engine 6.8.1:\nhttps://github.com/cheat-engine/cheat-engine/releases/download/v6.8.1/CheatEngine681.exe")
        assert(false, _translate('This tool will not work with Cheat Engine 7.0. Download and install other version. Recommended one is 6.8.1'))
    end
    MainWindowForm.LabelCEVer.Caption = ce_version
end

-- Get Live Editor Version
function get_le_version()
    local le_ver = string.gsub(ADDR_LIST.getMemoryRecordByID(0).Description, 'v', '')
    return le_ver
end

-- Check Live Editor Version
function check_le_version()
    local ver = get_le_version()

    do_log(string.format('Live Editor version: %s', ver))
    MainWindowForm.LabelLEVer.Caption = ver -- update version in GUI
end

function check_for_le_update()
    if CFG_DATA.flags.check_for_update then
        local new_version_is_available = false
        local r = getInternet()

        local version = r.getURL("https://raw.githubusercontent.com/xAranaktu/FIFA-20-Live-Editor/master/VERSION")
        r.destroy()

        -- no internet?
        if (version == nil) then
            NO_INTERNET = true
            do_log("CT Update check failed. No internet?", 'INFO')
            return false
        end

        local patrons_version = version:sub(1,8)
        local free_version = version:sub(9,17)

        do_log(string.format('Patrons ver -  %s, free ver - %s', patrons_version, free_version))

        local ipatronsver, _ = string.gsub(
            patrons_version, '%.', ''
        )
        ipatronsver = tonumber(ipatronsver)

        local ifreever, _ = string.gsub(
            free_version, '%.', ''
        )
        ifreever = tonumber(ifreever)

        local current_ver = get_le_version()
        local icurver, _ = string.gsub(
            current_ver, '%.', ''
        )
        icurver = tonumber(icurver)

        if CFG_DATA.flags.only_check_for_free_update then
            if CFG_DATA.other.ignore_update == free_version then
                return false
            end
            if ifreever > icurver then
                LATEST_VER = free_version
                MainWindowForm.LabelLatestLEVer.Caption = string.format(
                    "(Latest: %s)", LATEST_VER
                )
                MainWindowForm.LabelLatestLEVer.Visible = true
                return true
            end
        else
            if (ifreever > icurver) or (ipatronsver > icurver) then
                if CFG_DATA.other.ignore_update == patrons_version then
                    return false
                end
                LATEST_VER = patrons_version
                MainWindowForm.LabelLatestLEVer.Caption = string.format(
                    "(Latest: %s)", LATEST_VER
                )
                MainWindowForm.LabelLatestLEVer.Visible = true
                return true
            end
        end
    end

    return false
end

function create_dirs()
    local d_dir = string.gsub(DATA_DIR, "/","\\")
    local fifa_sett_dir = string.gsub(FIFA_SETTINGS_DIR .. 'Live Editor/cache', "/","\\")
    local cmds = {
        "mkdir " .. '"' .. d_dir .. '"',
        "ECHO A | xcopy cache " .. '"' .. fifa_sett_dir .. '" /E /i',
    }
    for i=1, #cmds do
        execute_cmd(cmds[i])
    end

end

local time = os.date("*t")
function do_log(text, level)
    if level == nil then
        level = 'INFO'
    end

    if DEBUG_MODE then
        if level ~= 'WARNING' then
            print(string.format("[ %s ] %s - %s", level, os.date("%c", os.time()), text))
        end
    else
        if level == 'ERROR' then
            showMessage(_translate(text))
        end
        logger, err = io.open("logs/log_".. string.format("%02d-%02d-%02d", time.year, time.month, time.day) .. ".txt", "a+")
        if logger == nil then
            -- log in console if file can't be open
            DEBUG_MODE = true
            print(io.popen"cd":read'*l')
            print(string.format("[ %s ] %s - %s", level, os.date("%c", os.time()), 'Error opening file: ' .. err))
        else
            logger:write(string.format("[ %s ] %s - %s\n", level, os.date("%c", os.time()), text))
            io.close(logger)
        end
    end
end

function setup_internal_calls()
    getBaseScriptsPtr()
    getIntFunctionsAddrs()
end

function getBaseScriptsPtr()
    local base_aob = tonumber(get_validated_address('AOB_SCRIPTS_BASE_PTR'), 16)
    writeQword(
        "ptrBaseScripts",
        byteTableToDword(readBytes(base_aob+10, 4, true)) + base_aob + 14
    )
end

function getIntFunctionsAddrs()
    local funcGenReport_aob = tonumber(get_validated_address('AOB_F_GEN_REPORT'), 16)
    writeQword(
        "funcGenReport",
        byteTableToDword(readBytes(funcGenReport_aob+4, 4, true)) + funcGenReport_aob + 8 - 0x100000000
    )
end

function readMultilevelPointer(base_addr, offsets)
    for i=1, #offsets do
        if base_addr == 0 or base_addr == nil then
            do_log(string.format("Invalid PTR: offset: %d", i), 'WARNING')
            do_log("All offsets", 'WARNING')
            for j=1, #offsets do
                do_log(string.format("%X", offsets[j]), 'WARNING')
            end
            return 0
        end
        base_addr = readPointer(base_addr+offsets[i])
    end
    return base_addr
end

function get_offset(base_addr, addr)
    return string.format('%X',tonumber(addr, 16) - base_addr)
end

function get_address_with_offset(base_addr, offset)
    -- Offset saved in file may contains only numbers. We want to have string
    if type(offset) == 'number' then
        offset = tostring(offset)
    end
    return string.format('%X',tonumber(offset, 16) + base_addr)
end

function get_validated_address(name, module_name, section)
    if name == nil then return end

    check_process()  -- Check if we are correctly attached to the game
    if module_name then
        name = string.format('%s.AOBS.%s', section, name)
        
        local res = AOBScanModule(
            getfield(string.format('AOB_DATA.%s', name)),
            module_name
        )
        local res_count = res.getCount()
        if res_count == 0 then 
            do_log(string.format("%s AOBScanModule error. Try to restart FIFA and Cheat Engine", name), 'ERROR')
            return '00000000'
        elseif res_count > 1 then
            do_log(string.format("%s AOBScanModule multiple matches - %i found", name, res_count), 'WARNING')
        end
        do_log(string.format('AOB FROM MODULE: %s -> %s', name, res[0]), 'INFO')

        return res[0]
    end

    local inject_at = nil
    if getfield(string.format('OFFSETS_DATA.offsets.%s', name)) ~= nil then
        inject_at = verify_offset(name)
    end
    if not inject_at then
        if not update_offset(name, true) then assert(false, string.format('Could not find valid offset for', name)) end
        inject_at = get_address_with_offset(BASE_ADDRESS, getfield(string.format('OFFSETS_DATA.offsets.%s', name)))
    end
    
    return inject_at
end

-- obsolete
function get_md5_version()
    if CFG_DATA.game.md5 ~= nil then
        return CFG_DATA.game.md5
    else
        return md5memory(BASE_ADDRESS, FIFA_MODULE_SIZE)
    end
end

-- Check game version
-- obsolete
function game_version_has_changed()
    local md5 = get_md5_version()
    if CFG_DATA.game.md5 == nil then
        CFG_DATA.game.md5 = md5
        save_cfg()
        return false
    end

    local new_md5 = md5memory(BASE_ADDRESS, FIFA_MODULE_SIZE)
    if new_md5 ~= md5 then
        showMessage("Game version has changed")
        CFG_DATA.game.md5 = new_md5
        save_cfg()
        return true
    else
        return false
    end
end

-- AOBScanModule
-- https://www.cheatengine.org/forum/viewtopic.php?p=5621132&sid=c4dd9b1a4d0ddabf23f99b8f9bfe5f4e
function AOBScanModule(aob, module_name, module_size)
    if aob == nil then
        do_log("Update not properly installed. Remove all versions of the live editor tool you have and download the latest one again", 'ERROR')
    end

    local memscan = createMemScan()
    local foundlist = createFoundList(memscan)

    local start = nil
    local stop = nil
    if module_name == nil then
        module_name = FIFA_PROCESS_NAME
        module_size = FIFA_MODULE_SIZE
        start = getAddressModule(module_name)
        if start == nil then
            start = BASE_ADDRESS
        end
    else
        module_size = getModuleSize(module_name)
        if module_size == nil then
            local module_sizes = {
                FootballCompEng_Win64_retail = 0xCE000
            }
            local mname = string.gsub(module_name, '.dll', '')
            module_size = module_sizes[mname]
        end
        start = getAddressModule(module_name)
    end

    if module_size ~= nil then
        do_log(string.format("Module_size %s, %X", module_name, module_size))
        stop = start + module_size
        do_log(string.format('%X - %X', start, stop))
    else
        stop = 0x7fffffffffff - start
        do_log(
            string.format(
                'Module_size %s is nil. new stop: %X',
                module_name, stop
            )
        )
    end

    memscan.firstScan(
      soExactValue, vtByteArray, rtRounded, 
      aob, nil, start, stop, "*X*W", 
      fsmNotAligned, "1", true, false, false, false
    )
    memscan.waitTillDone()
    foundlist.initialize()
    memscan.Destroy()

    return foundlist
end

-- Validate offset
-- Return address if offset is valid, otherwise return False
function verify_offset(name)
    do_log(string.format("Veryfing %s offset", name), 'INFO')
    local aob = getfield(string.format('AOB_DATA.%s', name))
    local nospace_aob = string.gsub(aob, "%s+", "")
    local aob_len = math.floor(string.len(nospace_aob)/2)
    local addres_to_check = get_address_with_offset(BASE_ADDRESS, getfield(string.format('OFFSETS_DATA.offsets.%s', name)))
    do_log(string.format("addres_to_check %s, aob: %s", addres_to_check, aob), 'INFO')
    local temp_bytes = readBytes(addres_to_check, aob_len, true)
    local bytes_to_verify = {}
    -- convert to hex
    for i =1,aob_len do
        bytes_to_verify[i] = string.format('%02X', temp_bytes[i])
    end

    local index = 1
    for b in string.gmatch(aob, "%S+") do
        if b == "??" then
            -- Ignore wildcards
        elseif b ~= bytes_to_verify[index] then
            do_log(string.format("Veryfing %s offset failed", name), 'WARNING')
            do_log(string.format("Bytes in memory: %s != %s: %s", table.concat(bytes_to_verify, ' '), name, aob), 'WARNING')
            if bytes_to_verify[1] == 'E9' then
                do_log('jmp already set. This happen when you close and reopen Live Editor without deactivating scripts. Now, restart FIFA and Cheat Engine to fix this problem', 'WARNING')
            end
            return false
        end
        index = index + 1
    end
    do_log(string.format("Veryfing %s offset success", name), 'INFO')
    return addres_to_check
end

-- Update offset
-- Return true if success
function update_offset(name, save, module_name, module_size, section)
    local res_offset = nil
    local valid_i = {}
    local base_addr = BASE_ADDRESS

    if module_name then
        name = string.format('%s.AOBS.%s', section, name)
        base_addr = getAddress(module_name)
    end
    
    do_log(string.format("AOBScanModule %s", name), 'INFO')
    local res = AOBScanModule(
        getfield(string.format('AOB_DATA.%s', name)),
        module_name,
        module_size
    )
    local res_count = res.getCount()
    if res_count == 0 then 
        do_log(string.format("%s AOBScanModule error. Try to restart FIFA and Cheat Engine", name), 'ERROR')
        return false
    elseif res_count > 1 then
        do_log(string.format("%s AOBScanModule multiple matches - %i found", name, res_count), 'WARNING')
        for i=0, res_count-1, 1 do
            res_offset = tonumber(res[i], 16)
            do_log(string.format("offset %i - %X", i+1, res_offset), 'WARNING')
            valid_i[#valid_i+1] = i
        end
        if #valid_i >= 1 then
            do_log(string.format("picking offset at index - %i", valid_i[1]), 'WARNING')
            setfield(string.format('OFFSETS_DATA.offsets.%s', name), get_offset(base_addr, res[valid_i[1]]))
        else
            do_log(string.format("%s AOBScanModule error", name), 'ERROR')
            return false
        end
    else
        local offset = get_offset(base_addr, res[0])
        setfield(string.format('OFFSETS_DATA.offsets.%s', name), offset)
        do_log(string.format("New Offset for %s - %s", name, offset), 'INFO')
    end
    res.destroy()
    if save then save_offsets() end
    return true
end

-- Update all offsets (may take a few minutes)
function update_offsets()
    for k,v in pairs(AOB_DATA) do
        if type(v) == 'string' then
            -- main FIFA module
            update_offset(k, false)
        else
            -- DLC Module
            local module_name = v['MODULE_NAME']
            local module_size = getModuleSize(module_name)
            for kk, vv in pairs(v['AOBS']) do
                update_offset(kk, false, module_name, module_size, k)
            end
        end
    end

    save_offsets()
end

function check_process() 
    if FIFA_PROCESS_NAME == nil then 
        do_log('Check process has failed. FIFA_PROCESS_NAME is nil. Did you allowed CE to execute lua script at starup? ', 'ERROR')
        assert(false, 'Not initialized')
    end
    local pCurrentPID = getProcessIDFromProcessName(FIFA_PROCESS_NAME) 
    
    if pCurrentPID == nil or pCurrentPID ~= getOpenedProcessID() then
        do_log('Invalid PID. Restart FIFA and Cheat Engine is required', 'ERROR')
        assert(false, "Restart FIFA and Cheat Engine")
    else
        return true
    end
end 

function can_autoactivate(script_id)
    local not_allowed_to_aa = {
        2998  -- "Generate new report" script, it's internal call and will cause crash when activated in Main Menu
    }

    for i=1, #not_allowed_to_aa do
        if not_allowed_to_aa[i] == script_id then
            return false
        end
    end
    return true
end

function autoactivate_scripts()
    -- Always activate database tables script
    -- And globalAllocs
    -- And loadlibrary & exit cm
    local always_activate = {
        7,  -- Scripts
        12, -- FIFA Database Tables
        CT_MEMORY_RECORDS['CURRENT_DATE_SCRIPT']
    }

    for i=1, #always_activate do
        local script_id = always_activate[i]
        local script_record = ADDR_LIST.getMemoryRecordByID(script_id)
        do_log(string.format('Activating %s (%d)', script_record.Description, script_id), 'INFO')
        script_record.Active = true
    end

    for i=1, #CFG_DATA.auto_activate do
        local script_id = CFG_DATA.auto_activate[i]
        if can_autoactivate(script_id) then
            local script_record = ADDR_LIST.getMemoryRecordByID(script_id)
            if script_record then
                do_log(string.format('Activating %s (%d)', script_record.Description, script_id), 'INFO')
                if not script_record.Active then
                    script_record.Active = true
                end
            end
        end
    end
    initPtrs()
end

-- find record in game database and update pointer in CT
function _is_record_valid(addr, sizeOf)
    local bytes = readBytes(addr, sizeOf, true)
    for i=1, #bytes do
        if bytes[i] >= 0 then return true end
    end
    return false
end

function find_record_in_game_db(start, memrec_id, value_to_find, sizeOf, first_ptrname, to_exit, limit, str_contains)
    local ct_record = ADDR_LIST.getMemoryRecordByID(memrec_id)  -- Record in Live Editor
    local offset = ct_record.getOffset(0)     -- int

    -- Assuming we are dealing with Binary Type
    local bitstart = ct_record.Binary.Startbit
    local binlen = ct_record.Binary.Size
    
    local i = start
    local current_value = 0
    local invalid_records = 0
    local ptr_addr = ''
    while true do
        ptr_addr = string.format('[%s]+%X', first_ptrname, offset+(i*sizeOf))
        if str_contains then
            current_value = readString(ptr_addr)
            value_to_find = string.lower(value_to_find)
        else
            current_value = bAnd(bShr(readInteger(ptr_addr), bitstart), (bShl(1, binlen) - 1))
        end
        local address = (readPointer(first_ptrname) + i*sizeOf)
        if (str_contains and string.match(string.lower(current_value), value_to_find)) or (current_value == value_to_find) then
            if _is_record_valid(address, sizeOf) then
                return {
                    index = i,
                    addr = address,
                }
            end
            invalid_records = invalid_records + 1
        elseif current_value == 0 then
            invalid_records = invalid_records + 1
        end
        i = i + 1

        if to_exit ~= nil and invalid_records >= to_exit then
            break
        end
        if limit ~= nil and i >= limit then 
            break 
        end
    end
    return {}
end

function find_records_in_game_db(memrec_id, value_to_find, sizeOf, first_ptrname, to_exit, limit, max_records, str_contains)
    local result = {}
    local start = 0
    local i = 0
    while true do
        local record = find_record_in_game_db(start, memrec_id, value_to_find, sizeOf, first_ptrname, to_exit, limit, str_contains)
        if record['addr'] == nil then break end
        start = record['index'] + 1
        table.insert(result, record)
        i = i + 1
        if i >= max_records then break end
    end

    return result
end

function getScreenID()
    return readString(readPointer(SCREEN_ID_PTR))
end

function logScreenID()
    local screen_id = getScreenID()
    if not screen_id then 
        do_log('Current Screen: nil')
    else
        do_log('Current Screen: ' .. screen_id)
    end
end

function initPtrs()
    local codeGameDB = tonumber(get_validated_address('AOB_codeGameDB'), 16)
    local base_ptr = readPointer(byteTableToDword(readBytes(codeGameDB+4, 4, true)) + codeGameDB + 8)
    if DEBUG_MODE then
        do_log(string.format("codeGameDB base_ptr %X", base_ptr))
    end

    local DB_One_Tables_ptr = readMultilevelPointer(base_ptr, {0x10, 0x390})
    local DB_Two_Tables_ptr = readMultilevelPointer(base_ptr, {0x10, 0x3C0})
    local DB_Three_Tables_ptr = readMultilevelPointer(base_ptr, {0x10, 0x3F0})
    --print(string.format("%X", readPointer("firstptrManager")))
    -- local xxx = 0
    -- local yyy = 0
    -- for i=1, 1024 do
    --     yyy = readMultilevelPointer(DB_One_Tables_ptr, {xxx, 0x28, 0x30})
    --     if yyy ~= nil then
    --         -- Addr of first record
    --         if string.format("%X", yyy) == "A56755F8" then
    --             do_log(string.format("iiii -> 0x%X", xxx))
    --         end
    --     end
    --     xxx = xxx + 8
    -- end
    -- do_log("END")

    if DEBUG_MODE then
        do_log(string.format("DB_One_Tables_ptr %X", DB_One_Tables_ptr))
        do_log(string.format("DB_Two_Tables_ptr %X", DB_Two_Tables_ptr))
        do_log(string.format("DB_Three_Tables_ptr %X", DB_Three_Tables_ptr))
    end

    -- Players Table
    local players_firstrecord = readMultilevelPointer(DB_One_Tables_ptr, {0xB0, 0x28, 0x30})
    -- [firstPlayerDataPtr+b0]+28]+30]0
    if DEBUG_MODE then
        do_log(string.format("players_firstrecord %X", players_firstrecord))
    end

    writeQword("firstPlayerDataPtr", players_firstrecord)
    writeQword("playerDataPtr", players_firstrecord)

    -- Playernames Table
    local playernames_firstrecord = readMultilevelPointer(DB_One_Tables_ptr, {0x148, 0x30, 0x2A8, 0x28, 0x30})
    if DEBUG_MODE then
        do_log(string.format("playernames_firstrecord %X", playernames_firstrecord))
    end

    writeQword("firstplayernamesDataPtr", playernames_firstrecord)
    writeQword("playernamesDataPtr", playernames_firstrecord)

    -- Dcplayernames Table
    local dcplayernames_firstrecord = readMultilevelPointer(DB_One_Tables_ptr, {0x140, 0x28, 0x30})
    if DEBUG_MODE then
        do_log(string.format("dcplayernames_firstrecord %X", dcplayernames_firstrecord))
    end

    writeQword("firstdcplayernamesDataPtr", dcplayernames_firstrecord)
    writeQword("dcplayernamesDataPtr", dcplayernames_firstrecord)

    -- Editedplayernames Table
    local editedplayernames_firstrecord = readMultilevelPointer(DB_One_Tables_ptr, {0xE8, 0x28, 0x30})
    if DEBUG_MODE then
        do_log(string.format("editedplayernames_firstrecord %X", editedplayernames_firstrecord))
    end

    writeQword("firsteditedplayernamesDataPtr", editedplayernames_firstrecord)
    writeQword("editedplayernamesDataPtr", editedplayernames_firstrecord)

    -- Teams Table
    local teams_firstrecord = readMultilevelPointer(DB_One_Tables_ptr, {0xD8, 0x28, 0x30})
    writeQword("firstteamsDataPtr", teams_firstrecord)
    writeQword("teamsDataPtr", teams_firstrecord)

    if DEBUG_MODE then
        do_log(string.format("teams_firstrecord %X", teams_firstrecord))
    end

    -- Manager Table
    local manager_firstrecord = readMultilevelPointer(DB_One_Tables_ptr, {0x78, 0x28, 0x30})
    writeQword("firstptrManager", manager_firstrecord)
    writeQword("ptrManager", manager_firstrecord)

    if DEBUG_MODE then
        do_log(string.format("manager_firstrecord %X", manager_firstrecord))
    end

    -- Formations Table
    local formations_firstrecord = readMultilevelPointer(DB_One_Tables_ptr, {0xE0, 0x28, 0x30})
    writeQword("firstptrFormations", formations_firstrecord)
    writeQword("ptrFormations", formations_firstrecord)

    if DEBUG_MODE then
        do_log(string.format("formations_firstrecord %X", formations_firstrecord))
    end

    -- default_mentalities Table
    local default_mentalities_firstrecord = readMultilevelPointer(DB_One_Tables_ptr, {0x168, 0x28, 0x30})
    writeQword("firstptrDefaultmentalities", default_mentalities_firstrecord)
    writeQword("ptrDefaultmentalities", default_mentalities_firstrecord)

    if DEBUG_MODE then
        do_log(string.format("default_mentalities_firstrecord %X", default_mentalities_firstrecord))
    end

    -- Teamsheets Table
    local mentalities_firstrecord = readMultilevelPointer(DB_Three_Tables_ptr, {0xA0, 0x28, 0x30})
    writeQword("firstptrMentalities", mentalities_firstrecord)
    writeQword("ptrMentalities", mentalities_firstrecord)
    

    if DEBUG_MODE then
        do_log(string.format("mentalities_firstrecord %X", mentalities_firstrecord))
    end

    -- default_teamsheets Table
    local default_teamsheets_firstrecord = readMultilevelPointer(DB_One_Tables_ptr, {0x110, 0x28, 0x30})
    writeQword("firstptrDefaultteamsheets", default_teamsheets_firstrecord)
    writeQword("ptrDefaultteamsheets", default_teamsheets_firstrecord)
    

    if DEBUG_MODE then
        do_log(string.format("default_teamsheets_firstrecord %X", default_teamsheets_firstrecord))
    end

    -- Teamsheets Table
    local teamsheets_firstrecord = readMultilevelPointer(DB_Three_Tables_ptr, {0xA8, 0x28, 0x30})
    writeQword("firstptrTeamsheets", teamsheets_firstrecord)
    writeQword("ptrTeamsheets", teamsheets_firstrecord)
    

    if DEBUG_MODE then
        do_log(string.format("teamsheets_firstrecord %X", teamsheets_firstrecord))
    end

    -- TeamKits Table
    local teamkits_firstrecord = readMultilevelPointer(DB_One_Tables_ptr, {0x120, 0x28, 0x30})
    writeQword("ptrfirstTeamkits", teamkits_firstrecord)
    writeQword("ptrTeamkits", teamkits_firstrecord)

    if DEBUG_MODE then
        do_log(string.format("teamkits_firstrecord %X", teamkits_firstrecord))
    end

    -- competitionKits Table
    local competitionkits_firstrecord = readMultilevelPointer(DB_One_Tables_ptr, {0x90, 0x28, 0x30})
    writeQword("ptrfirstCompetitionkits", competitionkits_firstrecord)
    writeQword("ptrCompetitionkits", competitionkits_firstrecord)

    if DEBUG_MODE then
        do_log(string.format("competitionkits_firstrecord %X", competitionkits_firstrecord))
    end

    -- Teamplayerlinks Table
    local teamplayerlinks_firstrecord = readMultilevelPointer(DB_One_Tables_ptr, {0x128, 0x28, 0x30})
    writeQword("ptrFirstTeamplayerlinks", teamplayerlinks_firstrecord)
    writeQword("ptrTeamplayerlinks", teamplayerlinks_firstrecord)

    -- LeagueTeamLinks Table
    local leagueteamlinks_firstrecord = readMultilevelPointer(DB_One_Tables_ptr, {0x150, 0x28, 0x30})
    writeQword("leagueteamlinksDataFirstPtr", leagueteamlinks_firstrecord)
    writeQword("leagueteamlinksDataPtr", leagueteamlinks_firstrecord)

    -- career_calendar Table
    local careercalendar_firstrecord = readMultilevelPointer(DB_Two_Tables_ptr, {0xC0, 0x28, 0x30})
    writeQword("ptrCareerCalendar", careercalendar_firstrecord)

    -- Career_PlayerContract
    local playercontract_firstrecord = readMultilevelPointer(DB_Two_Tables_ptr, {0x38, 0x28, 0x30})
    writeQword("firstplayercontractDataPtr", playercontract_firstrecord)
    writeQword("playercontractDataPtr", playercontract_firstrecord)

    -- BASE PTR FOR STAMINA & INJURES
    local code = tonumber(get_validated_address('AOB_BASE_STAMINA_INJURES'), 16)
    tmp = byteTableToDword(readBytes(code+3, 4, true)) + code + 7
    autoAssemble([[ 
        globalalloc(basePtrStaminaInjures, 8, $tmp)
    ]])
    writeQword("basePtrStaminaInjures", tmp)

    -- BASE PTR FOR FORM, MORALE and Release Clause
    local code = tonumber(get_validated_address('AOB_BASE_FORM_MORALE_RLC'), 16)
    tmp = byteTableToDword(readBytes(code+3, 4, true)) + code + 7
    autoAssemble([[ 
        globalalloc(basePtrTeamFormMoraleRLC, 8, $tmp)
    ]])
    writeQword("basePtrTeamFormMoraleRLC", tmp)

    setup_internal_calls()
end

-- end

-- load AOBs
function load_aobs()
    return {
        AOB_QuitCM = '48 81 EC 20 05 00 00 48 C7 45 90 FE FF FF FF 48 89 9C',

        AOB_screenID = '4C 0F 45 3D ?? ?? ?? ?? 48 8B FE',
        AOB_codeGameDB = '4C 0F 44 35 ?? ?? ?? ?? 41 8B 4E 08',
        AOB_CalendarCurrentDate = '44 8B 7A 34 44 8B 62 38',
        AOB_BASE_STAMINA_INJURES = '48 89 3D ?? ?? ?? ?? 48 89 05 ?? ?? ?? ?? EB 03',
        AOB_SCRIPTS_BASE_PTR = '48 8B 47 10 4C 89 32',
        AOB_F_GEN_REPORT = '48 89 D9 E8 ?? ?? ?? ?? 48 89 D9 48 8B 5C 24 38 48 8B 74 24 40 48 83 C4 20',
        AOB_BASE_FORM_MORALE_RLC = '48 89 35 ?? ?? ?? ?? 48 89 3D ?? ?? ?? ?? 48 89 0D ?? ?? ?? ??', 
        AOB_CustomTransfers = '84 C0 48 8B 01 74 11 FF 50 10',
        AOB_ptrTransferBudget = '41 8D 5C 24 11 EB ?? 48 8B 0D ?? ?? ?? ?? 48 8B 01',
        AOB_TransferBudget = '44 8B 48 08 45 8B 87 90 02 00 00',
        AOB_IsEditPlayerUnlocked = '48 8B CF E8 ?? ?? ?? ?? 85 C0 75 ?? 48 8B 46 08 40 ?? ?? 48 8B 80 B8 0F 00 00',
        AOB_AltTab = '48 83 EC 48 4C 8B 05 ?? ?? ?? ?? 4D 85 C0',
        AOB_DatabaseRead = '48 ?? ?? 4C 03 46 30 E8',
        AOB_UnlimitedTraining = '41 8B 7E 38 45 8B 76 3C',
        AOB_MoreEfficientTraining = '66 0F 6E 5E 1C 45',
        AOB_TrainingEveryDay =  '83 6F 3C 01 0F 89 2D 03 00 00',
        AOB_TrainingEveryDay_DAYWITHMATCH =  '48 8B CE FF 50 20 85 C0 74 05 41',
        AOB_SimA = '8B D8 4C 8D 44 24 38 8B D0 48 8B CF',
        AOB_SideManipulator = '48 8B 84 CB 18 01 00 00 83',
        AOB_GtnRevealPlayerData = '85 C0 75 0C 4C 8D 86 8C 02 00 00',
        AOB_YouthAcademyAllCountriesAvailable = '89 4C 24 30 B9 04 00 00 00',
        AOB_CountryIsBeingScouted = '80 FB 01 75 0C 4C',
        AOB_YouthAcademyRevealPotAndOvr = '89 06 48 8D 76 04 83 FF 06 ?? ?? 41 B8 FF FF FF FF',
        AOB_YouthAcademyRevealPotAndOvrTwo = 'BA 20 00 00 00 48 8D 8D 80 09',
        AOB_YouthAcademyRevealPotAndOvrThree = '48 03 C1 48 8D 4D 70',
        AOB_ManagerRating = '89 83 74 05 00 00 48 83',
        AOB_HireScout = '41 8B 01 89 45 48 41 8B',
        AOB_EditReleaseClause = '8B 48 08 83 F9 FF 74 06 89 8B',
        AOB_AllowLoanApp = '44 8B F8 83 F8 0A',
        AOB_AllowTransferAppBtnClick = '41 FF D1 8B F0 83 F8',
        AOB_AllowTransferAppThTxt = 'E8 ?? ?? ?? ?? 8B D8 83 F8 0E ?? ?? B8 65 65 00 00 0F A3 D8',
        AOB_AllowSign = '41 FF D1 44 8B E8 85',
        AOB_AllowSignText = 'FF 90 E8 00 00 00 83 F8 0E',
        AOB_UnlimitedPlayerRelease = '39 47 54 41 0F 9C C4',
        AOB_ReleasePlayerMsgBox = '4C 8B E0 85 FF 0F',
        AOB_ReleasePlayerFee = '41 89 04 24 89 C3',
        AOB_IngameStamina = '8B 43 68 41 89 82 F8 03 00 00',
        AOB_MatchTimer = '8B 41 50 89 47 10',
        AOB_MatchScore = '0F 10 48 10 0F 11 49 10 41 8B 55',
        AOB_UnlimitedSubstitutions = '8B 84 01 74 8F 00 00',
        AOB_DisableSubstitutions = '41 8B BC 1C 84 97 00 00 45',
        AOB_NegStatusCheck = '49 8B CE FF 90 00 01 00 00 89',
        AOB_ContractNeg = '04 48 8B 41 20 4C 8B 41 18 48 8B 50 38 0F 10 42 B4',
        AOB_IntJobOffer = '48 2B 81 80 01 00 00 48 C1 F8 06 85',
        AOB_ClubJobOffer = '49 8B 9E D8 00 00 00 49',
        AOB_ClubJobOfferAlwaysAccept = 'FF 50 08 3B 47 2C',
        AOB_DisableMorale = '41 88 45 00 84 C0',
        AOB_BetterMorale = '41 89 45 10 45 8D 44 24 9B',
        AOB_Form_Settings = '41 B8 FF FF FF FF 41 89 85 88',
        AOB_SimMaxCards = '41 89 86 5C 01 00 00 E8',
        AOB_SimMaxInjuries = '41 89 86 24 01 00 00 E8',
        AOB_SimFatigueBase = '41 B8 FF FF FF FF 41 89 46 10',
        AOB_YouthAcademyMoreYouthPlayers = '89 06 FF C7 48 83 C6 04 83 FF 02 7C BF 48 8B 7C 24 30 41 FF C7 49 FF C4',
        AOB_EditPlayerName_KnownAs = '48 05 9B 00 00 00 49 C7 C0 FF FF FF FF',
        AOB_YouthAcademyPrimAttr = '41 89 F9 89 46 04',
        AOB_YouthAcademySecAttr = '4C 8B 7C 24 30 89 46',
        AOB_YouthAcademyMinAgeForPromotion = '41 B8 03 00 00 00 89 85 E4',
        AOB_YouthAcademyPlayerAgeRange = '41 89 44 24 08 66 66',
        AOB_YouthAcademyYouthPlayersRetirement = '89 07 48 8D 7F 04 41 83 FD',
        AOB_YouthAcademyPlayerPotential = 'FF C6 41 89 04 24',
        AOB_YouthAcademyWeakFootChance = 'FF C7 89 06 48 8D 76 04 83 FF 06 7C C9',
        AOB_YouthAcademySkillMoveChance = '89 85 4C 01 00 00 4C',
        AOB_YouthAcademyGeneratePlayer = 'FF 40 32 F6 48 8B 9C 24 80 00 00 00',
        AOB_GENERATE_NEW_YA_REPORT = "8D 43 0E 89 44 24 3C",
        AOB_UniqueDribble = '44 8B 80 84 01 00 00',
        AOB_UniqueSprint = '45 8B 8A 84 01 00 00',
        AOB_ChangeStadium = '45 8B B4 24 24 17 00 00',
        AOB_MatchHalfLength = '45 8B 84 24 48 17 00 00',
        AOB_TODDisplay = '48 8B 03 4C 8B 90 38 02 00 00',
        AOB_TODReal = '4C 8B CF 49 8B CD B8',
        AOB_MatchWeather = '41 83 FF FF 44 0F 44 7D 68 41',
        AOB_EditCareerUsers = '8B 03 89 45 90 8B',
        AOB_GameSettingsCam = '8B 7C C6 58 89 7D 68',
        AOB_CustomManagerEditable = 'C7 45 7C 0F 27 00 00',

        -- PAP
        AOB_AgreeTransferRequest = "41 89 C5 48 8B 89 98 01 00 00",
        AOB_PAP_NEW_OFFER = "8B 81 9C 01 00 00 83 F8 FF",
        AOB_PAPAccompl = "8B 84 A9 18 07 00 00",
        AOB_BDRanges = "8B 49 78 3B D1",

        -- FREE CAM
        AOB_CAM_TARGET = "0F 11 AB 60 0B 00 00",

        AOB_CAM_ROTATE = "F3 0F 11 83 C8 05 00 00 F3",
        AOB_CAM_V_ROTATE_SPEED_MUL = "F3 0F 5E C7 F3 0F 11 83 B0 0B 00 00",
        AOB_CAM_H_ROTATE_SPEED_MUL = "F3 0F 11 83 AC 0B 00 00",
        AOB_CAM_Z_ROTATE_SPEED_MUL = "F3 0F 11 83 B4 0B 00 00 F3",
        AOB_STADIUM_BOUNDARY = "0F 10 32 0F 28 C6 0F 29",
        AOB_CAM_Z_BOUNDARY = "66 0F 70 0A 55 0F 28",
        AOB_FULL_ANGLE_ROTV = "F3 0F 10 40 60 F3 0F 58 83 B4",

        -- FootballCompEng_Win64_retail.dll
        FootballCompEng = {
            MODULE_NAME = 'FootballCompEng_Win64_retail.dll',
            AOBS = {
                AOB_Calendar = "33 D2 48 89 54 24 48 48 8B 4F 18",
                AOB_MatchFixing = "48 8B 13 48 81 C2 80 03 00 00",
                AOB_MatchFixingGoals = "48 8B 1C C8 48 85 DB 74 C7 48 8B 4E 20",
            }
        }

        -- KERNELBASE.dll
        -- KERNELBASE = {
        --     MODULE_NAME = 'KERNELBASE.dll',
        --     AOBS = {
        --         AOB_LoadLibraryA = "48 89 5C 24 08 48 89 74 24 10 57 48 83 EC 20 48 8B F9 48 85",
        --     }
        -- }
    }
end

-- load content from .ini files
function load_lang()
    if CFG_DATA.language == nil then
        do_log("Problem with config. Loading default cfg.")
        CFG_DATA = default_cfg()
    end

    local langfile = "languages/" .. CFG_DATA.language.current .. "/live_editor.mo"
    if file_exists(langfile) then
        do_log(string.format('Loading .mo file: %s', langfile), 'INFO')
        _ = mo(langfile)
    end
end
function load_theme()
    if file_exists("themes.ini") then
        do_log('Loading Theme from themes.ini', 'INFO')
        local themes = LIP.load("themes.ini")

        if CFG_DATA.theme == nil then
            CFG_DATA.theme = {
                default = 'dark',
                current = 'dark'
            }
            return 0
        end

        return themes[CFG_DATA.theme.current]
    else
        do_log('File themes.ini not found', 'WARNING')

        CFG_DATA.theme.current = 'dark'
        return 0
    end
end
function load_cfg()
    if file_exists("config.ini") then
        CACHE_DIR = 'cache/'
        OFFSETS_FILE_PATH = 'offsets.ini'
        CONFIG_FILE_PATH = 'config.ini'
    elseif not file_exists(CONFIG_FILE_PATH) then
        local data = default_cfg()
        create_dirs()

        local status, err = pcall(LIP.save, CONFIG_FILE_PATH, data)
        do_log(string.format('cfg file not found at %s - loading default data', CONFIG_FILE_PATH), 'INFO')
        local data = default_cfg()
        create_dirs()

        local status, err = pcall(LIP.save, CONFIG_FILE_PATH, data)

        if not status then
            do_log(string.format('LIP.SAVE FAILED for %s with err: %s', CONFIG_FILE_PATH, err))
            CACHE_DIR = 'cache/'
            OFFSETS_FILE_PATH = 'offsets.ini'
            CONFIG_FILE_PATH = 'config.ini'
            data.directories.cache_dir = CACHE_DIR
            local status, err = pcall(LIP.save, CONFIG_FILE_PATH, data)
        end
    end

    if file_exists(CONFIG_FILE_PATH) then
        do_log(string.format('Loading CFG_DATA from %s', CONFIG_FILE_PATH), 'INFO')
        local cfg = LIP.load(CONFIG_FILE_PATH);

        if cfg.directories then
            CACHE_DIR = cfg.directories.cache_dir
        end

        if cfg.flags then
            if cfg.flags.hide_ce_scanner == nil then
                cfg.flags.debug_mode = false
            end

            if cfg.flags.check_for_update == nil then
                cfg.flags.check_for_update = true
            end

            if cfg.flags.only_check_for_free_update == nil then
                cfg.flags.only_check_for_free_update = false
            end

            DEBUG_MODE = cfg.flags.debug_mode

            if cfg.flags.hide_ce_scanner == nil then
                cfg.flags.hide_ce_scanner = true
            end

            HIDE_CE_SCANNER = cfg.flags.hide_ce_scanner

            if cfg.flags.cache_players_data == nil then
                cfg.flags.cache_players_data = false
            end

            if cfg.flags.hide_players_potential == nil then
                cfg.flags.hide_players_potential = false
            end
        end

        if cfg.other then
            if cfg.other.ignore_update == nil then
                cfg.other.ignore_update = "20.1.0.0"
            end
        end

        return cfg
    end
    return default_cfg()
end

function default_cfg()
    local data = {
        flags = {
            debug_mode = DEBUG_MODE,
            deactive_on_close = false,
            hide_ce_scanner = true,
            check_for_update = true,
            only_check_for_free_update = false,
            cache_players_data = false,
            hide_players_potential = false
        },
        directories = {
            cache_dir = CACHE_DIR
        },
        game =
        {
            name = string.format('FIFA%s.exe', FIFA),
            name_trial = string.format('FIFA%s_TRIAL.exe', FIFA)
        },
        gui = {
            opacity = 255
        },
        auto_activate = {
            7,      -- Scripts
            12      -- FIFA Database Tables
        },
        hotkeys = {
            sync_with_game = 'VK_F5',
            search_player_by_id = 'VK_RETURN'
        },
        theme = {
            default = 'dark',
            current = 'dark'
        },
        language = {
            default = 'en_US',
            current = 'en_US'
        },
        other = {
            ignore_update = "20.1.0.0"
        }
    };

    return data
end

function save_cfg()
    if CFG_DATA == nil then 
        do_log('CFG_DATA is nil - save_cfg failed', 'WARNING')
        return 
    end
    do_log(string.format('Saving CFG_DATA to %s', CONFIG_FILE_PATH), 'INFO')
    LIP.save(CONFIG_FILE_PATH, CFG_DATA);
end

function load_offsets()
    if file_exists(OFFSETS_FILE_PATH) then
        do_log(string.format('Loading OFFSETS_DATA from %s', OFFSETS_FILE_PATH), 'INFO')
        return LIP.load(OFFSETS_FILE_PATH);
    else
        do_log(string.format('offsets file not found at %s - loading default data', OFFSETS_FILE_PATH), 'INFO')
        local data =
        {
            offsets =
            {
                AOB_AltTab = nil,
            },
        };
        LIP.save(OFFSETS_FILE_PATH, data);
        return data
    end

end

function save_offsets()
    if OFFSETS_DATA == nil then 
        do_log('OFFSETS_DATA is nil - save_offsets failed', 'WARNING')
        return 
    end
    LIP.save(OFFSETS_FILE_PATH, OFFSETS_DATA);
end



function load_playernames()
    local playernames_file_path = "other/playernames.csv"
    do_log(string.format("Loading playernames: %s", playernames_file_path))
    if file_exists(playernames_file_path) then
        for line in io.lines(playernames_file_path) do
            local values = split(line, ',')
            local name = values[1]
            local nameid = tonumber(values[2])
            -- local commentaryid = values[3]
            FIFA_PLAYERNAMES[nameid] = name
        end
        do_log("Playernames loaded.")
    end
end


function cache_players()
    local IsCMCached = readInteger("IsCMCached") or 0
    local cache_players_data_flag = 'false'
    if CFG_DATA.flags.cache_players_data then
        cache_players_data_flag = 'true'
    end
    do_log(string.format(
        "cache_players: IsCMCached: %d, flag: %s", 
        IsCMCached,
        cache_players_data_flag
    ))

    if IsCMCached == 0 and CFG_DATA.flags.cache_players_data then
        CACHED_PLAYERS = {}
        local firstname = ''
        local surname = ''
        local jerseyname = ''
        local commonname = ''
        local knownas = ''
        local fullname = '' -- For search by name

        local skintonecode = 0
        local headtypecode = 0
        local haircolorcode = 0

        local i = 0
        local sizeOf = DB_TABLE_SIZEOF['EDITEDPLAYERNAMES']

        dict_editedplayernames = {}
        do_log("iterate editedplayernames")
        local is_record_valid = true
        while true do
            local address = (readPointer('firsteditedplayernamesDataPtr') + i*sizeOf)
            local playerid_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['EDITEDPLAYERNAMES_PLAYERID'])
            local current_playerid = bAnd(bShr(readInteger(string.format('[%s]+%X', 'firsteditedplayernamesDataPtr', playerid_record.getOffset(0)+(i*sizeOf))), playerid_record.Binary.Startbit), (bShl(1, playerid_record.Binary.Size) - 1))
            is_record_valid = true
            if current_playerid == 0 then
                is_record_valid = false
            end
            if is_record_valid and (not _is_record_valid(address, sizeOf)) then
                is_record_valid = false
            end
            if is_record_valid then
                local firstname_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['EDITEDPLAYERNAMES_FIRSTNAME'])
                local edited_firstname = readString(string.format(
                    '[%s]+%X',
                    'firsteditedplayernamesDataPtr',
                    firstname_record.getOffset(0)+(i*sizeOf)
                ))

                local surname_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['EDITEDPLAYERNAMES_SURNAME'])
                local edited_surname = readString(string.format(
                    '[%s]+%X',
                    'firsteditedplayernamesDataPtr',
                    surname_record.getOffset(0)+(i*sizeOf)
                ))

                local jerseyname_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['EDITEDPLAYERNAMES_PLAYERJERSEYNAME'])
                local edited_jerseyname = readString(string.format(
                    '[%s]+%X',
                    'firsteditedplayernamesDataPtr',
                    jerseyname_record.getOffset(0)+(i*sizeOf)
                ))

                local commonname_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['EDITEDPLAYERNAMES_COMMONNAME'])
                local edited_commonname = readString(string.format(
                    '[%s]+%X',
                    'firsteditedplayernamesDataPtr',
                    commonname_record.getOffset(0)+(i*sizeOf)
                ))

                dict_editedplayernames[current_playerid] = {
                    firstname=edited_firstname,
                    surname=edited_surname,
                    jerseyname=edited_jerseyname,
                    commonname=edited_commonname
                }
            end
            i = i + 1
            if i >= DB_TABLE_RECORDS_LIMIT['EDITEDPLAYERNAMES'] then
                break
            end
        end

        i = 0
        sizeOf = DB_TABLE_SIZEOF['DCPLAYERNAMES']
        dict_dcplayernames = {}
        do_log("iterate dcplayernames")
        while true do
            is_record_valid = true
            local address = (readPointer('firstdcplayernamesDataPtr') + i*sizeOf)
            local nameid_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['DCPLAYERNAMES_NAMEID'])
            local current_nameid = bAnd(bShr(readInteger(string.format('[%s]+%X', 'firstdcplayernamesDataPtr', nameid_record.getOffset(0)+(i*sizeOf))), nameid_record.Binary.Startbit), (bShl(1, nameid_record.Binary.Size) - 1))
            
            if current_nameid == 0 then
                is_record_valid = false
            end
            if is_record_valid and (not _is_record_valid(address, sizeOf)) then
                is_record_valid = false
            end
            if is_record_valid then
                current_nameid = current_nameid + 34000 --rangelow
                local dcname_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['DCPLAYERNAMES_NAME'])
                local dcname = readString(string.format(
                    '[%s]+%X',
                    'firstdcplayernamesDataPtr',
                    dcname_record.getOffset(0)+(i*sizeOf)
                ))
                dict_dcplayernames[current_nameid] = dcname
            end
            i = i + 1
            if i >= DB_TABLE_RECORDS_LIMIT['DCPLAYERNAMES'] then
                break
            end
        end

        i = 0
        sizeOf = DB_TABLE_SIZEOF['PLAYERS']
        do_log("iterate players")
        while true do
            is_record_valid = true
            local address = (readPointer('firstPlayerDataPtr') + i*sizeOf)
            local playerid_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['PLAYERID'])
            local current_playerid = bAnd(bShr(readInteger(string.format('[%s]+%X', 'firstPlayerDataPtr', playerid_record.getOffset(0)+(i*sizeOf))), playerid_record.Binary.Startbit), (bShl(1, playerid_record.Binary.Size) - 1))
            if current_playerid == 0 then
                is_record_valid = false
            end
            if is_record_valid and (not _is_record_valid(address, sizeOf)) then
                is_record_valid = false
            end

            if is_record_valid then
                firstname = ''
                surname = ''
                jerseyname = ''
                commonname = ''
                knownas = ''
                fullname = '' -- For search by name

                skintonecode = 0
                headtypecode = 0
                haircolorcode = 0

                local editedplayername = dict_editedplayernames[current_playerid]

                if editedplayername then
                    firstname = editedplayername['firstname']
                    surname = editedplayername['surname']
                    jerseyname = editedplayername['jerseyname']
                    commonname = editedplayername['commonname']
                else
                    local firstnameid_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['FIRSTNAMEID'])
                    local current_firstnameid = bAnd(bShr(readInteger(string.format('[%s]+%X', 'firstPlayerDataPtr', firstnameid_record.getOffset(0)+(i*sizeOf))), firstnameid_record.Binary.Startbit), (bShl(1, firstnameid_record.Binary.Size) - 1))
                    if current_firstnameid > 0 then
                        if dict_dcplayernames[current_firstnameid] then
                            firstname = dict_dcplayernames[current_firstnameid]
                        elseif FIFA_PLAYERNAMES[current_firstnameid] then
                            firstname = FIFA_PLAYERNAMES[current_firstnameid]
                        end
                    end
                    local lastnameid_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['LASTNAMEID'])
                    local current_lastnameid = bAnd(bShr(readInteger(string.format('[%s]+%X', 'firstPlayerDataPtr', lastnameid_record.getOffset(0)+(i*sizeOf))), lastnameid_record.Binary.Startbit), (bShl(1, lastnameid_record.Binary.Size) - 1))
                    if current_lastnameid > 0 then
                        if dict_dcplayernames[current_lastnameid] then
                            surname = dict_dcplayernames[current_lastnameid]
                        elseif FIFA_PLAYERNAMES[current_lastnameid] then
                            surname = FIFA_PLAYERNAMES[current_lastnameid]
                        end
                    end
                    local commonnameid_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['COMMONNAMEID'])
                    local current_commonnameid = bAnd(bShr(readInteger(string.format('[%s]+%X', 'firstPlayerDataPtr', commonnameid_record.getOffset(0)+(i*sizeOf))), commonnameid_record.Binary.Startbit), (bShl(1, commonnameid_record.Binary.Size) - 1))
                    if current_commonnameid > 0 then
                        if dict_dcplayernames[current_commonnameid] then
                            commonname = dict_dcplayernames[current_commonnameid]
                        elseif FIFA_PLAYERNAMES[current_commonnameid] then
                            commonname = FIFA_PLAYERNAMES[current_commonnameid]
                        end
                    end
                    local jerseynameid_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['PLAYERJERSEYNAMEID'])
                    local current_jerseynameid = bAnd(bShr(readInteger(string.format('[%s]+%X', 'firstPlayerDataPtr', jerseynameid_record.getOffset(0)+(i*sizeOf))), jerseynameid_record.Binary.Startbit), (bShl(1, jerseynameid_record.Binary.Size) - 1))
                    if current_jerseynameid > 0 then
                        if dict_dcplayernames[current_jerseynameid] then
                            jerseyname = dict_dcplayernames[current_jerseynameid]
                        elseif FIFA_PLAYERNAMES[current_jerseynameid] then
                            jerseyname = FIFA_PLAYERNAMES[current_jerseynameid]
                        end
                    end
                end
                fullname = string.lower(string.format(
                    "%s %s %s %s",
                    firstname,
                    surname,
                    jerseyname,
                    commonname
                ))
                if commonname == '' then
                    knownas = string.format(
                        "%s. %s",
                        string.sub(firstname, 1, 1),
                        surname
                    )
                else
                    knownas = commonname
                end

                local skintonecode_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['SKINTONECODE'])
                skintonecode = bAnd(bShr(readInteger(string.format('[%s]+%X', 'firstPlayerDataPtr', skintonecode_record.getOffset(0)+(i*sizeOf))), skintonecode_record.Binary.Startbit), (bShl(1, skintonecode_record.Binary.Size) - 1))

                local headtypecode_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['HEADTYPECODE'])
                headtypecode = bAnd(bShr(readInteger(string.format('[%s]+%X', 'firstPlayerDataPtr', headtypecode_record.getOffset(0)+(i*sizeOf))), headtypecode_record.Binary.Startbit), (bShl(1, headtypecode_record.Binary.Size) - 1))

                local haircolorcode_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['HAIRCOLORCODE'])
                haircolorcode = bAnd(bShr(readInteger(string.format('[%s]+%X', 'firstPlayerDataPtr', haircolorcode_record.getOffset(0)+(i*sizeOf))), haircolorcode_record.Binary.Startbit), (bShl(1, haircolorcode_record.Binary.Size) - 1))

                CACHED_PLAYERS[current_playerid] = {
                    addr=address,
                    playerid=current_playerid,
                    firstname=firstname,
                    surname=surname,
                    jerseyname=jerseyname,
                    commonname=commonname,
                    knownas=knownas,
                    fullname=fullname,
                    skintonecode=skintonecode,
                    headtypecode=headtypecode,
                    haircolorcode=haircolorcode
                }
            end

            i = i + 1
            if i >= DB_TABLE_RECORDS_LIMIT['PLAYERS'] then
                break
            end
        end
        do_log("iterate players end")
        writeInteger("IsCMCached", 1)
    end

    do_log("cache_players - ok")
end
-- end
