require 'lua/GUI/consts';
require 'lua/GUI/forms/newmatchfixform/consts';
require 'lua/GUI/forms/newmatchfixform/helpers';
-- NewMatchFixForm Events

function NewMatchFixFormShow(sender)
    INCIDENTS = {
        SCORE = {
            TOTAL = 0,
            UNIQUE_SCORERS = 0,
            SCORERS = {},
            ASSISTS = {}
        },
    }
    NewMatchFixForm.NewIncidentContainer.Visible = false
    NewMatchFixForm.HomeTeamIDEdit.Text = "Home Team ID"
    NewMatchFixForm.HomeScoreEdit.Text = "0"
    NewMatchFixForm.AwayTeamIDEdit.Text = "Away Team ID"
    NewMatchFixForm.AwayScoreEdit.Text = "0"
    NewMatchFixForm.GoalScorerEdit.Text = "PlayerID..."
    NewMatchFixForm.GoalAssistEdit.Text = "PlayerID..."
    NewMatchFixForm.IncidentTypeCB.ItemIndex = 0

    -- TODO Assists
    NewMatchFixForm.GoalAssistEdit.Visible = false
    NewMatchFixForm.GoalAssistLabel.Visible = false

    local ss_c = load_crest(-1)
    NewMatchFixForm.HomeTeamCrest.Picture.LoadFromStream(ss_c)
    ss_c.destroy()
    ss_c = load_crest(-1)
    NewMatchFixForm.AwayTeamCrest.Picture.LoadFromStream(ss_c)
    ss_c.destroy()

    clear_custom_incident_containers()
end

function HomeTeamIDEditClick(sender)
    sender.Text = ""
end
function AwayTeamIDEditClick(sender)
    sender.Text = ""
end
function GoalScorerEditClick(sender)
    sender.Text = ""
end
function GoalAssistEditClick(sender)
    sender.Text = ""
end

function NewMatchFixFormExitClick(sender)
    NewMatchFixForm.close()
    MatchFixingForm.show()
end
function NewMatchFixFormMinimizeClick(sender)
    NewMatchFixForm.WindowState = "wsMinimized" 
end
function NewMatchFixFormTopPanelMouseDown(sender, button, x, y)
    NewMatchFixForm.dragNow()
end

function NewIncidentButtonClick()
    table.insert(INCIDENTS['SCORE']['SCORERS'], tonumber(NewMatchFixForm.GoalScorerEdit.Text))
    new_incident(INCIDENTS['SCORE']['UNIQUE_SCORERS'])
    INCIDENTS['SCORE']['TOTAL'] = INCIDENTS['SCORE']['TOTAL'] + 1
    onScoreSchange()
end

function ConfirmBtnClick()
    local gameid = readInteger("arr_fixedGamesData")
    local home_teamid = tonumber(NewMatchFixForm.HomeTeamIDEdit.Text)
    if home_teamid == nil or home_teamid == 0 then
        home_teamid = 4294967295
    end

    local away_teamid = tonumber(NewMatchFixForm.AwayTeamIDEdit.Text)
    if away_teamid == nil or away_teamid == 0 then
        away_teamid = 4294967295
    end

    local home_score = tonumber(NewMatchFixForm.HomeScoreEdit.Text)
    local away_score = tonumber(NewMatchFixForm.AwayScoreEdit.Text)

    writeInteger("arr_fixedGamesData", gameid + 1)

    writeInteger(
        string.format('arr_fixedGamesData+%s', string.format('%X', (gameid) * 16 + 4)),
        home_teamid
    )
    writeInteger(
        string.format('arr_fixedGamesData+%s', string.format('%X', (gameid) * 16 + 8)),
        away_teamid
    )
    writeInteger(
        string.format('arr_fixedGamesData+%s', string.format('%X', (gameid) * 16 + 12)),
        home_score
    )
    writeInteger(
        string.format('arr_fixedGamesData+%s', string.format('%X', (gameid) * 16 + 16)),
        away_score
    )

    writeInteger(
        string.format('arr_fixedGoals+%s', string.format('%X', (gameid) * 172)),
        home_teamid
    )

    writeInteger(
        string.format('arr_fixedGoals+%s', string.format('%X', (gameid) * 172 + 4)),
        away_teamid
    )

    writeInteger(
        string.format('arr_fixedGoals+%s', string.format('%X', (gameid) * 172 + 8)),
        INCIDENTS['SCORE']['TOTAL']
    )
    
    local scorer_off = 12
    for i=1, 20 do
        writeInteger(
            string.format('arr_fixedGoals+%s', string.format('%X', (gameid) * 172 + scorer_off)),
            INCIDENTS['SCORE']['SCORERS'][i] or 0
        )
        scorer_off = scorer_off + 8
    end

    NewMatchFixForm.close()
    MatchFixingForm.show()
end

function HomeTeamIDEditChange(sender)
    local teamid = tonumber(sender.Text)
    if teamid == nil or teamid == 0 then
        teamid = 4294967295
    end

    onTeamIDChange(NewMatchFixForm.HomeTeamCrest, teamid)
end

function AwayTeamIDEditChange(sender)
    local teamid = tonumber(sender.Text)
    if teamid == nil then 
        teamid = 4294967295
    end

    onTeamIDChange(NewMatchFixForm.AwayTeamCrest, teamid)
end

function onTeamIDChange(imgcomponent, teamid)
    local ss_c = load_crest(teamid)
    imgcomponent.Picture.LoadFromStream(ss_c)
    ss_c.destroy()
end

function HomeScoreEditChange()
    onScoreSchange()
end

function AwayScoreEditChange()
    onScoreSchange()
end

function onScoreSchange()
    local htscore = tonumber(NewMatchFixForm.HomeScoreEdit.Text)
    if htscore == nil then return false end

    local atscore = tonumber(NewMatchFixForm.AwayScoreEdit.Text)
    if atscore == nil then return false end

    local sum = htscore + atscore
    if INCIDENTS['SCORE']['TOTAL'] >= 20 then
        NewMatchFixForm.NewIncidentContainer.Visible = false
    elseif sum > 0 and INCIDENTS['SCORE']['TOTAL'] < sum then
        NewMatchFixForm.NewIncidentContainer.Visible = true
    else
        NewMatchFixForm.NewIncidentContainer.Visible = false
    end
end
