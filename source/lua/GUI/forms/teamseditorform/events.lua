require 'lua/GUI/consts';
require 'lua/GUI/helpers';
require 'lua/GUI/forms/teamseditorform/consts';
require 'lua/GUI/forms/teamseditorform/helpers';

-- Make window dragable
function TeamsEditorTopPanelMouseDown(sender, button, x, y)
    TeamsEditorForm.dragNow()
end

-- EVENTS

local FillTeamEditTimer = createTimer(nil)

-- OnShow - TEAM Edit Form
function TeamsEditorFormShow(sender)
    COMPONENTS_DESCRIPTION_TEAM_EDIT = get_components_description_team_edit()
    HAS_UNAPPLIED_TEAM_CHANGES = false

    TeamsEditorForm.WhileLoadingPanel.Visible = true
    TeamsEditorForm.FindTeamBtn.Visible = false
    -- Load Data
    timer_onTimer(FillTeamEditTimer, TrueTeamsEditorFormShow)
    timer_setInterval(FillTeamEditTimer, 100)
    timer_setEnabled(FillTeamEditTimer, true)
end

function TrueTeamsEditorFormShow()
    -- Disable Timer
    timer_setEnabled(FillTeamEditTimer, false)

    -- Fill TeamEdit Form
    FillTeamEditorForm(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['TEAMID']).Value)
    TeamsEditorForm.WhileLoadingPanel.Visible = false
    TeamsEditorForm.FindTeamBtn.Visible = true
end

function FindTeamBtnClick()
    FindTeamForm.show()
end

-- OnClose Teams Editor Form
function TeamsEditorFormClose(sender)
    return caHide
end


-- TOP BAR
function TeamsEditorMinimizeClick(sender)
    TeamsEditorForm.WindowState = "wsMinimized" 
end
function TeamsEditorExitClick(sender)
    TeamsEditorForm.close()
    MainWindowForm.show()
end

-- Common events
function TeamsCommonEditOnChange(sender)
    HAS_UNAPPLIED_TEAM_CHANGES = true
end


function TeamsTabClick(sender)
    -- No action when tab is visible
    if TeamsEditorForm[TEAMS_TAB_PANEL_MAP[sender.Name]].Visible then return end

    for key,value in pairs(TEAMS_TAB_PANEL_MAP) do
        if key == sender.Name then
            sender.Color = '0x001D1618'
            TeamsEditorForm[value].Visible = true
        else
            TeamsEditorForm[key].Color = '0x003F2F34'
            TeamsEditorForm[value].Visible = false
        end
    end
end
function TeamsTabMouseEnter(sender)
    if TeamsEditorForm[TEAMS_TAB_PANEL_MAP[sender.Name]].Visible then return end

    sender.Color = '0x00271D20'
end
function TeamsTabMouseLeave(sender)
    if TeamsEditorForm[TEAMS_TAB_PANEL_MAP[sender.Name]].Visible then return end
    
    sender.Color = '0x003F2F34'
end

function SyncTeamImageClick(sender)
    local IsCMCached = readInteger("IsCMCached") or 0
    if IsCMCached == 0 then
        -- Show Loading panel
        PlayersEditorForm.WhileLoadingPanel.Visible = true

        -- Load Data
        timer_onTimer(FillTeamEditTimer, TrueTeamsEditorFormShow)
        timer_setInterval(FillTeamEditTimer, 100)
        timer_setEnabled(FillTeamEditTimer, true)
    else
        FillTeamEditorForm(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['TEAMID']).Value)
    end
    
end

function TeamApplyChangesBtnClick(sender)
    TeamApplyChanges()
end

function TeamFormationCBOnChange(sender)
    update_formation_pitch(
        FORMATIONS_DATA[sender.ItemIndex - 1],
        DEFAULT_TSHEET_ADDR
    )
end

function TeamFormationPlanCBChange(sender)
    do_log("TeamFormationPlanCBChange")
    local idx = sender.ItemIndex + 1

    if idx >= sender.Items.Count then
        writeQword("ptrDefaultmentalities", TEAM_MENTALITIES[1]['addr'])
    else
        writeQword("ptrDefaultmentalities", TEAM_MENTALITIES[idx]['addr'])
    end

    local formationid = tonumber(ADDR_LIST.getMemoryRecordByID(MENTALITIES_DESC['sourceformationid']['id']).Value - 1)
    local tmp = TeamsEditorForm.TeamFormationCB.OnChange
    TeamsEditorForm.TeamFormationCB.OnChange = nil
    TeamsEditorForm.TeamFormationCB.ItemIndex = formationid + 1
    update_formation_pitch(
        FORMATIONS_DATA[formationid],
        DEFAULT_TSHEET_ADDR
    )
    TeamsEditorForm.TeamFormationCB.OnChange = tmp
end
