-- FIND TEAM FORM HELPERS

function find_teams_by_name(teamname)
    local result = {}
    if type(teamname) ~= 'string' then
        teamname = tostring(teamname)
    end

    if string.len(teamname) < 3 then
        return result
    end

    return find_records_in_game_db(
        CT_MEMORY_RECORDS['TEAMNAME'],
        teamname,
        DB_TABLE_SIZEOF['TEAMS'],
        'firstteamsDataPtr',
        nil,
        DB_TABLE_RECORDS_LIMIT['TEAMS'],
        DB_TABLE_RECORDS_LIMIT['TEAMS'],
        true
    )
end

function find_team_by_id(teamid)
    if type(teamid) == 'string' then
        teamid = tonumber(teamid)
    end

    if readPointer('firstteamsDataPtr') == nil then
        do_log("firstteamsDataPtr not initialized", 'ERROR')
        return false
    end

    -- teams table
    local sizeOf = DB_TABLE_SIZEOF['TEAMS']
    local team_addr = find_record_in_game_db(
        0, CT_MEMORY_RECORDS['TEAMID'], teamid, sizeOf, 'firstteamsDataPtr', 
        nil, DB_TABLE_RECORDS_LIMIT['TEAMS']
    )['addr']

    if team_addr then
        -- Update in Cheat Table
        writeQword('teamsDataPtr', team_addr)
        -- find_team_formation(teamid)
        find_team_teamsheet(teamid)
        find_team_default_mentalities(teamid)
        return true
    else
        do_log(string.format("Unable to find team with ID: %d.", teamid + 1), 'ERROR')
        return false
    end
end

function clear_search_for_team()
    FindTeamForm.FindTeamListBox.clear()
    TEAMS_SEARCH_TEAMS_FOUND = {}
end
