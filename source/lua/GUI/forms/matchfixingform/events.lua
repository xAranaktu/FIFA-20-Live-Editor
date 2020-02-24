require 'lua/helpers';
require 'lua/GUI/consts';
require 'lua/GUI/helpers';
require 'lua/GUI/forms/matchfixingform/helpers';
require 'lua/GUI/forms/matchfixingform/consts';

-- Make window dragable
function MatchFixingTopPanelMouseDown(sender, button, x, y)
    MatchFixingForm.dragNow()
end

-- EVENTS
function MatchFixingMinimizeClick(sender)
    MatchFixingForm.WindowState = "wsMinimized" 
end
function MatchFixingExitClick(sender)
    MatchFixingForm.close()
    MainWindowForm.show()
end
function MatchFixingSettingsClick(sender)
    SettingsForm.show()
end

function MatchFixingFormClose(sender)
    return caHide
end

function MatchFixingSyncImageClick(sender)
    clear_fav_teams_containers()
    clear_match_fixing_containers()
    create_fav_teams_containers()
    create_match_fixing_containers()
    clear_fav_scorers_containers()
    create_fav_scorers_containers()
end

function MatchFixingFormShow(sender)
    if not is_cm_loaded() then
        do_log(
            'Match Fixing works only in career mode. Load your career save first.',
            'ERROR'
        )
        MatchFixingForm.close()
        MainWindowForm.show()
        return
    end

    if not ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['MATCHFIXING_SCRIPT']).Active then
        ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['MATCHFIXING_SCRIPT']).Active = true
    end

    if readInteger("arr_fixedGamesAlwaysWin") == nil then
        MatchFixingForm.close()
        MainWindowForm.show()
        return
    end
    clear_fav_teams_containers()
    clear_match_fixing_containers()
    clear_fav_scorers_containers()
    create_fav_teams_containers()
    create_match_fixing_containers()
    create_fav_scorers_containers()

    MatchFixingForm.FixingTypeListBox.setItemIndex(0)
    FixingTypeListBoxSelectionChange(MatchFixingForm.FixingTypeListBox)
end

function MatchFixingAddFavTeamBtnClick(sender)
    local fav_teams = readInteger("arr_fixedGamesAlwaysWin")
    if fav_teams >= FAV_TEAMS_LIMIT then
        do_log(
            string.format("Add Fav team\nReached maximum number of favourite teams. %d is the limit.", FAV_TEAMS_LIMIT),
            'ERROR'
        )
        return false
    end

    local teamid = inputQuery("Add Fav team", "Enter teamid:", "0")
    if not teamid or tonumber(teamid) <= 0 then
        do_log(string.format("Add Fav team\nEnter Valid TeamID\n %s is invalid.", teamid), 'ERROR')
        return false
    end
    do_log(string.format("New fav team: %s", teamid), 'INFO')

    writeInteger("arr_fixedGamesAlwaysWin", fav_teams + 1)

    writeInteger(
        string.format('arr_fixedGamesAlwaysWin+%s', string.format('%X', (fav_teams) * 4 + 4)),
        teamid
    )

    create_fav_teams_container(fav_teams, teamid)

    if type(CFG_DATA.fav_teams) == 'table' then
        table.insert(CFG_DATA.fav_teams, tonumber(teamid))
    else
        CFG_DATA.fav_teams = { tonumber(teamid) }
    end
    save_cfg()

    do_log(string.format("Success ID: %d", fav_teams + 1), 'INFO')
end

function MatchFixingAddFavScorerBtnClick(sender)
    local fav_scorers = readInteger("arr_favGoalScorers")
    if fav_scorers >= FAV_SCORERS_LIMIT then
        do_log(
            string.format("Add Fav scorer\nReached maximum number of favourite scorers. %d is the limit.", FAV_SCORERS_LIMIT),
            'ERROR'
        )
        return false
    end

    local playerid = inputQuery("Add Fav scorer", "Enter playerid:", "0")
    if not playerid or tonumber(playerid) <= 0 then
        do_log(string.format("Add Fav scorer\nEnter Valid PlayerID\n %s is invalid.", playerid), 'ERROR')
        return false
    end
    do_log(string.format("New fav scorer: %s", playerid), 'INFO')

    writeInteger("arr_favGoalScorers", fav_scorers + 1)

    writeInteger(
        string.format('arr_favGoalScorers+%s', string.format('%X', (fav_scorers) * 4 + 4)),
        playerid
    )

    create_fav_scorer_container(fav_scorers, playerid)

    if type(CFG_DATA.fav_scorers) == 'table' then
        table.insert(CFG_DATA.fav_scorers, tonumber(playerid))
    else
        CFG_DATA.fav_scorers = { tonumber(playerid) }
    end
    save_cfg()

    do_log(string.format("Success ID: %d", fav_scorers + 1), 'INFO')
end

function MatchFixingNewMatchFixBtnClick(sender)
    if need_match_fixing_sync() then
        ShowMessage("Close this and try again after 2s.")
        clear_match_fixing_containers()
        create_match_fixing_containers()
        return false
    end

    MatchFixingForm.close()
    NewMatchFixForm.show()

    -- local fixed_games = readInteger("arr_fixedGamesData")
    -- if fixed_games >= 60 then
    --     do_log("Add Fixed Match\nReach maximum number of fixed games. 60 is the limit.", 'ERROR')
    --     return
    -- end

    -- local home_teamid = inputQuery("Match Fixing", "Enter home teamid:\nLeave 0 for any team.", "0")
    -- if (home_teamid == "0" or home_teamid == '') then
    --     home_teamid = 4294967295
    -- elseif tonumber(home_teamid) == nil then
    --     do_log(string.format("Value must be a number, %s is invalid", home_teamid), 'ERROR')
    --     return
    -- end

    -- local away_teamid = inputQuery("Match Fixing", "Enter away teamid:\nLeave 0 for any team.", "0")
    -- if (away_teamid == "0" or away_teamid == '') then
    --     away_teamid = 4294967295
    -- elseif tonumber(away_teamid) == nil then
    --     do_log(string.format("Value must be a number, %s is invalid", away_teamid), 'ERROR')
    --     return
    -- end

    -- local home_score = inputQuery("Match Fixing", "Enter num of goals scored by home team", "0")
    -- if tonumber(home_score) == nil then
    --     do_log(string.format("Value must be a number, %s is invalid", home_score), 'ERROR')
    --     return
    -- end

    -- local away_score = inputQuery("Match Fixing", "Enter num of goals scored by away team", "0")
    -- if tonumber(away_score) == nil then
    --     do_log(string.format("Value must be a number, %s is invalid", away_score), 'ERROR')
    --     return
    -- end

    -- do_log(string.format("New match fixing: %s %s:%s %s", home_teamid, home_score, away_score, away_teamid), 'INFO')

    -- writeInteger("arr_fixedGamesData", fixed_games + 1)

    -- writeInteger(
    --     string.format('arr_fixedGamesData+%s', string.format('%X', (fixed_games) * 16 + 4)),
    --     home_teamid
    -- )
    -- writeInteger(
    --     string.format('arr_fixedGamesData+%s', string.format('%X', (fixed_games) * 16 + 8)),
    --     away_teamid
    -- )
    -- writeInteger(
    --     string.format('arr_fixedGamesData+%s', string.format('%X', (fixed_games) * 16 + 12)),
    --     home_score
    -- )
    -- writeInteger(
    --     string.format('arr_fixedGamesData+%s', string.format('%X', (fixed_games) * 16 + 16)),
    --     away_score
    -- )
    -- create_match_fixing_container(fixed_games)
    -- do_log(string.format("Success ID: %d", fixed_games + 1), 'INFO')
end

function FixingTypeListBoxSelectionChange(sender, user)
    local Panels = {
        'MatchFixingContainer',
        'MatchFixingFavContainer',
        'MatchFixingFavScorersContainer',
    }
    for i=1, #Panels do
        if sender.ItemIndex == i-1 then
            MatchFixingForm[Panels[i]].Visible = true
        else
            MatchFixingForm[Panels[i]].Visible = false
        end
    end
end

function MatchFixingFavTeamHelpClick(sender)
ShowMessage([[
Favourite teams

Teams defined as a favourite will always win their games by 3:0.

If you got more than one favourite team and these teams will meet each other then the home team will always win.

You can only define 60 favourite teams at this moment.
]])
end

function MatchFixingFavScorerHelpClick(sender)
ShowMessage([[
Favourite Scorers

Players defined as favourite scorers will always all goals for their teams. (Except penalties)

You can only define 100 favourite scorers at this moment.
]])
end
