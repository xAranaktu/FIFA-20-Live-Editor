
function FillTeamEditorForm(teamid)
    do_log("FillTeamEditorForm")
    cache_players()
    if teamid ~= nil or type(teamid) ~= "number" then
        teamid = tonumber(teamid)
    end

    if teamid ~= nil then
        find_team_by_id(teamid)
    end

    for i=0, TeamsEditorForm.ComponentCount-1 do
        local component = TeamsEditorForm.Component[i]
        local component_name = component.Name
        local comp_desc = COMPONENTS_DESCRIPTION_TEAM_EDIT[component_name]
        if comp_desc == nil then goto continue end

        local component_class = component.ClassName

        component.OnChange = nil
        if component_class == 'TCEEdit' then
            component.Text = tonumber(ADDR_LIST.getMemoryRecordByID(comp_desc['id']).Value) + comp_desc['modifier']
            component.OnChange = TeamCommonEditOnChange
        elseif component_class == 'TCELabel' then
            component.Caption = ADDR_LIST.getMemoryRecordByID(comp_desc['id']).Value
        elseif component_class == 'TCEComboBox' then
            if not comp_desc['already_filled'] then
                component.clear()
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
            else
                component.ItemIndex = tonumber(ADDR_LIST.getMemoryRecordByID(comp_desc['id']).Value)
            end
        end
        if comp_desc['events'] then
            for key, value in pairs(comp_desc['events']) do
                component[key] = value
            end
        end

        ::continue::
    end
    local ss_c = load_crest(teamid + 1)
    TeamsEditorForm.ClubCrest.Picture.LoadFromStream(ss_c)
    ss_c.destroy()
    -- TEAM_PLAYERS = find_players_for_team(teamid)
    DEFAULT_TSHEET_ADDR = find_default_teamsheet(teamid)

    update_formation_pitch(
        FORMATIONS_DATA[TeamsEditorForm.TeamFormationCB.ItemIndex - 1], 
        DEFAULT_TSHEET_ADDR
    )

    -- local players = find_players_for_team(teamid)
    -- if #players > 0 then
    --     for i=1, #players do
    --         local addr = players[i]
    --         print(
    --             string.format("%d: %X", addr['index'], addr['addr'])
    --         )
    --         writeQword('ptrTeamplayerlinks', addr['addr'])
    --     end
    -- end

end

function TeamApplyChanges()
    for i=0, TeamsEditorForm.ComponentCount-1 do
        local component = TeamsEditorForm.Component[i]
        local component_name = component.Name
        local comp_desc = COMPONENTS_DESCRIPTION_TEAM_EDIT[component_name]
        if comp_desc == nil then goto continue end

        local component_class = component.ClassName
        if component_class == 'TCEEdit' then
            if string.len(component.Text) <= 0 then
                do_log(
                    string.format("%s component is empty. Please, fill it and try again", component_name),
                    'ERROR'
                )
            end
            ADDR_LIST.getMemoryRecordByID(comp_desc['id']).Value = tonumber(component.Text) - comp_desc['modifier']
        elseif component_class == 'TCEComboBox' then
            if comp_desc['onApplyChanges'] then
                comp_desc['onApplyChanges']({
                    component = component,
                    comp_desc = comp_desc,
                })
            else
                ADDR_LIST.getMemoryRecordByID(comp_desc['id']).Value = component.ItemIndex
            end
        end
        ::continue::
    end
    HAS_UNAPPLIED_TEAM_CHANGES = false
    showMessage("Team edited.")
    do_log("Team edited.")
end

function find_default_teamsheet(teamid)
    -- default_teamsheets table
    local sizeOf = DB_TABLE_SIZEOF['DEFAULT_TEAMSHEETS']
    local addr = find_record_in_game_db(
        0, CT_MEMORY_RECORDS['DEFAULT_TEAMSHEETS_TEAMID'], teamid, sizeOf, 'firstptrDefaultteamsheets', 
        nil, DB_TABLE_RECORDS_LIMIT['DEFAULT_TEAMSHEETS']
    )

    if addr then
        return addr['addr']
    end

    return nil
end

function find_players_for_team(teamid)
    if teamid == nil then
        do_log("find_players_for_team, no teamid", 'ERROR')
        return
    end

    if type(teamid) == 'string' then
        teamid = tonumber(teamid)
    end
    local addrs = find_records_in_game_db(
        CT_MEMORY_RECORDS['TPLINKS_TEAMID'],        -- memrec_id
        teamid,                                     -- value_to_find
        DB_TABLE_SIZEOF['TEAMPLAYERLINKS'],         -- size of
        'ptrFirstTeamplayerlinks',                  -- first_ptrname
        nil,                                        -- to_exit
        DB_TABLE_RECORDS_LIMIT['TEAMPLAYERLINKS'],  -- limit
        52                                          -- max_records
    )

    -- if #addrs > 0 then
    --     for i=1, #addrs do
    --         local addr = addrs[i]
    --         writeQword('ptrTeamplayerlinks', addr['addr'])
    --         local playerid = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['TPLINKS_PLAYERID']).Value

    --         if TEAM_PLAYERS[tostring(playerid)] == nil then
    --             if find_player_by_id(playerid, true) then  -- short_info = true
    --                 TEAM_PLAYERS[tostring(playerid)] = readQword('playerDataPtr')
    --                 print(string.format("%X", TEAM_PLAYERS[tostring(playerid)]))
    --                 print(playerid)
    --             end
    --         end
    --     end
    -- end

    return addrs
end

function find_team_default_mentalities(teamid)
    if type(teamid) == 'string' then
        teamid = tonumber(teamid)
    end

    local firstptrname = "firstptrDefaultmentalities"
    if readPointer(firstptrname) == nil then
        do_log(firstptrname .. " not initialized", 'ERROR')
        return false
    end
    local addrs = find_records_in_game_db(
        CT_MEMORY_RECORDS['DEFAULT_MENTALITIES_TEAMID'],    -- memrec_id
        teamid + 2,                                         -- value_to_find
        DB_TABLE_SIZEOF['DEFAULT_MENTALITIES'],             -- size of
        firstptrname,                                       -- first_ptrname
        nil,                                                -- to_exit
        DB_TABLE_RECORDS_LIMIT['DEFAULT_MENTALITIES'],      -- limit
        6                                                   -- max_records
    )

    if #addrs > 0 then
        TEAM_MENTALITIES = addrs
        -- Update in Cheat Table
        writeQword('ptrDefaultmentalities', addrs[1]['addr'])  -- Ultra defensive?

        local plancb = TeamsEditorForm.TeamFormationPlanCB
        local tmp = plancb.OnChange
        plancb.OnChange = nil
        plancb.clear()

        for i=1, #TEAM_MENTALITIES do
            local gameplan = string.format("Gameplan - %d", i)
            plancb.items.add(gameplan)
        end
        plancb.items.add("Gameplan - All")
        plancb.ItemIndex = #TEAM_MENTALITIES
        plancb.OnChange = tmp
    else
        do_log(string.format("Unable to find mentality for team with ID: %d.", teamid + 1), 'ERROR')
    end
end

function ClickSwapPlayers(sender)
    if FORMATION_PLAYER_SWAP_0 == nil then
        SWAP_IMG = createImage(sender.Parent)
        SWAP_IMG.Name = string.format("SwapImg")
        SWAP_IMG.Left = sender.Left + 20
        SWAP_IMG.Top = sender.Top + 20
        SWAP_IMG.Height = 32
        SWAP_IMG.Width = 32
        SWAP_IMG.Stretch = true
        SWAP_IMG.Hint = playerid
        SWAP_IMG.ShowHint = true
        SWAP_IMG.Picture.LoadFromStream(findTableFile('refresh.png').Stream)
        SWAP_IMG.Visible = true
        SWAP_IMG.bringToFront()
        FORMATION_PLAYER_SWAP_0 = sender
    else
        if FORMATION_PLAYER_SWAP_0 == sender then
            FORMATION_PLAYER_SWAP_0 = nil
            SWAP_IMG.destroy()
            SWAP_IMG = nil
            return 
        end
        
        local playerid0 = string.gsub(FORMATION_PLAYER_SWAP_0.Hint, "%D", '')
        local playerid1 = string.gsub(sender.Hint, "%D", '')

        local playername0 = nil
        local _iplayerid0 = tonumber(playerid0)
        local skintonecode0 = nil
        local headtypecode0 = nil
        local haircolorcode0 = nil
        if CACHED_PLAYERS[_iplayerid0] then
            playername0 = CACHED_PLAYERS[_iplayerid0]['knownas']
            skintonecode0 = CACHED_PLAYERS[_iplayerid0]['skintonecode']
            headtypecode0 = CACHED_PLAYERS[_iplayerid0]['headtypecode']
            haircolorcode0 = CACHED_PLAYERS[_iplayerid0]['haircolorcode']
        end

        local playername1 = nil
        local _iplayerid1 = tonumber(playerid1)
        local skintonecode1 = nil
        local headtypecode1 = nil
        local haircolorcode1 = nil
        if CACHED_PLAYERS[_iplayerid1] then
            playername1 = CACHED_PLAYERS[_iplayerid1]['knownas']
            skintonecode1 = CACHED_PLAYERS[_iplayerid1]['skintonecode']
            headtypecode1 = CACHED_PLAYERS[_iplayerid1]['headtypecode']
            haircolorcode1 = CACHED_PLAYERS[_iplayerid1]['haircolorcode']
        end

        local stream = load_headshot(
            playerid0,
            skintonecode0,
            headtypecode0,
            haircolorcode0
        )
        sender.Picture.LoadFromStream(stream)
        stream.destroy()

        stream = load_headshot(
            playerid1,
            skintonecode1,
            headtypecode1,
            haircolorcode1
        )
        FORMATION_PLAYER_SWAP_0.Picture.LoadFromStream(stream)
        stream.destroy()

        sender.Hint = string.format("%s (ID: %s)", playername0 or '', playerid0)
        FORMATION_PLAYER_SWAP_0.Hint = string.format("%s (ID: %s)", playername1 or '', playerid1)

        local id0, _ = string.gsub(FORMATION_PLAYER_SWAP_0.Name, "%D", '')
        local id1, _ = string.gsub(sender.Name, "%D", '')

        local lbl_name = string.format("TeamPlayerIDLabel%d", id0)
        local lbl_comp = TeamsEditorForm[lbl_name]
        if lbl_comp == nil then
            lbl_comp = TeamsEditorForm.FormationReservesScroll[lbl_name]
        end
        if lbl_comp then
            lbl_comp.Caption = playername1 or playerid1
            lbl_comp.Hint = string.format("%s (ID: %s)", playername1 or '', playerid1)
            lbl_comp.ShowHint = true
        end

        lbl_name = string.format("TeamPlayerIDLabel%d", id1)
        local lbl_comp = TeamsEditorForm[lbl_name]
        if lbl_comp == nil then
            lbl_comp = TeamsEditorForm.FormationReservesScroll[lbl_name]
        end
        if lbl_comp then
            lbl_comp.Caption = playername0 or playerid0
            lbl_comp.Hint = string.format("%s (ID: %s)", playername0 or '', playerid0)
            lbl_comp.ShowHint = true
        end

        FORMATION_PLAYER_SWAP_0 = nil
        SWAP_IMG.destroy()
        SWAP_IMG = nil
    end
end

function update_formation_pitch(formation_data, teamsheet_addr)
    do_log("update_formation_pitch")
    do_log("Formation id: " .. formation_data['sourceformationid'])
    local pimgcomp = nil
    local plblcomp = nil
    local offsetx = nil
    local offsety = nil
    local w = TeamsEditorForm.FormationPitchImg.Width - 20
    local h = TeamsEditorForm.FormationPitchImg.Height - 20
    local pw = TeamsEditorForm.TeamPlayerImg1.Width
    local ph = TeamsEditorForm.TeamPlayerImg1.Height
    local playerid = -1
    local players_on_pitch = {}

    for i=0, TeamsEditorForm.FormationReservesScroll.ComponentCount-1 do
        TeamsEditorForm.FormationReservesScroll.Component[0].destroy()
    end
    local available_players_count = 0

    local owner = TeamsEditorForm.FormationReservesScroll

    local pid_mod = TEAMSHEETS_DESC["playerid0"]['modifier']
    writeQword("ptrDefaultteamsheets", teamsheet_addr)
    for i=0, 51 do
        playerid = math.floor(
            ADDR_LIST.getMemoryRecordByID(TEAMSHEETS_DESC[string.format("playerid%d", i)]['id']).Value + pid_mod
        )
        if playerid == nil or playerid == -1 then break end

        local playername = nil
        local skintonecode = nil
        local headtypecode = nil
        local haircolorcode = nil
        if CACHED_PLAYERS[playerid] then
            playername = CACHED_PLAYERS[playerid]['knownas']
            skintonecode = CACHED_PLAYERS[playerid]['skintonecode']
            headtypecode = CACHED_PLAYERS[playerid]['headtypecode']
            haircolorcode = CACHED_PLAYERS[playerid]['haircolorcode']
        end

        if i <= 10 then
            offsetx = formation_data[string.format("offset%dx", i)]
            offsety = formation_data[string.format("offset%dy", i)]
            pimgcomp = TeamsEditorForm[string.format("TeamPlayerImg%d", i+1)]
            plblcomp = TeamsEditorForm[string.format("TeamPlayerIDLabel%d", i+1)]

            pimgcomp.onClick = ClickSwapPlayers
            pimgcomp.Cursor = "crHandPoint"
            pimgcomp.Left = math.floor((offsetx * w) - pw/2 + 10)
            pimgcomp.Top = math.floor(h - ((offsety * h) + ( ph + 15)) + 10)

            plblcomp.AutoSize = false
            plblcomp.Width = pw
            plblcomp.BorderSpacing.Top = 3
            plblcomp.Alignment = "taCenter"
            plblcomp.Caption = playername or playerid
            plblcomp.Hint = string.format("%s (ID: %d)", playername or '', playerid)
            plblcomp.ShowHint = true

            pimgcomp.Hint = string.format("%s (ID: %s)", playername or '', playerid)
            pimgcomp.ShowHint = true
            local stream = load_headshot(
                playerid,
                skintonecode,
                headtypecode,
                haircolorcode
            )
            pimgcomp.Picture.LoadFromStream(stream)
            stream.destroy()
        else
            available_players_count = available_players_count + 1
            local left = 10
            if (i % 2 == 0) then
                left = left + 80
            end
            local top = 10 + (105 * math.floor(math.floor(i-11)/2))
            local headshot_img = createImage(owner)
            headshot_img.Name = string.format("TeamPlayerImg%d", i+1)
            headshot_img.Left = left
            headshot_img.Top = top
            headshot_img.Height = 75
            headshot_img.Width = 75
            headshot_img.Stretch = true
            headshot_img.Hint = string.format("%s (ID: %s)", playername, playerid)
            headshot_img.ShowHint = true
            headshot_img.onClick = ClickSwapPlayers
            headshot_img.Cursor = "crHandPoint"
            
            local stream = load_headshot(
                playerid,
                skintonecode,
                headtypecode,
                haircolorcode
            )
            headshot_img.Picture.LoadFromStream(stream)
            stream.destroy()

            local lbl = createLabel(owner)
            lbl.AutoSize = false
            lbl.Name = string.format("TeamPlayerIDLabel%d", i+1)
            lbl.Caption = playername or playerid
            lbl.Hint = string.format("%s (ID: %d)", playername or '', playerid)
            lbl.ShowHint = true
            lbl.Width = 75
            lbl.Height = 15
            lbl.Left = left
            lbl.Top = top + 83
            lbl.Alignment = "taCenter"
            lbl.Transparent = false
            lbl.ParentColor = false
            lbl.ParentFont = false
            lbl.Color = 0x00000000
            lbl.Font.Color = 0x00FFFFFF
        end
    end

    TeamsEditorForm.TeamAvailablePlayersLabel.Caption = string.format("Available Players (%d)", available_players_count)
end

function find_team_teamsheet(teamid)
    if type(teamid) == 'string' then
        teamid = tonumber(teamid)
    end

    local firstptrname = "firstptrDefaultteamsheets"
    if readPointer(firstptrname) == nil then
        do_log(firstptrname .. " not initialized", 'ERROR')
        return false
    end

    -- DEFAULT_TEAMSHEETS table
    local sizeOf = DB_TABLE_SIZEOF['DEFAULT_TEAMSHEETS']
    local addr = find_record_in_game_db(
        0, CT_MEMORY_RECORDS['DEFAULT_TEAMSHEETS_TEAMID'], teamid, sizeOf, firstptrname,
        nil, DB_TABLE_RECORDS_LIMIT['DEFAULT_TEAMSHEETS']
    )['addr']

    if addr then
        -- Update in Cheat Table
        writeQword('ptrDefaultteamsheets', addr)
    else
        do_log(string.format("Unable to find mentality for team with ID: %d.", teamid + 1), 'ERROR')
        return false
    end
end

function find_team_formation(teamid)
    if type(teamid) == 'string' then
        teamid = tonumber(teamid)
    end

    if readPointer('firstptrFormations') == nil then
        do_log("firstptrFormations not initialized", 'ERROR')
        return false
    end

    -- formations table
    local sizeOf = DB_TABLE_SIZEOF['FORMATIONS']
    local formation_addr = find_record_in_game_db(
        0, CT_MEMORY_RECORDS['FORMATION_TEAMID'], teamid + 3, sizeOf, 'firstptrFormations', 
        nil, DB_TABLE_RECORDS_LIMIT['FORMATIONS']
    )['addr']

    if formation_addr then
        -- Update in Cheat Table
        writeQword('ptrFormations', formation_addr)
    else
        do_log(string.format("Unable to find formation for team with ID: %d.", teamid + 1), 'ERROR')
        return false
    end
end

function set_team_formation(args)
    do_log("set_team_formation")
    local component = args['component']

    local formation = component.ItemIndex
    -- Unknown formation
    if formation <= 1 then
        do_log("Unknown formation")
        return false
    end
    formation = formation - 1

    local comp_desc = args['comp_desc']

    if #TEAM_MENTALITIES > 0 then
        for i=0, 51 do
            local n = string.format("playerid%d", i)
            local f_id = TEAMSHEETS_DESC[n]['id']
            local modi = TEAMSHEETS_DESC[n]['modifier']
            if ADDR_LIST.getMemoryRecordByID(f_id).Value == 0 then break end
            local val = TeamsEditorForm[string.format("TeamPlayerImg%d", i+1)]
            if val == nil then
                val = TeamsEditorForm.FormationReservesScroll[string.format("TeamPlayerImg%d", i+1)]
                if val == nil then break end
            end
            local pid = string.gsub(val.Hint, "%D", '')
            ADDR_LIST.getMemoryRecordByID(f_id).Value = tonumber(pid) - modi
        end
        for i=1, #TEAM_MENTALITIES do
            local addr = TEAM_MENTALITIES[i]
            writeQword('ptrDefaultmentalities', addr['addr'])
            for k, v in pairs(FORMATIONS_DATA[formation]) do
                local f_id = MENTALITIES_DESC[k]['id']
                local modi = MENTALITIES_DESC[k]['modifier']
                ADDR_LIST.getMemoryRecordByID(f_id).Value = v - modi
            end
            for j=0, 10 do
                local n = string.format("playerid%d", j)
                local f_id = MENTALITIES_DESC[n]['id']
                local modi = MENTALITIES_DESC[n]['modifier']
                local pid = string.gsub(TeamsEditorForm[string.format("TeamPlayerImg%d", j+1)].Hint, "%D", '')
                ADDR_LIST.getMemoryRecordByID(f_id).Value = tonumber(pid) - modi
            end
        end
    end
end
