require 'lua/GUI/consts';
require 'lua/GUI/forms/findplayerform/consts';
require 'lua/GUI/forms/findplayerform/helpers';

-- Make window dragable
function FindPlayerTopPanelMouseDown(sender, button, x, y)
    FindPlayerForm.dragNow()
end

function FindPlayerExitClick(sender)
    FindPlayerForm.close()
end

function FindPlayerMinimizeClick(sender)
    FindPlayerForm.WindowState = "wsMinimized" 
end

function FindPlayerListBoxSelectionChange(sender)
    return 0
end

function FindPlayerSearchBtnClick(sender)
    clear_search_for_player()
    local txt = FindPlayerForm.FindPlayerEdit.Text
    if tonumber(txt) == nil then
        -- search for team name
        if string.len(txt) < 3 then
            do_log(string.format("Input at least 3 characters", txt), "ERROR")
            return 1
        end
        PLAYERS_SEARCH_PLAYERS_FOUND = find_players_by_name(txt)
        if #PLAYERS_SEARCH_PLAYERS_FOUND <= 0 then
            do_log(string.format("Player %s not found", txt), "ERROR")
            return 1
        end

        local player_addr = nil
        local player_string = ''
        for i=1, #PLAYERS_SEARCH_PLAYERS_FOUND do
            player_addr = PLAYERS_SEARCH_PLAYERS_FOUND[i]['addr']
            player_string = string.format(
                '%s %s (ID: %d)',
                PLAYERS_SEARCH_PLAYERS_FOUND[i]['firstname'],
                PLAYERS_SEARCH_PLAYERS_FOUND[i]['surname'],
                PLAYERS_SEARCH_PLAYERS_FOUND[i]['playerid']
            )
            FindPlayerForm.FindPlayerListBox.Items.Add(player_string)
        end
    else
        -- search for team id
        find_player_by_id(tonumber(txt))
        FillPlayerEditForm(tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['PLAYERID']).Value))
        clear_search_for_player()
        FindPlayerForm.close()
    end
end

function FindPlayerOkBtnClick(sender)
    local player_addr = nil
    if #PLAYERS_SEARCH_PLAYERS_FOUND <= 0 then
        do_log('Search for player first...', "ERROR")
        return 1
    elseif #PLAYERS_SEARCH_PLAYERS_FOUND == 1 then
        player_addr = PLAYERS_SEARCH_PLAYERS_FOUND[1]['addr']
    else
        local idx = FindPlayerForm.FindPlayerListBox.ItemIndex or 0
        player_addr = PLAYERS_SEARCH_PLAYERS_FOUND[idx+1]['addr']
    end
    writeQword('playerDataPtr', player_addr)
    FillPlayerEditForm(tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['PLAYERID']).Value))
    clear_search_for_player()
    FindPlayerForm.close()
end
