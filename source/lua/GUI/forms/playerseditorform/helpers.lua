PlayerTeamContext = {}


function check_if_has_unapplied_player_changes()
    if HAS_UNAPPLIED_PLAYER_CHANGES then
        if messageDialog("You have some unapplied changes in player editor\nDo you want to apply them?", mtInformation, mbYes,mbNo) == mrYes then
            ApplyChanges()
        else
            HAS_UNAPPLIED_PLAYER_CHANGES = false
        end
    end
end

function FillHeadTypeCB(args)
    -- Update data in HeadTypeGroupCB and HeadTypeCodeCB
    local head_type_code = nil
    if args then
        head_type_code = args['headtypecode']
    else
        head_type_code = tonumber(ADDR_LIST.getMemoryRecordByID(COMPONENTS_DESCRIPTION_PLAYER_EDIT['HeadTypeCodeCB']['id']).Value)
    end

    local i = 0
    local found = false
    for key, value in pairs(HEAD_TYPE_GROUPS) do
        local group = string.gsub(key, '_', ' ')
        PlayersEditorForm.HeadTypeGroupCB.items.add(group)
        
        if found ~= true then
            PlayersEditorForm.HeadTypeCodeCB.clear()
            for j = 1, #value do
                PlayersEditorForm.HeadTypeCodeCB.items.add(value[j])
                if value[j] == head_type_code then
                    PlayersEditorForm.HeadTypeGroupCB.ItemIndex = i
                    PlayersEditorForm.HeadTypeCodeCB.ItemIndex = j-1
                    found = true
                end
            end
            i = i + 1
        end
    end
end

PLAYEREDIT_HOTKEYS_OBJECTS = {}
function create_hotkeys(args)
    destroy_hotkeys()
    if CFG_DATA.hotkeys.sync_with_game then
        table.insert(PLAYEREDIT_HOTKEYS_OBJECTS, createHotkey(SyncImageClick, _G[CFG_DATA.hotkeys.sync_with_game]))
    end
    if CFG_DATA.hotkeys.search_player_by_id then
        -- Trigger correct action
        if args and args['sender'] then
            if args['sender'].Name == 'FindPlayerByNameFUTEdit' then
                table.insert(PLAYEREDIT_HOTKEYS_OBJECTS, createHotkey(SearchPlayerByNameFUTBtnClick, _G[CFG_DATA.hotkeys.search_player_by_id]))
            elseif args['sender'].Name == 'CopyCMFindPlayerByID' then
                table.insert(PLAYEREDIT_HOTKEYS_OBJECTS, createHotkey(CopyCMSearchPlayerByIDClick, _G[CFG_DATA.hotkeys.search_player_by_id]))
            end
        else
            table.insert(PLAYEREDIT_HOTKEYS_OBJECTS, createHotkey(SearchPlayerByIDClick, _G[CFG_DATA.hotkeys.search_player_by_id]))
        end
    end
end

function destroy_hotkeys()
    for i=1,#PLAYEREDIT_HOTKEYS_OBJECTS do
        PLAYEREDIT_HOTKEYS_OBJECTS[i].destroy()
    end
    PLAYEREDIT_HOTKEYS_OBJECTS = {}
end

function reset_components()
    for i=0, PlayersEditorForm.ComponentCount-1 do
        local component = PlayersEditorForm.Component[i]
        local component_class = component.ClassName
        -- clear
        if component_class == 'TCEEdit' then
            component.Text = ''
            component.OnChange = nil
        elseif component_class == 'TCETrackBar' then
            component.OnChange = nil
            component.Position = 1
            component.SelEnd = 1
        elseif component_class == 'TCEComboBox' then
            component.clear()
        end
    end
end

function roll_random_attributes(components)
    HAS_UNAPPLIED_PLAYER_CHANGES = true
    for i=1, #components do
        -- tmp disable onchange event
        local onchange_event = PlayersEditorForm[components[i]].OnChange
        PlayersEditorForm[components[i]].OnChange = nil
        PlayersEditorForm[components[i]].Text = math.random(ATTRIBUTE_BOUNDS['min'], ATTRIBUTE_BOUNDS['max'])
        PlayersEditorForm[components[i]].OnChange = onchange_event
    end
    update_trackbar(PlayersEditorForm[components[1]])
    recalculate_ovr(true)
end

-- Recalculate OVR
-- update_ovr_edit - bool. If true then value in OverallEdit will be updated
function math.round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

function update_total_stats()
    local sum = 0
    local attr_panel = PlayersEditorForm.AttributesPanel
    for i = 0, attr_panel.ControlCount-1 do
        for j=0, attr_panel.Control[i].ControlCount-1 do
            local comp = attr_panel.Control[i].Control[j]
            if comp.ClassName == 'TCEEdit' then
                sum = sum + tonumber(comp.Text)
            end
        end
    end

    if sum > 3366 then
        sum = 3366
    elseif sum < 0 then
        sum = 0
    end

    PlayersEditorForm.TotalStatsValueLabel.Caption = string.format(
        "%d / 3366", sum
    )
    PlayersEditorForm.TotalStatsValueBar.Position = sum
end

function recalculate_ovr(update_ovr_edit)
    local preferred_position_id = PlayersEditorForm.PreferredPosition1CB.ItemIndex
    if preferred_position_id == 1 then return end -- ignore SW

    -- top 3 values will be put in "Best At"
    local unique_ovrs = {}
    local top_ovrs = {}

    local calculated_ovrs = {}
    for posid, attributes in pairs(OVR_FORMULA) do
        local sum = 0
        for attr, perc in pairs(attributes) do
            local attr_val = tonumber(PlayersEditorForm[attr].Text)
            if attr_val == nil then
                return
            end
            sum = sum + (attr_val * perc)
        end
        sum = math.round(sum)
        unique_ovrs[sum] = sum

        calculated_ovrs[posid] = sum
    end
    if update_ovr_edit then
        PlayersEditorForm.OverallEdit.Text = calculated_ovrs[string.format("%d", preferred_position_id)] + tonumber(PlayersEditorForm.ModifierEdit.Text)
    end

    for k,v in pairs(unique_ovrs) do
        table.insert(top_ovrs, k)
    end

    table.sort(top_ovrs, function(a,b) return a>b end)

    -- Fill "Best At"
    local position_names = {
        ['1'] = {
            short = {},
            long = {},
            showhint = false
        },
        ['2'] = {
            short = {},
            long = {},
            showhint = false
        },
        ['3'] = {
            short = {},
            long = {},
            showhint = false
        }
    }
    -- remove useless pos
    local not_show = {
        4,6,9,11,13,15,17,19
    }
    for posid, ovr in pairs(calculated_ovrs) do
        for i = 1, #not_show do
            if tonumber(posid) == not_show[i] then
                goto continue
            end
        end
        for i = 1, 3 do
            if ovr == top_ovrs[i] then
                if #position_names[string.format("%d", i)]['short'] <= 2 then
                    table.insert(position_names[string.format("%d", i)]['short'], PlayersEditorForm.PreferredPosition1CB.Items[tonumber(posid)])
                elseif #position_names[string.format("%d", i)]['short'] == 3 then
                    table.insert(position_names[string.format("%d", i)]['short'], '...')
                    position_names[string.format("%d", i)]['showhint'] = true
                end
                table.insert(position_names[string.format("%d", i)]['long'], PlayersEditorForm.PreferredPosition1CB.Items[tonumber(posid)])
            end
        end
        ::continue::
    end

    for i = 1, 3 do
        if top_ovrs[i] then
            PlayersEditorForm[string.format("BestPositionLabel%d", i)].Caption = string.format("- %s: %d ovr", table.concat(position_names[string.format("%d", i)]['short'], '/'), top_ovrs[i])
            if position_names[string.format("%d", i)]['showhint'] then
                PlayersEditorForm[string.format("BestPositionLabel%d", i)].Hint = string.format("- %s: %d ovr", table.concat(position_names[string.format("%d", i)]['long'], '/'), top_ovrs[i])
                PlayersEditorForm[string.format("BestPositionLabel%d", i)].ShowHint = true
            else
                PlayersEditorForm[string.format("BestPositionLabel%d", i)].ShowHint = false
            end
        else
            PlayersEditorForm[string.format("BestPositionLabel%d", i)].Caption = '-'
            PlayersEditorForm[string.format("BestPositionLabel%d", i)].ShowHint = false
        end
    end

    update_total_stats()
end

function find_player_by_id(playerid)
    if type(playerid) == 'string' then
        playerid = tonumber(playerid)
    end

    -- return dict with playerid and teams
    if playerid <= 0 then
        do_log("Playerid must be higer than 0", 'ERROR')
        return false 
    elseif readPointer('firstPlayerDataPtr') == nil then
        do_log("firstPlayerDataPtr not initialized", 'ERROR')
        return false
    elseif readPointer('ptrFirstTeamplayerlinks') == nil then
        do_log("ptrFirstTeamplayerlinks not initialized", 'ERROR')
        return false
    end

    -- players table
    local sizeOf = DB_TABLE_SIZEOF['PLAYERS'] -- Size of one record in players database table (0x64)
    local player_addr = find_record_in_game_db(0, CT_MEMORY_RECORDS['PLAYERID'], playerid, sizeOf, 'firstPlayerDataPtr')['addr']

    if player_addr then
        -- Update in Cheat Table
        writeQword('playerDataPtr', player_addr)

        -- find team-player links
        playerid_record_id = CT_MEMORY_RECORDS['TPLINKS_PLAYERID']    -- PlayerID in teamplayerlinks table
        sizeOf = DB_TABLE_SIZEOF['TEAMPLAYERLINKS'] -- Size of one record in teamplayerlinks database table (0x10)

        PlayerTeamContext = {}
        local start = 0
        local team_ids = {}
        while true do
            local teamplayerlink = find_record_in_game_db(start, playerid_record_id, playerid, sizeOf, 'ptrFirstTeamplayerlinks')
            if teamplayerlink['addr'] == nil then break end
            start = start + teamplayerlink['index'] + 1

            writeQword('ptrTeamplayerlinks', teamplayerlink['addr'])
            local teamid = tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['TEAMID']).Value) + 1
            -- find league-team link
            local ltl_teamid_record_id = CT_MEMORY_RECORDS['LTL_TEAMID'] -- TeamID in leagueteamlinks table
            local ltl_sizeOf = DB_TABLE_SIZEOF['LEAGUETEAMLINKS'] -- Size of one record in leagueteamlinks database table (0x1C)
            local leagueteamlink_addr = find_record_in_game_db(0, ltl_teamid_record_id, teamid-1, ltl_sizeOf, 'leagueteamlinksDataFirstPtr', 2)['addr']
            if leagueteamlink_addr == nil then
                break 
            end

            writeQword('leagueteamlinksDataPtr', leagueteamlink_addr)
            
            local leagueid = tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['LEAGUEID']).Value) + 1
            local team_type = 'club'

            if leagueid == 76 then
                -- MLS ALL STARS/ADIDAS 
                team_type = 'all_stars'
            elseif leagueid == 78 or leagueid == 2136 then
                team_type = 'national'
            end

            -- elseif leagueid == 78 or leagueid == 2136 then
            --     teams['NationalTeam'] = {
            --         addr = teamplayerlink['addr']
            --     }
            -- else
            --     teams['Club'] = {
            --         addr = teamplayerlink['addr']
            --     }
            -- end
            PlayerTeamContext[teamid] = {
                addr = teamplayerlink['addr'],
                team_type = team_type
            }
            table.insert(team_ids, teamid)
        end
        -- set first team in CT
        if #team_ids >= 1 then
            writeQword('ptrTeamplayerlinks', PlayerTeamContext[team_ids[1]]['addr'])
        else
            do_log(string.format("No link for player with ID: %d.", playerid), 'WARNING')
        end
        return true
    else
        do_log(string.format("Unable to find player with ID: %d.", playerid), 'ERROR')
        return false
    end
end

function birthdate_to_age(args)
    do_log("birthdate_to_age")
    local curr_date_cal = tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['CURRDATE']).Value)
    if curr_date_cal == nil or curr_date_cal == 0 then
        -- 01.07.2019 -- FIFA 20
        local add_year = math.floor(11 + ((math.floor(FIFA - 20) * 365)))
        curr_date_cal = tonumber(string.format("%d0600", add_year))
    end
    local str_current_date = string.format("%d", 20080101 + curr_date_cal)
    do_log(string.format("str_current_date: %s", str_current_date))

    local current_date = os.time{
        year=tonumber(string.sub(str_current_date, 1, 4)),
        month=tonumber(string.sub(str_current_date, 5, 6)),
        day=tonumber(string.sub(str_current_date, 7, 8))
    }

    local birthdate = convert_from_days(args['birthdate']) or convert_from_days(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['BIRTHDATE']).Value)
    return math.floor(os.difftime(current_date, birthdate) / (24*60*60*365.25))
end

function update_trackbar(sender)
    local trackBarName = string.format("%sTrackBar", COMPONENTS_DESCRIPTION_PLAYER_EDIT[sender.Name]['group'])
    local valueLabelName = string.format("%sValueLabel", COMPONENTS_DESCRIPTION_PLAYER_EDIT[sender.Name]['group'])

    -- recalculate ovr of group of attrs
    local onchange_func = PlayersEditorForm[trackBarName].OnChange
    PlayersEditorForm[trackBarName].OnChange = nil

    local calc = AttributesTrackBarVal({
        component_name = trackBarName,
    })

    PlayersEditorForm[trackBarName].Position = calc
    PlayersEditorForm[trackBarName].SelEnd = calc
    PlayersEditorForm[valueLabelName].Caption = calc

    PlayersEditorForm[trackBarName].OnChange = onchange_func
end

function is_injured_visibility(visible)
    local b = nil
    if visible == 1 then
        visible = true
    else
        visible = false
    end

    PlayersEditorForm.InjuryLabel.Visible = visible
    PlayersEditorForm.InjuryCB.Visible = visible
    PlayersEditorForm.FullFitDateLabel.Visible = visible
    PlayersEditorForm.FullFitDateEdit.Visible = visible
end

function get_player_release_clause_addr(playerid)
    -- struct size
    local size_of = RLC_STRUCT['size']

    local rlc_ptr = readMultilevelPointer(
        readPointer("basePtrTeamFormMoraleRLC"),
        {0x0, 0x538, 0x0, 0x20, 0xB8}
    )

    local start_addr = readPointer(rlc_ptr+0x178)
    local end_addr = readPointer(rlc_ptr+RLC_STRUCT['end_offset'])

    if DEBUG_MODE then
        do_log("get_player_release_clause_addr")
        do_log(string.format("start_addr: %X", start_addr))
        do_log(string.format("end_addr: %X", end_addr))
    end

    if (not start_addr) or (not end_addr) then
        return nil
    end

    local list_len = ((end_addr - start_addr) // size_of) - 1
    if list_len > 28000 then
        list_len = 28000
    end

    if DEBUG_MODE then
        do_log(string.format("list_len: %d", list_len))
    end

    for i=0, list_len do
        local pid = readInteger(start_addr + RLC_STRUCT['pid'])
        if pid == playerid then
            return start_addr
        end

        start_addr = start_addr + size_of
    end
    return nil
end

function get_player_form_addr(playerid)
    -- struct size
    local size_of =  PLAYERFORM_STRUCT['size']

    local form_ptr = readMultilevelPointer(
        readPointer("basePtrTeamFormMoraleRLC"),
        {0x0, 0x538, 0x0, 0x20, 0x120, 0x1A8}
    ) + 8

    if DEBUG_MODE then
        do_log("get_player_form_addr")
        do_log(string.format("teamid: %d", readInteger(form_ptr-4)))
        do_log(string.format("start_addr: %X", form_ptr))
    end

    -- Max squad size = 52
    for i=0, 51, 1 do
        local pid = readInteger(form_ptr + PLAYERFORM_STRUCT['pid'])
        if pid == 4294967295 then
            return nil
        end
        if pid == playerid then
            return form_ptr
        end
        form_ptr = form_ptr + size_of
    end
    return nil
end

function get_player_morale_addr(playerid)
    -- struct size
    local size_of =  PLAYERMORALE_STRUCT['size']

    local morale_ptr = readMultilevelPointer(
        readPointer("basePtrTeamFormMoraleRLC"),
        {0x0, 0x538, 0x0, 0x20, 0x158}
    ) 

    -- teamid at morale_ptr + 0x8. May be bugged?

    local _start = readPointer(morale_ptr + 0x498)
    local _end = readPointer(morale_ptr + 0x4A0)

    if (not _start) or (not _end) then
        return nil
    end

    local squad_size = ((_end - _start) // size_of) + 1

    if DEBUG_MODE then
        do_log("get_player_morale_addr")
        do_log(string.format("teamid: %d", readInteger(morale_ptr+0x488)))
        do_log(string.format("squad_size: %d", squad_size))
        do_log(string.format("start_addr: %X", _start))
        do_log(string.format("end_addr: %X", _end))
    end

    morale_ptr = _start
    -- Max squad size = 52
    for i=0, squad_size, 1 do
        local pid = readInteger(morale_ptr + PLAYERMORALE_STRUCT['pid'])
        if pid == 0 then
            return nil
        end
        if pid == playerid then
            return morale_ptr
        end
        morale_ptr = morale_ptr + size_of
    end
    return nil
end

function get_player_fitness_addr(playerid, free)
    -- struct size
    local size_of =  INJ_FIT_STRUCT['size']

    local fitness_ptr = readMultilevelPointer(
        readPointer("basePtrStaminaInjures"),
        {0x0, 0x8, 0x5D8, 0x0}
    )

    if fitness_ptr == 0 or fitness_ptr == nil then
        return 0
    end

    local fitness_start = readPointer(fitness_ptr+0x1988)
    local fitness_end = readPointer(fitness_ptr+0x1990)

    if (not fitness_start) or (not fitness_end) then
        return nil
    end

    -- Probably limit is 2000 players, but better calc it
    local limit = (fitness_end-fitness_start)//size_of - 1

    local count = 0

    for i=0, limit do
        local pid = readInteger(fitness_start + INJ_FIT_STRUCT['pid'])
        local has_data = readInteger(fitness_start + INJ_FIT_STRUCT['has_data']) -- 1 or 0
        if has_data == 0 then
            if free and pid == 4294967295 then
                return fitness_start
            end
            goto continue
        end

        if (playerid > 0) and (pid == playerid) then
            return fitness_start
        end
        ::continue::
        fitness_start = fitness_start + size_of
    end

    return 0
end

function value_to_date(value)
    -- Convert value from the game to human readable form (format: DD/MM/YYYY)
    -- ex. 20180908 -> 08/09/2018
    local to_string = string.format('%d', value)
    return string.format(
        '%s/%s/%s',
        string.sub(to_string, 7),
        string.sub(to_string, 5, 6),
        string.sub(to_string, 1, 4)
    )
end

function date_to_value(d)
    local m_date, _ = string.gsub(d, '%D', '')
    if string.len(m_date) ~= 8 then
        local txt = string.format('Invalid date format: %s', d)
        do_log(txt, 'ERROR')
        return false
    end
    m_date = string.format(
        '%s%s%s',
        string.sub(m_date, 5),
        string.sub(m_date, 3, 4),
        string.sub(m_date, 1, 2)
    )
    return tonumber(m_date)
end

function load_player_release_clause(playerid, is_cm_loaded)
    if not playerid then
        return
    end
    if not is_cm_loaded then
        PlayersEditorForm.ReleaseClauseEdit.Visible = false
        PlayersEditorForm.ReleaseClauseLabel.Visible = false
        return
    else
        PlayersEditorForm.ReleaseClauseEdit.Visible = true
        PlayersEditorForm.ReleaseClauseLabel.Visible = true
    end
    do_log(string.format("load_player_release_clause. PlayerID: %d", playerid))

    local addr = get_player_release_clause_addr(playerid)
    
    if addr == nil then
        PlayersEditorForm.ReleaseClauseEdit.Text = "None"
        return
    end

    if DEBUG_MODE then
        do_log(string.format("addr: %X", addr))
    end

    PlayersEditorForm.ReleaseClauseEdit.Text = readInteger(addr+RLC_STRUCT['value'])
end

function load_player_morale(playerid, is_cm_loaded)
    if not playerid then
        PlayersEditorForm.MoraleCB.Visible = false
        PlayersEditorForm.MoraleLabel.Visible = false
        return
    end
    if not is_cm_loaded then
        PlayersEditorForm.MoraleCB.Visible = false
        PlayersEditorForm.MoraleLabel.Visible = false
        return
    else
        PlayersEditorForm.MoraleCB.Visible = true
        PlayersEditorForm.MoraleLabel.Visible = true
    end
    do_log(string.format("load_player_morale. PlayerID: %d", playerid))
    local addr = get_player_morale_addr(playerid)
    if addr == nil then
        PlayersEditorForm.MoraleCB.Visible = false
        PlayersEditorForm.MoraleLabel.Visible = false
        return
    end

    local morale = readInteger(addr+PLAYERMORALE_STRUCT['morale_val'])

    if morale <= 35 then
        morale_level = 0    -- VERY_LOW
    elseif morale <= 55 then
        morale_level = 1    -- LOW
    elseif morale <= 70 then
        morale_level = 2    -- NORMAL
    elseif morale <= 85 then
        morale_level = 3    -- HIGH
    else
        morale_level = 4    -- VERY_HIGH
    end

    PlayersEditorForm.MoraleCB.Visible = true
    PlayersEditorForm.MoraleLabel.Visible = true
    PlayersEditorForm.MoraleCB.ItemIndex = morale_level
end

function load_player_match_form(playerid, is_cm_loaded)
    if not playerid then
        PlayersEditorForm.FormCB.Visible = false
        PlayersEditorForm.FormLabel.Visible = false
        return
    end
    if not is_cm_loaded then
        PlayersEditorForm.FormCB.Visible = false
        PlayersEditorForm.FormLabel.Visible = false
        return
    else
        PlayersEditorForm.FormCB.Visible = true
        PlayersEditorForm.FormLabel.Visible = true
    end
    do_log(string.format("load_player_match_form. PlayerID: %d", playerid))
    local addr = get_player_form_addr(playerid)
    if addr == nil then
        PlayersEditorForm.FormCB.Visible = false
        PlayersEditorForm.FormLabel.Visible = false
        return
    end

    local form = readInteger(addr+PLAYERFORM_STRUCT['form'])
    if form < 1 then
        do_log(string.format("Invalid player form! %d - %d", form, playerid), 'ERROR')
        form = 1
    elseif form > 5 then
        do_log(string.format("Invalid player form! %d - %d", form, playerid), 'ERROR')
        form = 5
    end

    -- local fcb_on_change = PlayersEditorForm.FormCB.OnChange
    -- PlayersEditorForm.FormCB.OnChange = nil

    PlayersEditorForm.FormCB.Visible = true
    PlayersEditorForm.FormLabel.Visible = true
    PlayersEditorForm.FormCB.ItemIndex = form - 1

    -- PlayersEditorForm.IsInjuredCB.OnChange = fcb_on_change

    -- local possible_forms = {
    --     "Bad", "Poor", "Okay", "Good", "Excellent"
    -- }
end

function load_player_fitness(playerid, is_cm_loaded)
    if not playerid then
        return
    end

    if not is_cm_loaded then
        PlayersEditorForm.IsInjuredCB.Visible = false
        PlayersEditorForm.InjuredLabel.Visible = false
        PlayersEditorForm.InjuryCB.Visible = false
        PlayersEditorForm.InjuryLabel.Visible = false
        PlayersEditorForm.DurabilityEdit.Visible = false
        PlayersEditorForm.DurabilityLabel.Visible = false
        PlayersEditorForm.FullFitDateEdit.Visible = false
        PlayersEditorForm.FullFitDateLabel.Visible = false
        return
    else
        PlayersEditorForm.IsInjuredCB.Visible = true
        PlayersEditorForm.InjuredLabel.Visible = true
        PlayersEditorForm.InjuryCB.Visible = true
        PlayersEditorForm.InjuryLabel.Visible = true
        PlayersEditorForm.DurabilityEdit.Visible = true
        PlayersEditorForm.DurabilityLabel.Visible = true
        PlayersEditorForm.FullFitDateEdit.Visible = true
        PlayersEditorForm.FullFitDateLabel.Visible = true
    end
    do_log(string.format("load_player_fitness. PlayerID: %d", playerid))

    local iicb_on_change = PlayersEditorForm.IsInjuredCB.OnChange
    local icb_on_change = PlayersEditorForm.InjuryCB.OnChange
    local de_on_change = PlayersEditorForm.DurabilityEdit.OnChange
    local ffde_on_change = PlayersEditorForm.FullFitDateEdit.OnChange

    PlayersEditorForm.IsInjuredCB.OnChange = nil
    PlayersEditorForm.InjuryCB.OnChange = nil
    PlayersEditorForm.DurabilityEdit.OnChange = nil
    PlayersEditorForm.FullFitDateEdit.OnChange = nil

    local component = PlayersEditorForm.InjuryCB
    component.clear()

    local dropdown = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['INJURY_TYPE'])
    local dropdown_items = dropdown.DropDownList
    local dropdown_selected_value = dropdown.Value
    for j = 0, dropdown_items.Count-1 do
        local val, desc = string.match(dropdown_items[j], "(%d+): '(.+)'")

        -- Fill combobox in GUI with values from memory record dropdown
        component.items.add(desc)

        -- Set active item & update hint
        -- if dropdown_selected_value == val then
        --     component.ItemIndex = j
        --     component.Hint = desc
        -- end
    end

    local addr = get_player_fitness_addr(playerid)
    if addr == 0 then
        PlayersEditorForm.IsInjuredCB.ItemIndex = 0
        PlayersEditorForm.InjuryCB.ItemIndex = 0
        PlayersEditorForm.FullFitDateEdit.Text = "01/01/2008"
        PlayersEditorForm.DurabilityEdit.Text = "100%"
    else
        local injury_type = readInteger(addr + INJ_FIT_STRUCT['inj_type'])
        PlayersEditorForm.DurabilityEdit.Text = string.format(
            "%d%%", readInteger(addr + INJ_FIT_STRUCT['fitness'])
        )

        if injury_type > 0 then
            PlayersEditorForm.IsInjuredCB.ItemIndex = 1
            PlayersEditorForm.InjuryCB.ItemIndex = injury_type
            PlayersEditorForm.FullFitDateEdit.Text = value_to_date(
                readInteger(addr + INJ_FIT_STRUCT['fit_on'])
            )
        else
            PlayersEditorForm.IsInjuredCB.ItemIndex = 0
            PlayersEditorForm.InjuryCB.ItemIndex = 0
            PlayersEditorForm.FullFitDateEdit.Text = "01/01/2008"
        end

    end

    is_injured_visibility(PlayersEditorForm.IsInjuredCB.ItemIndex)

    PlayersEditorForm.IsInjuredCB.OnChange = iicb_on_change
    PlayersEditorForm.InjuryCB.OnChange = icb_on_change
    PlayersEditorForm.DurabilityEdit.OnChange = de_on_change
    PlayersEditorForm.FullFitDateEdit.OnChange = ffde_on_change
end

function save_player_release_clause(playerid)
    if not playerid then
        return
    end
    do_log(string.format("save_player_release_clause. PlayerID: %d", playerid))
    -- remove non-digits
    local release_clause, _ = string.gsub(
        PlayersEditorForm.ReleaseClauseEdit.Text,
        '%D', ''
    )
    release_clause = tonumber(release_clause) -- remove non-digits

    local addr = get_player_release_clause_addr(playerid)
    local teamid = 0
    local add_clause = false
    local remove_clause = false
    local edit_clause = false
    if addr == nil then
        if (not release_clause) or (release_clause <= 0) then
            return
        elseif (release_clause >= 2147483646) then
            do_log(string.format("Invalid release clause - %d", release_clause), 'INFO')
            release_clause = 2147483646
        end
        teamid = inputQuery("Create release clause", "Enter player current teamid:", "0")
        if not teamid or tonumber(teamid) <= 0 then
            do_log(string.format("Release clause\nEnter Valid TeamID\n %s is invalid.", teamid), 'ERROR')
            return
        end
        add_clause = true
    else
        if readInteger(addr+RLC_STRUCT['value']) == release_clause then
            -- No change
            return
        end

        if (not release_clause) or (release_clause <= 0) then
            remove_clause = true
        elseif (release_clause >= 2147483646) then
            do_log(string.format("Invalid release clause - %d", release_clause), 'INFO')
            release_clause = 2147483646
        else
            teamid = readInteger(addr+RLC_STRUCT['tid'])
            edit_clause = true
        end
    end

    -- fix size
    local rlc_ptr = readMultilevelPointer(
        readPointer("basePtrTeamFormMoraleRLC"),
        {0x0, 0x538, 0x0, 0x20, 0xB8}
    )
    if remove_clause then
        local end_addr = readPointer(rlc_ptr+RLC_STRUCT['end_offset'])
        local bytecount = end_addr - addr + RLC_STRUCT['size']
        local bytes = readBytes(addr+RLC_STRUCT['size'], bytecount, true)
        writeBytes(addr, bytes)
        writeQword(rlc_ptr+RLC_STRUCT['end_offset'], readPointer(rlc_ptr+RLC_STRUCT['end_offset'])-RLC_STRUCT['size'])
        return
    elseif add_clause then
        addr = readPointer(rlc_ptr+RLC_STRUCT['end_offset'])
        writeQword(rlc_ptr+RLC_STRUCT['end_offset'], readPointer(rlc_ptr+RLC_STRUCT['end_offset'])+RLC_STRUCT['size'])
    end
    writeInteger(addr, playerid)
    writeInteger(addr+4, teamid)
    writeInteger(addr+8, release_clause)

end

function save_player_morale(playerid)
    if not playerid then
        return
    end
    do_log(string.format("save_player_morale. PlayerID: %d", playerid))
    local addr = get_player_morale_addr(playerid)
    if addr == nil then
        return
    end

    local morale_level = PlayersEditorForm.MoraleCB.ItemIndex + 1
    local morale_vals = {
        15, 40, 65, 75, 95
    }

    local morale = morale_vals[morale_level]

    -- Will it be enough?
    writeInteger(addr+PLAYERMORALE_STRUCT['morale_val'], morale)
    writeInteger(addr+PLAYERMORALE_STRUCT['contract'], morale)
    writeInteger(addr+PLAYERMORALE_STRUCT['playtime'], morale)
end

function save_player_match_form(playerid)
    if not playerid then
        return
    end
    do_log(string.format("save_player_match_form. PlayerID: %d", playerid))
    local addr = get_player_form_addr(playerid)
    if addr == nil then
        return
    end

    local form = PlayersEditorForm.FormCB.ItemIndex+1

    if not form or form < 1 then
        do_log(string.format("Invalid player form! %d - %d", form, playerid), 'WARNING')
        form = 1
    elseif form > 5 then
        do_log(string.format("Invalid player form! %d - %d", form, playerid), 'WARNING')
        form = 5
    end

    -- Arrow
    writeInteger(addr+PLAYERFORM_STRUCT['form'], form)

    -- avg. needed for arrow?
    local form_vals = {
        25, 50, 65, 75, 90
    }
    local form_val = form_vals[form]

    -- Last 10 games?
    for i=0, 9 do
        local off = PLAYERFORM_STRUCT['last_games_avg_1'] + (i * 4)
        writeInteger(addr+off, form_val)
    end

    -- Avg from last 10 games?
    writeInteger(addr+PLAYERFORM_STRUCT['recent_avg'], form_val)
end

function save_player_fitness(playerid)
    do_log("save_player_fitness")
    if not playerid then
        return
    end
    do_log(string.format("save_player_fitness. PlayerID: %d", playerid))
    local addr = get_player_fitness_addr(playerid)
    local is_injured = PlayersEditorForm.IsInjuredCB.ItemIndex
    local stamina = PlayersEditorForm.DurabilityEdit.Text
    stamina = string.gsub(stamina, '%D', '')
    if addr == 0 and is_injured == 0 and stamina == "100" then
        return
    end

    if addr == 0 then
        addr = get_player_fitness_addr(0, true)
        if addr == 0 then
            do_log(
                "Unable to save player fitness. Limit reached (?)",
                'ERROR'
            )
            return
        end
    end
    stamina = tonumber(stamina)
    if not stamina or stamina > 100 then
        stamina = 100
    elseif stamina <= 1 then
        stamina = 2
    end

    local pid = writeInteger(addr + INJ_FIT_STRUCT['pid'], playerid)
    local teamid = writeInteger(addr + INJ_FIT_STRUCT['tid'], 4294967295) -- -1
    local has_data = writeInteger(addr + INJ_FIT_STRUCT['has_data'], 1)
    local fitness = writeInteger(addr + INJ_FIT_STRUCT['fitness'], stamina)

    if is_injured == 1 then
        local t = PlayersEditorForm.InjuryCB.ItemIndex
        if t == 0 then
            t = 1
        end
    
        local injury_unk = writeInteger(addr + INJ_FIT_STRUCT['unk1'], 1) -- ?
        local injury_unk2 = writeInteger(addr + INJ_FIT_STRUCT['unk2'], 6)
        local injury_type = writeInteger(addr + INJ_FIT_STRUCT['inj_type'], t)
        local fit_on = writeInteger(addr + INJ_FIT_STRUCT['fit_on'], date_to_value(
            PlayersEditorForm.FullFitDateEdit.Text
        ))  -- DATE: YYYYMMDD
        local injury_unk3 = writeInteger(addr + INJ_FIT_STRUCT['unk3'], 3)  -- 3 for injury??
        local is_match_fit = writeInteger(addr + INJ_FIT_STRUCT['regenerated'], 0) -- 1 or 0 ?
    else
        local injury_unk = writeInteger(addr + INJ_FIT_STRUCT['unk1'], 0) -- ?
        local injury_unk2 = writeInteger(addr + INJ_FIT_STRUCT['unk2'], 0)
        local injury_type = writeInteger(addr + INJ_FIT_STRUCT['inj_type'], 0)
        local fit_on = writeInteger(addr + INJ_FIT_STRUCT['fit_on'], 20080101)  -- DATE: YYYYMMDD
        local injury_unk3 = writeInteger(addr + INJ_FIT_STRUCT['unk3'], 0)  -- 3 for injury??
        local is_match_fit = writeInteger(addr + INJ_FIT_STRUCT['regenerated'], 3) -- 1 or 0 ?
    end
end

function AttributesTrackBarVal(args)
    local component_name = args['component_name']

    local comp_desc = COMPONENTS_DESCRIPTION_PLAYER_EDIT[component_name]

    local sum_attr = 0
    local items = 0

    if comp_desc['depends_on'] then
        for i=1, #comp_desc['depends_on'] do
            items = items + 1
            if PlayersEditorForm[comp_desc['depends_on'][i]].Text == '' then
                local r = COMPONENTS_DESCRIPTION_PLAYER_EDIT[comp_desc['depends_on'][i]]
                PlayersEditorForm[comp_desc['depends_on'][i]].Text = tonumber(ADDR_LIST.getMemoryRecordByID(r['id']).Value) + r['modifier']
            end
            sum_attr = sum_attr + tonumber(PlayersEditorForm[comp_desc['depends_on'][i]].Text)
        end
    end

    local result = math.ceil(sum_attr/items)
    if result > ATTRIBUTE_BOUNDS['max'] then
        result = ATTRIBUTE_BOUNDS['max']
    elseif result < ATTRIBUTE_BOUNDS['min'] then
        result = ATTRIBUTE_BOUNDS['min']
    end

    return result
end

-- Fill fields in Player Edit Form
function FillPlayerEditForm(playerid)

    if playerid ~= nil then
        find_player_by_id(playerid)
    end

    local new_val = 0
    for i=0, PlayersEditorForm.ComponentCount-1 do
        local component = PlayersEditorForm.Component[i]
        local component_name = component.Name
        local comp_desc = COMPONENTS_DESCRIPTION_PLAYER_EDIT[component_name]
        if comp_desc == nil then goto continue end

        local component_class = component.ClassName
        if component_class == 'TCEEdit' then
            -- clear
            component.OnChange = nil

            -- Update value of all edit fields
            if comp_desc['valFromFunc'] then
                component.Text = comp_desc['valFromFunc']({
                    comp_desc = comp_desc,
                })
            else
                component.Text = tonumber(ADDR_LIST.getMemoryRecordByID(comp_desc['id']).Value) + comp_desc['modifier']
            end

            if comp_desc['events'] then
                for key, value in pairs(comp_desc['events']) do
                    component[key] = value
                end
            else
                component.OnChange = CommonEditOnChange
            end
        elseif component_class == 'TCETrackBar' then
            if comp_desc['events'] then
                for key, value in pairs(comp_desc['events']) do
                    component[key] = value
                end
            end
        elseif component_class == 'TCEComboBox' then
            -- clear
            if not comp_desc['already_filled'] then
                component.clear()

                if comp_desc['valFromFunc'] then
                    comp_desc['valFromFunc']()
                else
                    local dropdown = ADDR_LIST.getMemoryRecordByID(comp_desc['id'])
                    local dropdown_items = dropdown.DropDownList
                    local dropdown_selected_value = dropdown.Value
                    for j = 0, dropdown_items.Count-1 do
                        local val, desc = string.match(dropdown_items[j], "(%d+): '(.+)'")
        
                        -- Fill combobox in GUI with values from memory record dropdown
                        component.items.add(desc)
        
                        -- Set active item & update hint
                        if dropdown_selected_value == val then
                            component.ItemIndex = j
                            component.Hint = desc
                        end
                    end
                end
            end

            -- Add events
            if comp_desc['events'] then
                for key, value in pairs(comp_desc['events']) do
                    component[key] = value
                end
            else
                component.OnChange = CommonCBOnChange
                component.OnDropDown = CommonCBOnDropDown
                component.OnMouseEnter = CommonCBOnMouseEnter
                component.OnMouseLeave = CommonCBOnMouseLeave
            end
        elseif component_class == 'TCECheckBox' then
            -- Set checkbox state
            component.State = tonumber(ADDR_LIST.getMemoryRecordByID(comp_desc['id']).Value)
        end
        ::continue::
    end

    -- Update trackbars
    local trackbars = {
        'AttackTrackBar',
        'DefendingTrackBar',
        'SkillTrackBar',
        'GoalkeeperTrackBar',
        'PowerTrackBar',
        'MovementTrackBar',
        'MentalityTrackBar',
    }
    for i=1, #trackbars do
        update_trackbar(PlayersEditorForm[trackbars[i]])
    end

    -- Load Img
    local ss_hs = load_headshot(
        tonumber(PlayersEditorForm.PlayerIDEdit.Text),
        tonumber(ADDR_LIST.getMemoryRecordByID(COMPONENTS_DESCRIPTION_PLAYER_EDIT['SkinColorCB']['id']).Value),
        tonumber(ADDR_LIST.getMemoryRecordByID(COMPONENTS_DESCRIPTION_PLAYER_EDIT['HeadTypeCodeCB']['id']).Value),
        tonumber(ADDR_LIST.getMemoryRecordByID(COMPONENTS_DESCRIPTION_PLAYER_EDIT['HairColorCB']['id']).Value)
    )
    PlayersEditorForm.Headshot.Picture.LoadFromStream(ss_hs)
    ss_hs.destroy()
    PlayersEditorForm.Headshot.stretch=true

    local ss_c = load_crest(tonumber(PlayersEditorForm.TeamIDEdit.Text))
    PlayersEditorForm.Crest64x64.Picture.LoadFromStream(ss_c)
    ss_c.destroy()
    PlayersEditorForm.Crest64x64.stretch=true

    local iPlayerID = tonumber(PlayersEditorForm.PlayerIDEdit.Text)

    local is_cm_loaded = is_cm_loaded()
    IS_CM_LOADED_AT_ENTER = is_cm_loaded
    -- Player info - fitness & injury
    load_player_fitness(iPlayerID, is_cm_loaded)

    -- Player info - form
    load_player_match_form(iPlayerID, is_cm_loaded)

    -- Player info - Morale
    load_player_morale(iPlayerID, is_cm_loaded)

    -- Player info - Release Clause
    load_player_release_clause(iPlayerID, is_cm_loaded)
    do_log("FillPlayerEditForm Finished")
end

function age_to_birthdate(args)
    do_log("age_to_birthdate")
    local current_age = birthdate_to_age(args)
    local component = args['component']
    local age = tonumber(component.Text)

    -- Don't overwrite age if not changed
    if current_age == age then
        return ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['BIRTHDATE']).Value
    end

    local comp_desc = args['comp_desc']

    local new_birthdate = nil
    local curr_date_cal = tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['CURRDATE']).Value)
    if curr_date_cal == nil or curr_date_cal == 0 then
        -- 01.07.2019 -- FIFA 20
        local add_year = math.floor(11 + ((math.floor(FIFA - 20) * 365)))
        curr_date_cal = tonumber(string.format("%d0600", add_year))
    end
    local str_current_date = string.format("%d", 20080101 + curr_date_cal)

    do_log(string.format("str_current_date: %s", str_current_date))

    new_birthdate = convert_to_days(os.time{
        year=tonumber(string.sub(str_current_date, 1, 4)) - age,
        month=tonumber(string.sub(str_current_date, 5, 6)),
        day=tonumber(string.sub(str_current_date, 7, 8))
    })

    return new_birthdate
end

-- From GUI to CT
function ApplyChangesToDropDown(dropdown, component)
    local dropdown_items = dropdown.DropDownList
    local dropdown_selected_value = dropdown.Value

    for j = 0, dropdown_items.Count-1 do
        local val, desc = string.match(dropdown_items[j], "(%d+): '(.+)'")
        if component.Items[component.ItemIndex] == desc then
            dropdown.Value = tonumber(val)
            return
        end
    end
end

function ApplyChanges()
    -- verify playerid 
    if ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['PLAYERID']).Value ~= PlayersEditorForm.PlayerIDEdit.Text then
        do_log(
            string.format("GUI was not synchronized with the game. playerid in GUI:%s playerid in game:%s .To prevent your save from damage, changes hasn't been applied", ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['PLAYERID']).Value, PlayersEditorForm.PlayerIDEdit.Text),
            'ERROR'
        )
        HAS_UNAPPLIED_PLAYER_CHANGES = false
        return
    end

    for i=0, PlayersEditorForm.ComponentCount-1 do
        local component = PlayersEditorForm.Component[i]
        local component_name = component.Name
        
        -- Just in case we somehow fail at validating playerid
        -- We can't allow that playerid will be changed
        if component_name == 'PlayerIDEdit' then goto continue end
        if component_name == 'TeamIDEdit' then goto continue end

        local comp_desc = COMPONENTS_DESCRIPTION_PLAYER_EDIT[component_name]
        if comp_desc == nil then goto continue end
        if comp_desc['id'] == nil then goto continue end
        local component_class = component.ClassName
        
        if component_class == 'TCEEdit' then
            if string.len(component.Text) <= 0 then
                do_log(
                    string.format("%s component is empty. Please, fill it and try again", component_name),
                    'ERROR'
                )
            end
            if comp_desc['onApplyChanges'] then
                ADDR_LIST.getMemoryRecordByID(comp_desc['id']).Value = comp_desc['onApplyChanges']({
                    component = component,
                    comp_desc = comp_desc,
                })
            else
                ADDR_LIST.getMemoryRecordByID(comp_desc['id']).Value = tonumber(component.Text) - comp_desc['modifier']
            end

        elseif component_class == 'TCEComboBox' then
            ApplyChangesToDropDown(ADDR_LIST.getMemoryRecordByID(comp_desc['id']), component)
        elseif component_class == 'TCECheckBox' then
            ADDR_LIST.getMemoryRecordByID(comp_desc['id']).Value = tonumber(component.State)
        end
        ::continue::
    end

    local iPlayerID = tonumber(PlayersEditorForm.PlayerIDEdit.Text)

    if IS_CM_LOADED_AT_ENTER then
        save_player_fitness(iPlayerID)
        save_player_match_form(iPlayerID)
        save_player_morale(iPlayerID)
        save_player_release_clause(iPlayerID)
    end

    HAS_UNAPPLIED_PLAYER_CHANGES = false
    showMessage("Player edited.")
end

function fut_copy_card_to_gui(player)

    local columns = {
        firstnameid = 1,
        lastnameid = 2,
        playerjerseynameid = 3,
        commonnameid = 4,
        skintypecode = 5,
        trait2 = 6,
        bodytypecode = 7,
        haircolorcode = 8,
        facialhairtypecode = 9,
        curve = 10,
        jerseystylecode = 11,
        agility = 12,
        tattooback = 13,
        accessorycode4 = 14,
        gksavetype = 15,
        positioning = 16,
        tattooleftarm = 17,
        hairtypecode = 18,
        standingtackle = 19,
        preferredposition3 = 20,
        longpassing = 21,
        penalties = 22,
        animfreekickstartposcode = 23,
        animpenaltieskickstylecode = 24,
        isretiring = 25,
        longshots = 26,
        gkdiving = 27,
        interceptions = 28,
        shoecolorcode2 = 29,
        crossing = 30,
        potential = 31,
        gkreflexes = 32,
        finishingcode1 = 33,
        reactions = 34,
        composure = 35,
        vision = 36,
        contractvaliduntil = 37,
        animpenaltiesapproachcode = 38,
        finishing = 39,
        dribbling = 40,
        slidingtackle = 41,
        accessorycode3 = 42,
        accessorycolourcode1 = 43,
        headtypecode = 44,
        sprintspeed = 45,
        height = 46,
        hasseasonaljersey = 47,
        tattoohead = 48,
        preferredposition2 = 49,
        strength = 50,
        shoetypecode = 51,
        birthdate = 52,
        preferredposition1 = 53,
        tattooleftleg = 54,
        ballcontrol = 55,
        shotpower = 56,
        trait1 = 57,
        socklengthcode = 58,
        weight = 59,
        hashighqualityhead = 60,
        gkglovetypecode = 61,
        tattoorightarm = 62,
        balance = 63,
        gender = 64,
        headassetid = 65,
        gkkicking = 66,
        internationalrep = 67,
        animpenaltiesmotionstylecode = 68,
        shortpassing = 69,
        freekickaccuracy = 70,
        skillmoves = 71,
        faceposerpreset = 72,
        usercaneditname = 73,
        avatarpomid = 74,
        attackingworkrate = 75,
        finishingcode2 = 76,
        aggression = 77,
        acceleration = 78,
        headingaccuracy = 79,
        iscustomized = 80,
        eyebrowcode = 81,
        runningcode2 = 82,
        modifier = 83,
        gkhandling = 84,
        eyecolorcode = 85,
        jerseysleevelengthcode = 86,
        accessorycolourcode3 = 87,
        accessorycode1 = 88,
        playerjointeamdate = 89,
        headclasscode = 90,
        defensiveworkrate = 91,
        tattoofront = 92,
        nationality = 93,
        preferredfoot = 94,
        sideburnscode = 95,
        weakfootabilitytypecode = 96,
        jumping = 97,
        personality = 98,
        gkkickstyle = 99,
        stamina = 100,
        playerid = 101,
        marking = 102,
        accessorycolourcode4 = 103,
        gkpositioning = 104,
        headvariation = 105,
        skillmoveslikelihood = 106,
        skintonecode = 107,
        shortstyle = 108,
        overallrating = 109,
        smallsidedshoetypecode = 110,
        emotion = 111,
        runstylecode = 112,
        jerseyfit = 113,
        accessorycode2 = 114,
        shoedesigncode = 115,
        shoecolorcode1 = 116,
        hairstylecode = 117,
        animpenaltiesstartposcode = 118,
        runningcode1 = 119,
        preferredposition4 = 120,
        volleys = 121,
        accessorycolourcode2 = 122,
        tattoorightleg = 123,
        facialhaircolorcode = 124
    }

    local comp_to_column = {
        -- FirstNameIDEdit = 'firstnameid',
        -- LastNameIDEdit = 'lastnameid',
        -- JerseyNameIDEdit = 'playerjerseynameid',
        -- CommonNameIDEdit = 'commonnameid',
        HairColorCB = "haircolorcode",
        FacialHairTypeEdit = "facialhairtypecode",
        CurveEdit = "curve",
        JerseyStyleEdit = "jerseystylecode",
        AgilityEdit = "agility",
        AccessoryEdit4 = "accessorycode4",
        GKSaveTypeEdit = "gksavetype",
        AttackPositioningEdit = "positioning",
        HairTypeEdit = "hairtypecode",
        StandingTackleEdit = "standingtackle",
        PreferredPosition3CB = "preferredposition3",
        LongPassingEdit = "longpassing",
        PenaltiesEdit = "penalties",
        AnimFreeKickStartPosEdit = "animfreekickstartposcode",
        AnimPenaltiesKickStyleEdit = "animpenaltieskickstylecode",
        IsRetiringCB = "isretiring",
        LongShotsEdit = "longshots",
        GKDivingEdit = "gkdiving",
        InterceptionsEdit = "interceptions",
        shoecolorEdit2 = "shoecolorcode2",
        CrossingEdit = "crossing",
        PotentialEdit = "potential",
        GKReflexEdit = "gkreflexes",
        FinishingCodeEdit1 = "finishingcode1",
        ReactionsEdit = "reactions",
        ComposureEdit = "composure",
        VisionEdit = "vision",
        AnimPenaltiesApproachEdit = "animpenaltiesapproachcode",
        FinishingEdit = "finishing",
        DribblingEdit = "dribbling",
        SlidingTackleEdit = "slidingtackle",
        AccessoryEdit3 = "accessorycode3",
        AccessoryColourEdit1 = "accessorycolourcode1",
        HeadTypeCodeCB = "headtypecode",
        SprintSpeedEdit = "sprintspeed",
        HeightEdit = "height",
        hasseasonaljerseyEdit = "hasseasonaljersey",
        PreferredPosition2CB = "preferredposition2",
        StrengthEdit = "strength",
        shoetypeEdit = "shoetypecode",
        AgeEdit = "birthdate",
        PreferredPosition1CB = "preferredposition1",
        BallControlEdit = "ballcontrol",
        ShotPowerEdit = "shotpower",
        socklengthEdit = "socklengthcode",
        WeightEdit = "weight",
        HasHighQualityHeadCB = "hashighqualityhead",
        GKGloveTypeEdit = "gkglovetypecode",
        BalanceEdit = "balance",
        HeadAssetIDEdit = "headassetid",
        GKKickingEdit = "gkkicking",
        InternationalReputationCB = "internationalrep",
        AnimPenaltiesMotionStyleEdit = "animpenaltiesmotionstylecode",
        ShortPassingEdit = "shortpassing",
        FreeKickAccuracyEdit = "freekickaccuracy",
        SkillMovesCB = "skillmoves",
        FacePoserPresetEdit = "faceposerpreset",
        AttackingWorkRateCB = "attackingworkrate",
        FinishingCodeEdit2 = "finishingcode2",
        AggressionEdit = "aggression",
        AccelerationEdit = "acceleration",
        HeadingAccuracyEdit = "headingaccuracy",
        EyebrowEdit = "eyebrowcode",
        runningcodeEdit2 = "runningcode2",
        ModifierEdit = "modifier",
        GKHandlingEdit = "gkhandling",
        EyeColorEdit = "eyecolorcode",
        jerseysleevelengthEdit = "jerseysleevelengthcode",
        AccessoryColourEdit3 = "accessorycolourcode3",
        AccessoryEdit1 = "accessorycode1",
        HeadClassCodeEdit = "headclasscode",
        DefensiveWorkRateCB = "defensiveworkrate",
        NationalityCB = "nationality",
        PreferredFootCB = "preferredfoot",
        SideburnsEdit = "sideburnscode",
        WeakFootCB = "weakfootabilitytypecode",
        JumpingEdit = "jumping",
        SkinTypeEdit = "skintypecode",
        GKKickStyleEdit = "gkkickstyle",
        StaminaEdit = "stamina",
        MarkingEdit = "marking",
        AccessoryColourEdit4 = "accessorycolourcode4",
        GKPositioningEdit = "gkpositioning",
        HeadVariationEdit = "headvariation",
        SkillMoveslikelihoodEdit = "skillmoveslikelihood",
        SkinColorCB = "skintonecode",
        shortstyleEdit = "shortstyle",
        OverallEdit = "overallrating",
        EmotionEdit = "emotion",
        JerseyFitEdit = "jerseyfit",
        AccessoryEdit2 = "accessorycode2",
        shoedesignEdit = "shoedesigncode",
        shoecolorEdit1 = "shoecolorcode1",
        HairStyleEdit = "hairstylecode",
        BodyTypeCB = "bodytypecode",
        AnimPenaltiesStartPosEdit = "animpenaltiesstartposcode",
        runningcodeEdit1 = "runningcode1",
        PreferredPosition4CB = "preferredposition4",
        VolleysEdit = "volleys",
        AccessoryColourEdit2 = "accessorycolourcode2",
        FacialHairColorEdit = "facialhaircolorcode"
    }

    local comp_to_fut = {
        OverallEdit = "ovr",
        LongShotsEdit = "longshotsaccuracy"
    }

    local playerid = tonumber(player['details']['base_playerid'])
    if DEBUG_MODE then
        print("baseplayerid")
        print(playerid)
    end

    if playerid == nil then
        do_log('COPY ERROR\n baseplayerid is nil:', 'ERROR')
        return
    end
    local fix_playerids = {
        _9999931 = 7763,
    }
    local fix_playerid = string.format("_%d", playerid)

    if fix_playerids[fix_playerid] ~= nil then
        do_log(string.format(
            'Fixed playerid %d -> %d', playerid, fix_playerids[fix_playerid]
        ))
        playerid = fix_playerids[fix_playerid]
    end

    local fut_players_file_path = "other/fut/base_fut_players.csv"

    for line in io.lines(fut_players_file_path) do
        local values = split(line, ',')
        local f_playerid = tonumber(values[columns['playerid']])
        if not f_playerid then goto continue end

        if f_playerid == playerid then
            if PlayersEditorForm.FUTCopyAttribsCB.State == 0 then
                local trait1_comps = {
                    "LongThrowInCB",
                    "PowerFreeKickCB",
                    "InjuryProneCB",
                    "SolidPlayerCB",
                    "DivesIntoTacklesCB",
                    "",
                    "LeadershipCB",
                    "EarlyCrosserCB",
                    "FinesseShotCB",
                    "FlairCB",
                    "LongPasserCB",
                    "LongShotTakerCB",
                    "SpeedDribblerCB",
                    "PlaymakerCB",
                    "GKLongthrowCB",
                    "PowerheaderCB",
                    "GiantthrowinCB",
                    "OutsitefootshotCB",
                    "SwervePassCB",
                    "SecondWindCB",
                    "FlairPassesCB",
                    "BicycleKicksCB",
                    "GKFlatKickCB",
                    "OneClubPlayerCB",
                    "TeamPlayerCB",
                    "ChipShotCB",
                    "TechnicalDribblerCB",
                    "RushesOutOfGoalCB",
                    "CautiousWithCrossesCB",
                    "ComesForCrossessCB"
                }
                local trait1 = toBits(tonumber(values[columns['trait1']]))
                local index = 1
                for ch in string.gmatch(trait1, '.') do
                    local comp = PlayersEditorForm[trait1_comps[index]]
                    if comp then
                        comp.State = tonumber(ch)
                    end
                    index = index + 1
                end

                local trait2_comps = {
                    "",
                    "SaveswithFeetCB",
                    "SetPlaySpecialistCB"
                }
                local trait2 = toBits(tonumber(values[columns['trait2']]))
                local index = 1
                for ch in string.gmatch(trait2, '.') do
                    local comp = PlayersEditorForm[trait2_comps[index]]
                    if comp then
                        comp.State = tonumber(ch)
                    end
                    index = index + 1
                end
            end
            
            local dont_copy_headmodel = (
                PlayersEditorForm.FUTCopyHeadModelCB.State == 1 or
                PlayersEditorForm.FutFIFACB.ItemIndex > 0
            )
            for key, value in pairs(comp_to_column) do
                local component = PlayersEditorForm[key]
                local component_name = component.Name
                local comp_desc = COMPONENTS_DESCRIPTION_PLAYER_EDIT[component_name]
                local component_class = component.ClassName

                if dont_copy_headmodel and (
                    component_name == 'HeadClassCodeEdit' or 
                    component_name == 'HeadAssetIDEdit' or 
                    component_name == 'HeadVariationEdit' or 
                    component_name == 'HairTypeEdit' or 
                    component_name == 'HairStyleEdit' or 
                    component_name == 'FacialHairTypeEdit' or 
                    component_name == 'FacialHairColorEdit' or 
                    component_name == 'SideburnsEdit' or 
                    component_name == 'EyebrowEdit' or 
                    component_name == 'EyeColorEdit' or 
                    component_name == 'SkinTypeEdit' or
                    component_name == 'HasHighQualityHeadCB' or 
                    component_name == 'HairColorCB' or 
                    component_name == 'HeadTypeCodeCB' or 
                    component_name == 'SkinColorCB' or
                    component_name == 'HeadTypeGroupCB'
                ) then
                    -- Don't change headmodel
                elseif component_name == 'AgeEdit' then
                    if PlayersEditorForm.FUTCopyAgeCB.State == 0 then 
                        -- clear
                        component.OnChange = nil

                        -- Update AgeEdit
                        if comp_desc['valFromFunc'] then
                            component.Text = comp_desc['valFromFunc']({
                                comp_desc = comp_desc,
                                birthdate = values[columns['birthdate']]
                            })
                        end

                        if comp_desc['events'] then
                            for key, value in pairs(comp_desc['events']) do
                                component[key] = value
                            end
                        else
                            component.OnChange = CommonEditOnChange
                        end
                    end
                elseif component_name == 'HeadTypeCodeCB' then
                    FillHeadTypeCB({
                        headtypecode = tonumber(values[columns[value]])
                    })
                elseif component_class == 'TCEEdit' then
                    if PlayersEditorForm.FUTCopyAttribsCB.State == 1 and (
                        component.Parent.Parent.Name == 'AttributesPanel' or 
                        component.Name == 'OverallEdit' or
                        component.Name == 'PotentialEdit'
                    ) then
                        -- Don't copy attributes
                    else
                        -- clear
                        component.OnChange = nil

                        local new_comp_text = (
                            player['details']['stat_json'][value] or 
                            player['details'][comp_to_fut[key]] or 
                            player['details']['stat_json'][comp_to_fut[key]] or 
                            values[columns[value]]
                        )
                        -- if not tonumber(new_comp_text) then
                        --     print(component_name)
                        --     print(new_comp_text)
                        --     print(value)
                        -- end
                        
                        -- Composure has been added in FIFA 18
                        if (
                            component.Name == 'ComposureEdit' and
                            tonumber(new_comp_text) == 0
                        ) then
                            new_comp_text = tonumber(player['details']['ovr']) - 6
                        end

                        component.Text = tonumber(new_comp_text)
            
                        if comp_desc['events'] then
                            for key, value in pairs(comp_desc['events']) do
                                component[key] = value
                            end
                        else
                            component.OnChange = CommonEditOnChange
                        end
                    end
                elseif component_class == 'TCEComboBox' then
                    if PlayersEditorForm.FUTCopyAttribsCB.State == 1 and (
                        component.Parent.Parent.Name == 'AttributesPanel'
                    ) then
                        -- Don't copy attributes
                    else
                        -- clear
                        component.OnChange = nil

                        local new_comp_val = nil
                        if value == 'preferredposition1' then
                            local pos_name_to_id = {
                                GK = 0,
                                SW = 1,
                                RWB = 2,
                                RB = 3,
                                RCB = 4,
                                CB = 5,
                                LCB = 6,
                                LB = 7,
                                LWB = 8,
                                RDM = 9,
                                CDM = 10,
                                LDM = 11,
                                RM = 12,
                                RCM = 13,
                                CM = 14,
                                LCM = 15,
                                LM = 16,
                                RAM = 17,
                                CAM = 18,
                                LAM = 19,
                                RF = 20,
                                CF = 21,
                                LF = 22,
                                RW = 23,
                                RS = 24,
                                ST = 25,
                                LS = 26,
                                LW = 27,
                            }
                            new_comp_val = pos_name_to_id[player['position']]
                        else
                            new_comp_val = (
                                player['details']['stat_json'][value] or
                                player['details'][comp_to_fut[key]] or
                                player['details']['stat_json'][comp_to_fut[key]] or
                                values[columns[value]]
                            )
                        end

                        local dropdown = ADDR_LIST.getMemoryRecordByID(comp_desc['id'])
                        local dropdown_items = dropdown.DropDownList

                        for j = 0, dropdown_items.Count-1 do
                            local val, desc = string.match(dropdown_items[j], "(%d+): '(.+)'")

                            if tonumber(val) + comp_desc['modifier'] == tonumber(new_comp_val) then
                                component.ItemIndex = j
                                component.Hint = desc
                            end
                        end

                        -- Add events
                        if comp_desc['events'] then
                            for key, value in pairs(comp_desc['events']) do
                                component[key] = value
                            end
                        else
                            component.OnChange = CommonCBOnChange
                            component.OnDropDown = CommonCBOnDropDown
                            component.OnMouseEnter = CommonCBOnMouseEnter
                            component.OnMouseLeave = CommonCBOnMouseLeave
                        end
                    end
                end
            end

            if PlayersEditorForm.FUTCopyAttribsCB.State == 0 then
                -- Apply chem style:
                local chem_style_itm_index = PlayersEditorForm.FUTChemStyleCB.ItemIndex
                local chem_styles = {
                    -- Basic
                    {
                        SprintSpeedEdit = 5,
                        AttackPositioningEdit = 5,
                        ShotPowerEdit = 5,
                        VolleysEdit = 5,
                        PenaltiesEdit = 5,
                        VisionEdit = 5,
                        ShortPassingEdit = 5,
                        LongPassingEdit = 5,
                        CurveEdit = 5,
                        AgilityEdit = 5,
                        BallControlEdit = 5,
                        DribblingEdit = 5,
                        MarkingEdit = 5,
                        StandingTackleEdit = 5,
                        SlidingTackleEdit = 5,
                        JumpingEdit = 5,
                        StrengthEdit = 5
                    },
                    -- GK Basic
                    {
                        GKDivingEdit = 10,
                        GKHandlingEdit = 10,
                        GKKickingEdit = 10,
                        GKReflexEdit = 10,
                        AccelerationEdit = 5,
                        GKPositioningEdit = 10
                    },
                    -- Sniper
                    {
                        AttackPositioningEdit = 10,
                        FinishingEdit = 15,
                        VolleysEdit = 10,
                        PenaltiesEdit = 15,
                        AgilityEdit = 5,
                        BalanceEdit = 10,
                        ReactionsEdit = 5,
                        BallControlEdit = 5,
                        DribblingEdit = 15
                    },
                    -- Finisher
                    {
                        FinishingEdit = 5,
                        ShotPowerEdit = 15,
                        LongShotsEdit = 15,
                        VolleysEdit = 10,
                        PenaltiesEdit = 10,
                        JumpingEdit = 15,
                        StrengthEdit = 10,
                        AggressionEdit = 10
                    },
                    -- Deadeye
                    {
                        AttackPositioningEdit = 10,
                        FinishingEdit = 15,
                        ShotPowerEdit = 10,
                        LongShotsEdit = 5,
                        PenaltiesEdit = 5,
                        VisionEdit = 5,
                        FreeKickAccuracyEdit = 10,
                        LongPassingEdit = 5,
                        ShortPassingEdit = 15,
                        CurveEdit = 10
                    },
                    -- Marksman
                    {
                        AttackPositioningEdit = 10,
                        FinishingEdit = 5,
                        ShotPowerEdit = 10,
                        LongShotsEdit = 10,
                        VolleysEdit = 10,
                        PenaltiesEdit = 5,
                        AgilityEdit = 5,
                        ReactionsEdit = 5,
                        BallControlEdit = 5,
                        DribblingEdit = 5,
                        JumpingEdit = 10,
                        StrengthEdit = 5,
                        AggressionEdit = 5
                    },
                    -- Hawk
                    {
                        AccelerationEdit = 10,
                        SprintSpeedEdit = 5,
                        AttackPositioningEdit = 10,
                        FinishingEdit = 5,
                        ShotPowerEdit = 10,
                        LongShotsEdit = 10,
                        VolleysEdit = 10,
                        PenaltiesEdit = 5,
                        JumpingEdit = 10,
                        StrengthEdit = 5,
                        AggressionEdit = 10
                    },
                    -- Artist
                    {
                        VisionEdit = 15,
                        CrossingEdit = 5,
                        LongPassingEdit = 15,
                        ShortPassingEdit = 10,
                        CurveEdit = 5,
                        AgilityEdit = 5,
                        BalanceEdit = 5,
                        ReactionsEdit = 10,
                        BallControlEdit = 5,
                        DribblingEdit = 15
                    },
                    -- Architect
                    {
                        VisionEdit = 10,
                        CrossingEdit = 15,
                        FreeKickAccuracyEdit = 5,
                        LongPassingEdit = 15,
                        ShortPassingEdit = 10,
                        CurveEdit = 5,
                        JumpingEdit = 5,
                        StrengthEdit = 15,
                        AggressionEdit = 10
                    },
                    -- Powerhouse
                    {
                        VisionEdit = 10,
                        CrossingEdit = 5,
                        LongPassingEdit = 10,
                        ShortPassingEdit = 15,
                        CurveEdit = 10,
                        InterceptionsEdit = 5,
                        MarkingEdit = 10,
                        StandingTackleEdit = 15,
                        SlidingTackleEdit = 10
                    },
                    -- Maestro
                    {
                        AttackPositioningEdit = 5,
                        FinishingEdit = 5,
                        ShotPowerEdit = 10,
                        LongShotsEdit = 10,
                        VolleysEdit = 10,
                        VisionEdit = 5,
                        FreeKickAccuracyEdit = 10,
                        LongPassingEdit = 5,
                        ShortPassingEdit = 10,
                        ReactionsEdit = 5,
                        BallControlEdit = 5,
                        DribblingEdit = 10
                    },
                    -- Engine
                    {
                        AccelerationEdit = 10,
                        SprintSpeedEdit = 5,
                        VisionEdit = 5,
                        CrossingEdit = 5,
                        FreeKickAccuracyEdit = 10,
                        LongPassingEdit = 5,
                        ShortPassingEdit = 10,
                        CurveEdit = 5,
                        AgilityEdit = 5,
                        BalanceEdit = 10,
                        ReactionsEdit = 5,
                        BallControlEdit = 5,
                        DribblingEdit = 10
                    },
                    -- Sentinel
                    {
                        InterceptionsEdit = 5,
                        HeadingAccuracyEdit = 10,
                        MarkingEdit = 15,
                        StandingTackleEdit = 15,
                        SlidingTackleEdit = 10,
                        JumpingEdit = 5,
                        StrengthEdit = 15,
                        AggressionEdit = 10
                    },
                    -- Guardian
                    {
                        AgilityEdit = 5,
                        BalanceEdit = 10,
                        ReactionsEdit = 5,
                        BallControlEdit = 5,
                        DribblingEdit = 15,
                        InterceptionsEdit = 10,
                        HeadingAccuracyEdit = 5,
                        MarkingEdit = 15,
                        StandingTackleEdit = 10,
                        SlidingTackleEdit = 10
                    },
                    -- Gladiator
                    {
                        AttackPositioningEdit = 15,
                        FinishingEdit = 5,
                        ShotPowerEdit = 10,
                        LongShotsEdit = 5,
                        InterceptionsEdit = 10,
                        HeadingAccuracyEdit = 15,
                        MarkingEdit = 5,
                        StandingTackleEdit = 10,
                        SlidingTackleEdit = 15
                    },
                    -- Backbone
                    {
                        VisionEdit = 5,
                        CrossingEdit = 5,
                        LongPassingEdit = 5,
                        ShortPassingEdit = 10,
                        CurveEdit = 5,
                        InterceptionsEdit = 5,
                        HeadingAccuracyEdit = 5,
                        MarkingEdit = 10,
                        StandingTackleEdit = 10,
                        SlidingTackleEdit = 10,
                        JumpingEdit = 5,
                        StrengthEdit = 10,
                        AggressionEdit = 5
                    },
                    -- Anchor
                    {
                        AccelerationEdit = 10,
                        SprintSpeedEdit = 5,
                        InterceptionsEdit = 5,
                        HeadingAccuracyEdit = 10,
                        MarkingEdit = 10,
                        StandingTackleEdit = 10,
                        SlidingTackleEdit = 10,
                        JumpingEdit = 10,
                        StrengthEdit = 10,
                        AggressionEdit = 10
                    },
                    -- Hunter
                    {
                        AccelerationEdit = 15,
                        SprintSpeedEdit = 10,
                        AttackPositioningEdit = 15,
                        FinishingEdit = 10,
                        ShotPowerEdit = 10,
                        LongShotsEdit = 5,
                        VolleysEdit = 10,
                        PenaltiesEdit = 15
                    },
                    -- Catalyst
                    {
                        AccelerationEdit = 15,
                        SprintSpeedEdit = 10,
                        VisionEdit = 15,
                        CrossingEdit = 10,
                        FreeKickAccuracyEdit = 10,
                        LongPassingEdit = 5,
                        ShortPassingEdit = 10,
                        CurveEdit = 15
                    },
                    -- Shadow
                    {
                        AccelerationEdit = 15,
                        SprintSpeedEdit = 10,
                        InterceptionsEdit = 10,
                        HeadingAccuracyEdit = 10,
                        MarkingEdit = 15,
                        StandingTackleEdit = 15,
                        SlidingTackleEdit = 15
                    },
                    -- Wall
                    {
                        GKDivingEdit = 15,
                        GKHandlingEdit = 15,
                        GKKickingEdit = 15
                    },
                    -- Shield
                    {
                        GKKickingEdit = 15,
                        GKReflexEdit = 15,
                        AccelerationEdit = 10,
                        SprintSpeedEdit = 5
                    },
                    -- Cat
                    {
                        GKReflexEdit = 15,
                        AccelerationEdit = 10,
                        SprintSpeedEdit = 5,
                        GKPositioningEdit = 15
                    },
                    -- Glove
                    {
                        GKDivingEdit = 15,
                        GKHandlingEdit = 15,
                        GKPositioningEdit = 15
                    },
                }

                if chem_styles[chem_style_itm_index] then
                    for component_name, modif in pairs(chem_styles[chem_style_itm_index]) do
                        local component = PlayersEditorForm[component_name]
                        -- tmp disable onchange event
                        local onchange_event = component.OnChange
                        component.OnChange = nil

                        local new_attr_val = tonumber(component.Text) + modif
                        if new_attr_val > 99 then new_attr_val = 99 end

                        component.Text = new_attr_val
                        
                        component.OnChange = onchange_event
                    end
                end

                local trackbars = {
                    'AttackTrackBar',
                    'DefendingTrackBar',
                    'SkillTrackBar',
                    'GoalkeeperTrackBar',
                    'PowerTrackBar',
                    'MovementTrackBar',
                    'MentalityTrackBar',
                }
                for i=1, #trackbars do
                    update_trackbar(PlayersEditorForm[trackbars[i]])
                end
                
                -- Adjust Potential
                if PlayersEditorForm.FUTAdjustPotCB.State == 1 then
                    if tonumber(PlayersEditorForm.OverallEdit.Text) > tonumber(PlayersEditorForm.PotentialEdit.Text) then
                        PlayersEditorForm.PotentialEdit.Text = PlayersEditorForm.OverallEdit.Text
                    end
                end

                -- Fix preferred positions
                local pos_arr = {PlayersEditorForm.PreferredPosition1CB.ItemIndex+1}
                for i=2, 4 do
                    if pos_arr[1] ~= PlayersEditorForm[string.format('PreferredPosition%dCB', i)].ItemIndex then
                        table.insert(pos_arr, PlayersEditorForm[string.format('PreferredPosition%dCB', i)].ItemIndex)
                    end
                end
                for i=2, 4 do
                    PlayersEditorForm[string.format('PreferredPosition%dCB', i)].ItemIndex = pos_arr[i] or 0
                end

                -- Recalc OVR for best at
                recalculate_ovr(false)
            end
            -- DONE
            HAS_UNAPPLIED_PLAYER_CHANGES = true
            ShowMessage('Data from FUT has been copied to GUI.\nTo see the changes in game you need to "Apply Changes"')
            return true
        elseif f_playerid > playerid then
            -- Not found
            do_log('COPY ERROR\n Player not Found: ' .. playerid, 'ERROR')
            ShowMessage('COPY ERROR\n Player not Found: ' .. playerid)
            return false
        end
        ::continue::
    end
end

function fut_create_card(player, idx)
    if not player then return end

    local fut_fifa = FIFA - PlayersEditorForm.FutFIFACB.ItemIndex
    local player_details = fut_get_player_details(player['id'], fut_fifa)

    FOUND_FUT_PLAYERS[idx]['details'] = player_details

    -- Cards img
    local card = player_details['card']
    if card ~= nil then
        local url = FUT_URLS['card_bg'] .. card .. '?v=119'
        local stream = load_img('ut/cards_bg/' .. card, url)

        if stream ~= nil then
            PlayersEditorForm.CardBGImage.Picture.LoadFromStream(stream)
            stream.destroy()
        end
    end
    -- Headshot
    if player_details['miniface_img'] ~= nil then
        local img_comp = nil
        if player_details['special_img'] == 1 then
            img_comp = PlayersEditorForm.CardSpecialHeadshotImage
            PlayersEditorForm.CardHeadshotImage.Visible = false
            PlayersEditorForm.CardSpecialHeadshotImage.Visible = true
        else
            img_comp = PlayersEditorForm.CardHeadshotImage
            PlayersEditorForm.CardHeadshotImage.Visible = true
            PlayersEditorForm.CardSpecialHeadshotImage.Visible = false
        end
        -- print(player['headshot']['imgUrl'])

        stream = load_img(
            string.format('heads/p%d.png', player['id']),
            player_details['miniface_img']
        )
        if stream then
            img_comp.Picture.LoadFromStream(stream)
            stream.destroy()
        end
    end

    -- Nationality Img
    stream = load_img(
        string.format('flags/f%d.png', player_details['nation_id']),
        player_details['nation_img']
    )
    if stream then
        PlayersEditorForm.CardNatImage.Picture.LoadFromStream(stream)
        stream.destroy()
    end

    -- Club crest Img
    stream = load_img(
        string.format('crest/l%d.png', player_details['club_id']),
        player_details['club_img']
    )
    if stream then
        PlayersEditorForm.CardClubImage.Picture.LoadFromStream(stream)
        stream.destroy()
    end

    -- Font colors for labels on card
    local type_color_map = {
        -- Non Rare
        ['0-bronze'] = '0x2B2217',
        ['0-silver'] = '0x26292A',
        ['0-gold'] = '0x443A22',

        -- Rare
        ['1-bronze'] = '0x3A2717',
        ['1-silver'] = '0x303536',
        ['1-gold'] = '0x46390C',

        -- TOTW
        ['3-bronze'] = '0xBB9266',
        ['3-silver'] = '0xB0BCC8',
        ['3-gold'] = '0xE9CC74',

        -- HERO
        ['4-gold'] = '0xFBFBFB',

        -- TOTY
        ['5-gold'] = '0xEBCD5B',

        -- Record breaker
        ['6-gold'] = '0xFBFBFB',

        -- St. Patrick's Day
        ['7-gold'] = '0xFBFBFB',

        -- Domestic MOTM
        ['8-gold'] = '0xFBFBFB',

        -- FUT Champions
        ['18-bronze'] = '0xBB9266',
        ['18-silver'] = '0xB0BCC8',
        ['18-gold'] = '0xE3CF83',

        -- Pro player
        ['10-gold'] = '0x625217',

        -- Special item
        ['9-gold'] = '0x12FCC6',
        ['11-gold'] = '0x12FCC6',
        ['16-gold'] = '0x12FCC6',
        ['23-gold'] = '0x12FCC6',
        ['26-gold'] = '0x12FCC6',
        ['30-gold'] = '0x12FCC6',
        ['37-gold'] = '0x12FCC6',
        ['44-gold'] = '0x12FCC6',
        ['50-gold'] = '0x12FCC6',
        ['80-gold'] = '0x12FCC6',

        -- Icons
        ['12-icon'] = '0x625217',

        -- The journey
        ['17-gold'] = '0xE9CC74',

        -- OTW
        ['21-gold'] = '0xFF4782',

        -- Ultimate SCREAM
        ['21-otw'] = '0xFF690D',

        -- SBC
        ['24-gold'] = '0x72C0FF',

        -- Premium SBC
        ['25-gold'] = '0xFD95F6',

        -- Award winner
        ['28-gold'] = '0xFBFBFB',

        -- FUTMAS
        ['32-gold'] = '0xFBFBFB',

        -- POTM Bundesliga
        ['42-gold'] = '0xFBFBFB',

        -- POTM PL
        ['43-gold'] = '0x05f1ff',

        -- UEFA Euro League MOTM
        ['45-gold'] = '0xF39200',

        -- UCL Common
        ['47-gold'] = '0xFBFBFB',

        -- UCL Rare
        ['48-gold'] = '0xFBFBFB',

        -- UCL MOTM
        ['49-gold'] = '0xFBFBFB',

        -- Flashback sbc
        ['51-sbc_flashback'] = '0xB0FFEB',
        
        -- Swap Deals I
        ['52-bronze'] = '0x05b3c3',
        ['52-silver'] = '0x05b3c3',
        ['52-gold'] = '0x05b3c3',

        -- Swap Deals II
        ['53-gold'] = '0x05b3c3',

        -- Swap Deals III
        ['54-gold'] = '0x05b3c3',

        -- Swap Deals IV
        ['55-gold'] = '0x05b3c3',

        -- Swap Deals V
        ['56-gold'] = '0x05b3c3',

        -- Swap Deals VI
        ['57-gold'] = '0x05b3c3',

        -- Swap Deals VII
        ['58-gold'] = '0x05b3c3',

        -- Swap Deals VII
        ['59-gold'] = '0x05b3c3',

        -- Swap Deals IX
        ['60-gold'] = '0x05b3c3',

        -- Swap Deals X
        ['61-gold'] = '0x05b3c3',

        -- Swap Deals XI
        ['62-gold'] = '0x05b3c3',

        -- Swap Deals Rewards
        ['63-gold'] = '0x05b3c3',

        -- TOTY Nominee
        ['64-gold'] = '0xEFD668',

        -- TOTS Nominee
        ['65-gold'] = '0xEFD668',

        -- TOTS 85+
        ['66-gold'] = '0xEFD668',

        -- POTM MLS
        ['67-gold'] = '0xFBFBFB',

        -- UEFA Euro League TOTT
        ['68-gold'] = '0xFBFBFB',

        -- UCL Premium SBC
        ['69-gold'] = '0xFBFBFB',

        -- UCL Euro League TOTT
        ['70-gold'] = '0xFBFBFB',

        -- FUTURE Stars
        ['71-gold'] = '0xC0FF36',

        -- Carniball
        ['72-gold'] = '0xC0FF36',

        -- Lunar NEW YEAR
        ['73-gold'] = '0xFBFBFB',

        -- Holi
        ['74-gold'] = '0xFBFBFB',

        -- Easter
        ['75-gold'] = '0xFBFBFB',

        -- National Day I
        ['76-gold'] = '0xFBFBFB',

        -- UEFA EUROPA LEAGUE
        ['78-gold'] = '0xFBFBFB',

        -- POTM LaLiga
        ['79-gold'] = '0xFBFBFB',

        -- FUTURE Stars Nom
        ['83-gold'] = '0xC0FF36',

        -- Priem icon Moments
        ['84-gold'] = '0x625217',

        -- Headliners
        ['85-gold'] = '0xFBFBFB',
    }

    -- print(string.format('%d-%s', player['rarityId'], player['quality']))
    local f_color = type_color_map[player_details['card_type']]

    if f_color == nil then
        f_color = '0xFBFBFB'
    end

    -- OVR LABEL
    PlayersEditorForm.CardNameLabel.Caption = player_details['ovr']
    PlayersEditorForm.CardNameLabel.Font.Color = f_color

    -- Position LABEL
    PlayersEditorForm.CardPosLabel.Caption = player_details['pos']
    PlayersEditorForm.CardPosLabel.Font.Color = f_color

    -- Player Name Label
    PlayersEditorForm.CardPlayerNameLabel.Caption = player_details['name']
    PlayersEditorForm.CardPlayerNameLabel.Font.Color = f_color

    -- Attributes
    fut_fill_attributes(player_details, f_color)
end

function fut_fill_attributes(player, f_color)
    -- Attr chem styles

    local chanded_attr_arr = {}

    local picked_chem_style = PlayersEditorForm.FUTChemStyleCB.Items[PlayersEditorForm.FUTChemStyleCB.ItemIndex]

    -- If picked chem style other than None/Basic
    if string.match(picked_chem_style, ',') then
        local changed_attr = split(string.match(picked_chem_style, "%((.+)%)"), ',')
        for i=1, #changed_attr do
            local attr = changed_attr[i]
            attr = string.gsub(attr, '+', '')
            chanded_attr_arr[string.match(attr, "([A-Z]+)")] = tonumber(string.match(attr, "([0-9]+)"))
        end
    end

    -- Attributes
    local attr_abbr = {
        pace = "PAC",
        shooting = "SHO",
        passing = "PAS",
        dribblingp = "DRI",
        defending = "DEF",
        heading = "PHY",
        gkdiving = "DIV",
        gkhandling = "HAN",
        gkkicking = "KIC",
        gkreflexes = "REF",
        speed = "SPE",
        gkpositioning = "POS"
    }
    TEST = player
    for i=1, 6 do
        local component = PlayersEditorForm[string.format('CardPlayerAttrLabel%d', i)]
        local attr_name = attr_abbr[player[string.format('stat%d_name', i)]]
        local attr_val = player[string.format('stat%d_val', i)]
        if chanded_attr_arr[attr_name] then
            attr_val = string.format("%d +%d", attr_val, chanded_attr_arr[attr_name])
        end

        local caption = string.format(
            '%s %s',
            attr_val,
            attr_name
        )
        component.Caption = caption
        if f_color then component.Font.Color = f_color end
    end
end

FUT_API_PAGE = 1
function fut_search_player(player_data, page)
    if string.len(player_data) < 3 then
        showMessage("Input at least 3 characters.")
        return
    end

    local fut_fifa = FIFA - PlayersEditorForm.FutFIFACB.ItemIndex
    FOUND_FUT_PLAYERS = fut_find_player(player_data, page, fut_fifa)
    if FOUND_FUT_PLAYERS == nil then return end

    local players = FOUND_FUT_PLAYERS
    local players_count = #players
    local scrollbox_width = 310

    -- if players_count >= 24 then
    --     can_continue = true
    -- else
    --     can_continue = false
    -- end

    can_continue = false
    PlayersEditorForm.NextPage.Enabled = can_continue

    if page == 1 then
        PlayersEditorForm.PrevPage.Enabled = false
    else
        PlayersEditorForm.PrevPage.Enabled = true
    end

    for i=1, players_count do
        local player = players[i]
        local card_type = player['version'] or 'Normal'
        local formated_string = string.format(
            '%s - %s - %d ovr - %s',
            player['full_name'], card_type, player['rating'], player['position']
        )

        -- Dynamic width
        local str_len = string.len(formated_string)
        if str_len >= 35 then
            local new_width = 310 + ((str_len - 35) * 8)
            if new_width > scrollbox_width then
                scrollbox_width = new_width
            end
        end
        PlayersEditorForm.FUTPickPlayerListBox.Items.Add(formated_string)
    end

    -- Change width (add scroll)
    if scrollbox_width ~= PlayersEditorForm.FUTPickPlayerListBox.Width then
        PlayersEditorForm.FUTPickPlayerListBox.Width = scrollbox_width
    end

    if scrollbox_width > 310 then
        PlayersEditorForm.FUTPickPlayerScrollBox.HorzScrollBar.Visible = true
    else
        PlayersEditorForm.FUTPickPlayerScrollBox.HorzScrollBar.Visible = false
    end

    if players_count >= 27 then
        PlayersEditorForm.FUTPickPlayerScrollBox.VertScrollBar.Visible = true
    else
        PlayersEditorForm.FUTPickPlayerScrollBox.VertScrollBar.Visible = false
    end
end
