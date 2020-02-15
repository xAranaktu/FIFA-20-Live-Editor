require 'lua/GUI/consts';
require 'lua/GUI/forms/findteamform/consts';
require 'lua/GUI/forms/findteamform/helpers';

-- Make window dragable
function FindTeamTopPanelMouseDown(sender, button, x, y)
    FindTeamForm.dragNow()
end

function FindTeamExitClick(sender)
    FindTeamForm.close()
end

function FindTeamMinimizeClick(sender)
    FindTeamForm.WindowState = "wsMinimized" 
end

function FindTeamListBoxSelectionChange(sender)
    return 0
end

function FindTeamSearchBtnClick(sender)
    clear_search_for_team()
    local txt = FindTeamForm.FindTeamEdit.Text
    if tonumber(txt) == nil then
        -- search for team name
        if string.len(txt) < 3 then
            do_log(string.format("Input at least 3 characters", txt), "ERROR")
            return 1
        end
        TEAMS_SEARCH_TEAMS_FOUND = find_teams_by_name(string.lower(txt))
        if #TEAMS_SEARCH_TEAMS_FOUND <= 0 then
            do_log(string.format("Team %s not found", txt), "ERROR")
            return 1
        end

        local team_addr = nil
        local team_string = ''
        for i=1, #TEAMS_SEARCH_TEAMS_FOUND do
            team_addr = TEAMS_SEARCH_TEAMS_FOUND[i]['addr']
            writeQword('teamsDataPtr', team_addr)
            team_string = string.format(
                '%s (ID: %d)',
                ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['TEAMNAME']).Value,
                tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['TEAMID']).Value) + 1
            )
            FindTeamForm.FindTeamListBox.Items.Add(team_string)
        end
    else
        -- search for team id
        find_team_by_id(tonumber(txt) - 1)
        FillTeamEditorForm(tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['TEAMID']).Value))
        clear_search_for_team()
        FindTeamForm.close()
    end
end

function FindTeamOkBtnClick(sender)
    local team_addr = nil
    if #TEAMS_SEARCH_TEAMS_FOUND <= 0 then
        do_log('Search for team first...', "ERROR")
        return 1
    elseif #TEAMS_SEARCH_TEAMS_FOUND == 1 then
        team_addr = TEAMS_SEARCH_TEAMS_FOUND[1]['addr']
    else
        local idx = FindTeamForm.FindTeamListBox.ItemIndex or 0
        team_addr = TEAMS_SEARCH_TEAMS_FOUND[idx+1]['addr']
    end
    writeQword('teamsDataPtr', team_addr)
    FillTeamEditorForm(tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['TEAMID']).Value))
    clear_search_for_team()
    FindTeamForm.close()
end
