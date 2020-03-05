require 'lua/GUI/consts';
require 'lua/GUI/helpers';
require 'lua/GUI/forms/playerseditorform/consts';
require 'lua/GUI/forms/playerseditorform/helpers';
require 'lua/fut_requests'

-- Make window dragable
function PlayerEditTopPanelMouseDown(sender, button, x, y)
    PlayersEditorForm.dragNow()
end

-- EVENTS

local FillPlayerEditTimer = createTimer(nil)

-- OnShow - Player Edit Form
function PlayerEditFormShow(sender)
    -- Hook Load and exit cm
    if not ADDR_LIST.getMemoryRecordByID(4831).Active then
        ADDR_LIST.getMemoryRecordByID(4831).Active = true
    end

    COMPONENTS_DESCRIPTION_PLAYER_EDIT = get_components_description_player_edit()
    HAS_UNAPPLIED_PLAYER_CHANGES = false

    -- No current date
    -- if ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['CURRENT_DATE_DAY']).Value == '??' and is_cm_loaded() then
    --     do_log("No ptr for current date. Reload your CM save and try again", 'ERROR')
    --     PlayersEditorForm.hide()
    --     MainWindowForm.show()
    --     return
    -- end

    local playerid_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['PLAYERID'])
    
    -- Don't update anything if we don't have players table addr
    if playerid_record == nil then 
        do_log("playerid_record is nil. Activate 'Database Tables' script and reload your career save.", 'ERROR')
        PlayersEditorForm.hide()
        MainWindowForm.show()
        return
    elseif playerid_record.Value == '??' then
        do_log("playerid_record.Value is '??'. Activate 'Database Tables' script and reload your career save.", 'ERROR')
        PlayersEditorForm.hide()
        MainWindowForm.show()
        return
    end

    -- or teamplayerlinks table addr
    local teamid_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['TPLINKS_TEAMID'])
    if teamid_record == nil then 
        do_log("teamid_record is nil", 'ERROR')
        PlayersEditorForm.hide()
        MainWindowForm.show()
        return
    elseif teamid_record.Value == '??' then
        do_log("teamid_record.Value is '??'. Activate 'Database Tables' script and reload your career save.", 'ERROR')
        PlayersEditorForm.hide()
        MainWindowForm.show()
        return
    end

    -- Show Loading panel
    PlayersEditorForm.FindPlayerByID.Visible = false
    PlayersEditorForm.SearchPlayerByID.Visible = false
    PlayersEditorForm.WhileLoadingPanel.Visible = true

    -- Load Data
    timer_onTimer(FillPlayerEditTimer, TruePlayerEditFormShow)
    timer_setInterval(FillPlayerEditTimer, 100)
    timer_setEnabled(FillPlayerEditTimer, true)
end

function TruePlayerEditFormShow()
    -- Disable Timer
    timer_setEnabled(FillPlayerEditTimer, false)

    -- Fill Form
    FillPlayerEditForm(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['PLAYERID']).Value)

    -- Recalculate OVR (update "Best At")
    recalculate_ovr()

    -- Create Hotkeys
    create_hotkeys()

    -- Clone CM
    PlayersEditorForm.CopyCMFindPlayerByID.Text = 'Find player by ID...'

    -- FUT
    PlayersEditorForm.CloneFromListBox.setItemIndex(0)
    PlayersEditorForm.CardContainerPanel.Visible = false

    PlayersEditorForm.FutFIFACB.Hint = ''

    -- If cached we can search for player by name
    -- Use findplayers form
    if CFG_DATA.flags.cache_players_data then
        PlayersEditorForm.FindPlayerByID.Visible = false
        PlayersEditorForm.SearchPlayerByID.Visible = false
        PlayersEditorForm.FindPlayerBtn.Visible = true
    else
        PlayersEditorForm.FindPlayerByID.Text = 'Find player by ID...'
        PlayersEditorForm.FindPlayerByID.Visible = true
        PlayersEditorForm.SearchPlayerByID.Visible = true
        PlayersEditorForm.FindPlayerBtn.Visible = false
    end

    -- Hide Loading Panel and show components
    PlayersEditorForm.PlayerInfoTab.Color = "0x001D1618"
    PlayersEditorForm.PlayerInfoPanel.Visible = true
    PlayersEditorForm.WhileLoadingPanel.Visible = false
end

-- OnClose Players Editor Form
function PlayersEditorFormClose(sender)
    check_if_has_unapplied_player_changes()
    destroy_hotkeys()
    return caHide
end


-- TOP BAR
function PlayerEditMinimizeClick(sender)
    PlayersEditorForm.WindowState = "wsMinimized" 
end
function PlayerEditExitClick(sender)
    PlayersEditorForm.close()
    MainWindowForm.show()
end

function FindPlayerBtnClick(sender)
    FindPlayerForm.show()
end

-- Tab Clicks
function TabClick(sender)
    -- No action when tab is visible
    if PlayersEditorForm[PLAYERS_TAB_PANEL_MAP[sender.Name]].Visible then return end

    for key,value in pairs(PLAYERS_TAB_PANEL_MAP) do
        if key == sender.Name then
            sender.Color = '0x001D1618'
            PlayersEditorForm[value].Visible = true
        else
            PlayersEditorForm[key].Color = '0x003F2F34'
            PlayersEditorForm[value].Visible = false
        end
    end
end

-- Hover
function TabMouseEnter(sender)
    if PlayersEditorForm[PLAYERS_TAB_PANEL_MAP[sender.Name]].Visible then return end

    sender.Color = '0x00271D20'
end
function TabMouseLeave(sender)
    if PlayersEditorForm[PLAYERS_TAB_PANEL_MAP[sender.Name]].Visible then return end
    
    sender.Color = '0x003F2F34'
end

-- Apply Changes Click
function ApplyChangesBtnClick(sender)
    ApplyChanges()
end
function ApplyChangesLabelClick(sender)
    ApplyChanges()
end


-- Randomize Attributes
function RandomMentalityAttrClick(sender)
    roll_random_attributes({
        "AggressionEdit", "ComposureEdit", "InterceptionsEdit",
        "AttackPositioningEdit", "VisionEdit", "PenaltiesEdit",
    })
end
function RandomMovementAttrClick(sender)
    roll_random_attributes({
        "AccelerationEdit", "SprintSpeedEdit", "AgilityEdit",
        "ReactionsEdit", "BalanceEdit",
    })
end
function RandomPowerAttrClick(sender)
    roll_random_attributes({
        "ShotPowerEdit", "JumpingEdit", "StaminaEdit",
        "StrengthEdit", "LongShotsEdit",
    })
end
function RandomGKAttrClick(sender)
    roll_random_attributes({
        "GKDivingEdit", "GKHandlingEdit", "GKKickingEdit",
        "GKPositioningEdit", "GKReflexEdit",
    })
end
function RandomSkillAttrClick(sender)
    roll_random_attributes({
        "DribblingEdit", "CurveEdit", "FreeKickAccuracyEdit",
        "LongPassingEdit", "BallControlEdit",
    })
end
function RandomDefendingAttrClick(sender)
    roll_random_attributes({
        "MarkingEdit", "StandingTackleEdit", "SlidingTackleEdit",
    })
end
function RandomAttackAttrClick(sender)
    roll_random_attributes({
        "CrossingEdit", "FinishingEdit", "HeadingAccuracyEdit",
        "ShortPassingEdit", "VolleysEdit"
    })
end

function PlayerEditorSettingsClick(sender)
    SETTINGS_INDEX = 0
    SettingsForm.show()
end
function FindPlayerByIDClick(sender)
    create_hotkeys()
    sender.Text = ''
end

function SyncImageClick(sender)
    local playerid = tonumber(PlayersEditorForm.FindPlayerByID.Text)
    local playerid_ct = tonumber(ADDR_LIST.getMemoryRecordByID(93).Value)
    if playerid == playerid_ct then return end
    PlayerTeamContext = {}
    check_if_has_unapplied_player_changes()

    local IsCMCached = readInteger("IsCMCached") or 0
    if IsCMCached == 0 then
        -- Show Loading panel
        PlayersEditorForm.FindPlayerByID.Visible = false
        PlayersEditorForm.SearchPlayerByID.Visible = false
        PlayersEditorForm.WhileLoadingPanel.Visible = true

        -- Load Data
        timer_onTimer(FillPlayerEditTimer, TruePlayerEditFormShow)
        timer_setInterval(FillPlayerEditTimer, 100)
        timer_setEnabled(FillPlayerEditTimer, true)
    else
        PlayersEditorForm.FindPlayerByID.Text = 'Find player by ID...'
        FillPlayerEditForm()
        recalculate_ovr()
    end
end
function SearchPlayerByIDClick(sender)
    local playerid = tonumber(PlayersEditorForm.FindPlayerByID.Text)
    if playerid == nil then return end

    check_if_has_unapplied_player_changes()
    FillPlayerEditForm(playerid)
    PlayersEditorForm.FindPlayerByID.Text = playerid
    recalculate_ovr()
end

function HeadshotMouseMove(sender, x, y)
    if (
            (x >= sender.Width - PlayersEditorForm.Crest64x64.Width) and 
            (y <= PlayersEditorForm.Crest64x64.Height)
    ) then
        PlayersEditorForm.Crest64x64.bringToFront()
    else
        PlayersEditorForm.Crest64x64.sendToBack()
    end
end

function Crest64x64Click(sender)

    local team_ids = {}
    for key, value in pairs(PlayerTeamContext) do
        table.insert(team_ids, tonumber(key))
    end
    if #team_ids <= 1 then return end


    -- switch context
    local current_teamid = tonumber(PlayersEditorForm.TeamIDEdit.Text)
    table.sort(team_ids)
    local index = nil
    for i=1, #team_ids do
        if team_ids[i] == current_teamid then
            index = i
            break
        end
    end
    if index == nil then return end


    local next_team_index = index + 1
    if next_team_index > #team_ids then
        next_team_index = 1
    end

    writeQword('ptrTeamplayerlinks', PlayerTeamContext[team_ids[next_team_index]]['addr'])
    FillPlayerEditForm()
end

function Crest64x64MouseLeave(sender)
    sender.sendToBack()
end

function HeadTypeCodeCBOnChange(sender)
    -- OnChange for headtypecode or haircolorcode or skintonecode
    local playerid = tonumber(PlayersEditorForm.PlayerIDEdit.Text)
    if playerid >= 280000 then
        local headtypecode = tonumber(
            PlayersEditorForm.HeadTypeCodeCB.Items[PlayersEditorForm.HeadTypeCodeCB.ItemIndex] or
            ADDR_LIST.getMemoryRecordByID(COMPONENTS_DESCRIPTION_PLAYER_EDIT['HeadTypeCodeCB']['id']).Value
        )

        local haircolorcode = PlayersEditorForm.HairColorCB.ItemIndex
        if haircolorcode < 0 then
            haircolorcode = tonumber(ADDR_LIST.getMemoryRecordByID(COMPONENTS_DESCRIPTION_PLAYER_EDIT['HairColorCB']['id']).Value)
        end

        local skintonecode = tonumber(
            PlayersEditorForm.SkinColorCB.ItemIndex or
            ADDR_LIST.getMemoryRecordByID(COMPONENTS_DESCRIPTION_PLAYER_EDIT['SkinColorCB']['id']).Value
        )

        local ss_hs = load_headshot(
            playerid,
            skintonecode,
            headtypecode,
            haircolorcode
        )
        PlayersEditorForm.Headshot.Picture.LoadFromStream(ss_hs)
        ss_hs.destroy()
    end
    CommonCBOnChange(sender)
end

function AttributesTrackBarOnChange(sender)
    local comp_desc = COMPONENTS_DESCRIPTION_PLAYER_EDIT[sender.Name]

    local new_val = sender.Position

    local lbl = PlayersEditorForm[comp_desc['components_inheriting_value'][1]]
    local diff = new_val - tonumber(lbl.Caption)
    if comp_desc['depends_on'] then
        for i=1, #comp_desc['depends_on'] do
            local new_attr_val = tonumber(PlayersEditorForm[comp_desc['depends_on'][i]].Text) + diff
            if new_attr_val > ATTRIBUTE_BOUNDS['max'] then
                new_attr_val = ATTRIBUTE_BOUNDS['max']
            elseif new_attr_val < ATTRIBUTE_BOUNDS['min'] then
                new_attr_val = ATTRIBUTE_BOUNDS['min']
            end
            -- save onchange event function
            local onchange_event = PlayersEditorForm[comp_desc['depends_on'][i]].OnChange
            -- tmp disable onchange event
            PlayersEditorForm[comp_desc['depends_on'][i]].OnChange = nil
            -- update value
            PlayersEditorForm[comp_desc['depends_on'][i]].Text = new_attr_val
            -- restore onchange event
            PlayersEditorForm[comp_desc['depends_on'][i]].OnChange = onchange_event
        end
    end

    lbl.Caption = new_val
    sender.SelEnd = new_val
    recalculate_ovr(true)
end

function IsInjuredCBChange(sender)
    is_injured_visibility(sender.ItemIndex)
end

function ReleaseClauseEditChange(sender)
    return
end

-- Common events
function CommonEditOnChange(sender)
    HAS_UNAPPLIED_PLAYER_CHANGES = true
end

function CommonCBOnChange(sender)
    HAS_UNAPPLIED_PLAYER_CHANGES = true
    UpdateCBComponentHint(sender)
end

function CommonCBOnDropDown(sender)
    MakeComponentWider(sender)
end

function CommonCBOnMouseEnter(sender)
    SaveOriginalWidth(sender)
end

function CommonCBOnMouseLeave(sender)
    MakeComponentShorter(sender)
end

function AttrOnChange(sender)
    if sender.Text == '' then return end
    HAS_UNAPPLIED_PLAYER_CHANGES = true
    local new_val = tonumber(sender.Text)

    if new_val == nil then
        -- only numbers
        new_val = math.random(ATTRIBUTE_BOUNDS['min'],ATTRIBUTE_BOUNDS['max'])
    elseif new_val > ATTRIBUTE_BOUNDS['max'] then
        new_val = ATTRIBUTE_BOUNDS['max']
    elseif new_val < ATTRIBUTE_BOUNDS['min'] then
        new_val = ATTRIBUTE_BOUNDS['min']
    end
    sender.Text = new_val

    update_trackbar(sender)
    -- recalculate player ovr 
    recalculate_ovr(true)
end

function HeadTypeGroupCBOnChange(sender)
    PlayersEditorForm.HeadTypeCodeCB.clear()
    local dropdown_selected_value = sender.Items[sender.ItemIndex]
    for key, value in pairs(HEAD_TYPE_GROUPS) do
        local group = string.gsub(key, '_', ' ')
        if group == dropdown_selected_value then
            for j = 1, #value do
                PlayersEditorForm.HeadTypeCodeCB.items.add(value[j])
            end
            break
        end
    end
    CommonCBOnChange(sender)
end

-- COPY CM
function CopyCMFindPlayerByIDClick(sender)
    create_hotkeys({
        sender = sender
    })
    COPY_FROM_CM_PLAYER_ID = nil
    PlayersEditorForm.CopyCMImage.Visible = false
    sender.Text = ''
end

function CopyCMSearchPlayerByIDClick(sender)
    COPY_FROM_CM_PLAYER_ID = nil
    local playerid = tonumber(PlayersEditorForm.CopyCMFindPlayerByID.Text)
    if playerid == nil then 
        PlayersEditorForm.CopyCMImage.Visible = false
        return 
    end

    local org_players = readQword('playerDataPtr')
    local org_tplinks = readQword('ptrTeamplayerlinks')

    COPY_FROM_CM_PLAYER_ID = {
        org_players = org_players,
        keep_original = {
            always = {
                comps = {
                    PlayerIDEdit = PlayersEditorForm.PlayerIDEdit.Text,
                    TeamIDEdit = PlayersEditorForm.TeamIDEdit.Text,
                    ContractValidUntilEdit = PlayersEditorForm.ContractValidUntilEdit.Text,
                    PlayerJoinTeamDateEdit = PlayersEditorForm.PlayerJoinTeamDateEdit.Text,
                    JerseyNumberEdit = PlayersEditorForm.JerseyNumberEdit.Text
                }
            },
            age = {
                cb = PlayersEditorForm.CMCopyAgeCB,
                comps = {
                    AgeEdit = PlayersEditorForm.JerseyNumberEdit.Text
                }
            },
            headmodel = {
                cb = PlayersEditorForm.CMCopyHeadModelCB,
                comps = {
                    HeadClassCodeEdit = PlayersEditorForm.HeadClassCodeEdit.Text,
                    HeadAssetIDEdit = PlayersEditorForm.HeadAssetIDEdit.Text,
                    HeadVariationEdit = PlayersEditorForm.HeadVariationEdit.Text,
                    HairTypeEdit = PlayersEditorForm.HairTypeEdit.Text,
                    HairStyleEdit = PlayersEditorForm.HairStyleEdit.Text,
                    FacialHairTypeEdit = PlayersEditorForm.FacialHairTypeEdit.Text,
                    FacialHairColorEdit = PlayersEditorForm.FacialHairColorEdit.Text,
                    SideburnsEdit = PlayersEditorForm.SideburnsEdit.Text,
                    EyebrowEdit = PlayersEditorForm.EyebrowEdit.Text,
                    EyeColorEdit = PlayersEditorForm.EyeColorEdit.Text,
                    SkinTypeEdit = PlayersEditorForm.SkinTypeEdit.Text,
                    SkinColorCB = PlayersEditorForm.SkinColorCB.ItemIndex,
                    HasHighQualityHeadCB = PlayersEditorForm.HasHighQualityHeadCB.ItemIndex,
                    HairColorCB = PlayersEditorForm.HairColorCB.ItemIndex,
                    HeadTypeCodeCB = PlayersEditorForm.HeadTypeCodeCB.Items[PlayersEditorForm.HeadTypeCodeCB.ItemIndex]
                }
            },
            nameids = {
                cb = PlayersEditorForm.CMCopyNameCB,
                comps = {
                    FirstNameIDEdit = PlayersEditorForm.FirstNameIDEdit.Text,
                    LastNameIDEdit = PlayersEditorForm.LastNameIDEdit.Text,
                    JerseyNameIDEdit = PlayersEditorForm.JerseyNameIDEdit.Text,
                    CommonNameIDEdit = PlayersEditorForm.CommonNameIDEdit.Text
                }
            }
        }
    }

    find_player_by_id(playerid)
    COPY_FROM_CM_PLAYER_ID['players'] = readQword('playerDataPtr')

    -- load headshot
    local stream = load_headshot(
        tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['PLAYERID']).Value),
        tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['SKINTONECODE']).Value),
        tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['HEADTYPECODE']).Value),
        tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['HAIRCOLORCODE']).Value)
    )
    PlayersEditorForm.CopyCMImage.Picture.LoadFromStream(stream)
    stream.destroy()

    -- Restore org player in CT
    writeQword('playerDataPtr', org_players)
    writeQword('ptrTeamplayerlinks', org_tplinks)

    if not PlayersEditorForm.CopyCMImage.Visible then
        PlayersEditorForm.CopyCMImage.Visible = true
    end
end

function CopyCMPlayerLabelClick(sender)
    CopyCMPlayerBtnClick(sender)
end

function CopyCMPlayerBtnClick(sender)
    if not COPY_FROM_CM_PLAYER_ID then
        do_log('Find player first', 'ERROR')
        return
    end

    writeQword('playerDataPtr', COPY_FROM_CM_PLAYER_ID['players'])
    FillPlayerEditForm()

    local org = COPY_FROM_CM_PLAYER_ID['keep_original']

    for key, value in pairs(org) do
        if key == 'always' then
            for c, v in pairs(org['always']['comps']) do
                PlayersEditorForm[c].Text = v
            end
        else
            if org[key]['cb'].State == 1 then
                for c, v in pairs(org[key]['comps']) do
                    if PlayersEditorForm[c].ClassName == 'TCEEdit' then
                        PlayersEditorForm[c].Text = v
                    elseif PlayersEditorForm[c].ClassName == 'TCEComboBox' then
                        if type(v) == 'number' then
                            PlayersEditorForm[c].ItemIndex = v
                        elseif type(v) == 'string' then
                            FillHeadTypeCB({
                                headtypecode = tonumber(v)
                            })
                        end
                    end
                end
            end
        end
    end

    -- Load Img
    local ss_hs = load_headshot(
        tonumber(PlayersEditorForm.PlayerIDEdit.Text),
        tonumber(PlayersEditorForm.SkinColorCB.Text),
        tonumber(PlayersEditorForm.HeadTypeCodeCB.Items[PlayersEditorForm.HeadTypeCodeCB.ItemIndex]),
        tonumber(PlayersEditorForm.HairColorCB.ItemIndex)
    )
    PlayersEditorForm.Headshot.Picture.LoadFromStream(ss_hs)
    ss_hs.destroy()

    recalculate_ovr()
    writeQword('playerDataPtr', COPY_FROM_CM_PLAYER_ID['org_players'])
    ShowMessage('Player data has been copied to GUI.\nTo see the changes in game you need to "Apply Changes"')
end

-- FUT
function FUTChemStyleCBChange(sender)
    sender.Hint = sender.Items[sender.ItemIndex]

    -- Labels on card
    local selected = PlayersEditorForm.FUTPickPlayerListBox.ItemIndex + 1
    local player = FOUND_FUT_PLAYERS[selected]
    if not player then return end
    if not player['details'] then return end

    fut_fill_attributes(player['details'])
end

function FindPlayerByNameFUTEditClick(sender)
    create_hotkeys({
        sender = sender
    })
    sender.Text = ''
end

function SearchPlayerByNameFUTBtnClick(sender)
    PlayersEditorForm.CardContainerPanel.Visible = false
    PlayersEditorForm.FUTPickPlayerListBox.clear()
    if PlayersEditorForm.FindPlayerByNameFUTEdit.Text == '' then return end
    if PlayersEditorForm.FindPlayerByNameFUTEdit.Text == 'Enter player name you want to find' then return end
    fut_search_player(PlayersEditorForm.FindPlayerByNameFUTEdit.Text, 1)
end

function FUTPickPlayerListBoxSelectionChange(sender, user)
    local selected = PlayersEditorForm.FUTPickPlayerListBox.ItemIndex + 1
    local player = FOUND_FUT_PLAYERS[selected]
    if not player then return end
    -- Create CARD in GUI
    fut_create_card(player, selected)

    if not PlayersEditorForm.CardContainerPanel.Visible then
        PlayersEditorForm.CardContainerPanel.Visible = true
    end
end
function CloneFromListBoxSelectionChange(sender, user)
    local Panels = {
        'CloneFromFUTPanel',
        'CloneFromCMPanel',
    }
    for i=1, #Panels do
        if sender.ItemIndex == i-1 then
            PlayersEditorForm[Panels[i]].Visible = true
        else
            PlayersEditorForm[Panels[i]].Visible = false
        end
    end
end

function PrevPageClick(sender)
    if FUT_API_PAGE == 1 then return end

    FUT_API_PAGE = FUT_API_PAGE - 1
    if FUT_API_PAGE < 1 then
        FUT_API_PAGE = 1
    end
    fut_search_player(PlayersEditorForm.FindPlayerByNameFUTEdit.Text, FUT_API_PAGE)
end
function NextPageClick(sender)
    FUT_API_PAGE = FUT_API_PAGE + 1
    fut_search_player(PlayersEditorForm.FindPlayerByNameFUTEdit.Text, FUT_API_PAGE)
end

function FUTCopyPlayerBtnClick(sender)
    local selected = PlayersEditorForm.FUTPickPlayerListBox.ItemIndex + 1
    local player = FOUND_FUT_PLAYERS[selected]

    if not player then
        do_log('Select player card first.', 'ERROR')
        return
    end

    if player['details'] == nil then
        local fut_fifa = FIFA - PlayersEditorForm.FutFIFACB.ItemIndex
        player['details'] = fut_get_player_details(player['id'], fut_fifa)
        FOUND_FUT_PLAYERS[selected]['details'] = player
    end

    
    fut_copy_card_to_gui(player)
    do_log("fut_copy_card_to_gui finished")
end

function CardContainerPanelClick(sender)
    local selected = PlayersEditorForm.FUTPickPlayerListBox.ItemIndex + 1
    local player = FOUND_FUT_PLAYERS[selected]

    local fut_fifa = FIFA - PlayersEditorForm.FutFIFACB.ItemIndex

    local player_page = string.format(
        FUT_URLS['player_details'],
        fut_fifa,
        player['id']
    )
    shellExecute(player_page)
end

function FutFIFACBChange(sender)
    SearchPlayerByNameFUTBtnClick(sender)
end

function PerformanceBonusTypeCBChange(sender)
    if sender.ItemIndex == 0 then
        PlayersEditorForm.PerformanceBonusCountEdit.Text = "None"
        PlayersEditorForm.PerformanceBonusValueEdit.Text = "None"

        PlayersEditorForm.PerformanceBonusCountLabel.Visible = false
        PlayersEditorForm.PerformanceBonusCountEdit.Visible = false
        PlayersEditorForm.PerformanceBonusValueLabel.Visible = false
        PlayersEditorForm.PerformanceBonusValueEdit.Visible = false
    else
        PlayersEditorForm.PerformanceBonusCountLabel.Visible = true
        PlayersEditorForm.PerformanceBonusCountEdit.Visible = true
        PlayersEditorForm.PerformanceBonusValueLabel.Visible = true
        PlayersEditorForm.PerformanceBonusValueEdit.Visible = true
        PlayersEditorForm.PerformanceBonusCountEdit.Text = FillPerformanceBonusCountEdit()
        PlayersEditorForm.PerformanceBonusValueEdit.Text = tonumber(ADDR_LIST.getMemoryRecordByID(COMPONENTS_DESCRIPTION_PLAYER_EDIT['PerformanceBonusValueEdit']['id']).Value) + COMPONENTS_DESCRIPTION_PLAYER_EDIT['PerformanceBonusValueEdit']['modifier']
    end
    UpdateCBComponentHint(sender)
    HAS_UNAPPLIED_PLAYER_CHANGES = true
end
