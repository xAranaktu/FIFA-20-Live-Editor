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
    COMPONENTS_DESCRIPTION_MANAGER_EDIT = get_components_description_manager_edit()
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

function CommonTeamCBOnChange(sender)
    HAS_UNAPPLIED_TEAM_CHANGES = true
    UpdateCBComponentHint(sender)
end

function CommonTeamCBOnDropDown(sender)
    MakeComponentWider(sender)
end

function CommonTeamCBOnMouseEnter(sender)
    SaveOriginalWidth(sender)
end

function CommonTeamCBOnMouseLeave(sender)
    MakeComponentShorter(sender)
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

function TeamColorFullOnChange(sender)
    local colorID, _ = string.gsub(sender.Name, '%D', '')
    local value = string.gsub(sender.Text, '#', '')
    value = string.gsub(value, '0x', '')
    if string.len(value) < 6 then
        return 0
    elseif string.len(value) > 6 then
        do_log(
            string.format('Invalid Color %d format - %s.', colorID, sender.Text)
            'ERROR'
        )
        sender.Text = "#FFFFFF"
        return 1
    end
    local red = tonumber(string.sub(value, 1, 2), 16)
    local green = tonumber(string.sub(value, 3, 4), 16)
    local blue = tonumber(string.sub(value, 5, 6), 16)

    TeamsEditorForm[string.format('TeamColor%dPreview', colorID)].Color = string.format(
        '0x%02X%02X%02X',
        blue,
        green,
        red
    )

    local red_comp = TeamsEditorForm[string.format('TeamColor%dRedEdit', colorID)]
    local saved_red_onchange = red_comp.OnChange
    red_comp.OnChange = nil
    red_comp.Text = red
    red_comp.OnChange = saved_red_onchange

    local green_comp = TeamsEditorForm[string.format('TeamColor%dGreenEdit', colorID)]
    local saved_green_onchange = green_comp.OnChange
    green_comp.OnChange = nil
    green_comp.Text = green
    green_comp.OnChange = saved_green_onchange

    local blue_comp = TeamsEditorForm[string.format('TeamColor%dBlueEdit', colorID)]
    local saved_blue_onchange = blue_comp.OnChange
    blue_comp.OnChange = nil
    blue_comp.Text = blue
    blue_comp.OnChange = saved_blue_onchange
end

function TeamColorOnChange(sender)
    local colorID, _ = string.gsub(sender.Name, '%D', '')
    
    local red = _validated_color(TeamsEditorForm[string.format('TeamColor%dRedEdit', colorID)])
    local green = _validated_color(TeamsEditorForm[string.format('TeamColor%dGreenEdit', colorID)])
    local blue = _validated_color(TeamsEditorForm[string.format('TeamColor%dBlueEdit', colorID)])

    TeamsEditorForm[string.format('TeamColor%dHex', colorID)].Text = string.format(
        '#%02X%02X%02X',
        red,
        green,
        blue
    )

    TeamsEditorForm[string.format('TeamColor%dPreview', colorID)].Color = string.format(
        '0x%02X%02X%02X',
        blue,
        green,
        red
    )
end