-- NEW MATCH FIX FORM HELPERS

function clear_custom_incident_containers()
    for i=0, NewMatchFixForm.MatchIncidentsScroll.ComponentCount-1 do
        NewMatchFixForm.MatchIncidentsScroll.Component[0].destroy()
    end
end

function new_incident(i)
    local playerid = NewMatchFixForm.GoalScorerEdit.Text
    for i=0, NewMatchFixForm.MatchIncidentsScroll.ComponentCount-1 do
        local container = NewMatchFixForm.MatchIncidentsScroll.Component[i]
        for j=0, container.ComponentCount-1 do
            local comp = container.Component[j]
            if comp.Name == string.format('PlayerIDLabel%d', i+1) then
                if comp.Caption == playerid then
                    local ngoals = 0
                    local iplayerid = tonumber(playerid)
                    for k=1, #INCIDENTS['SCORE']['SCORERS'] do
                        if INCIDENTS['SCORE']['SCORERS'][k] == iplayerid then
                            ngoals = ngoals + 1
                        end
                    end
                    container[string.format('IncidentTypeLabel%d', i+1)].Caption = string.format('Goal (%dx)', ngoals)
                    return true
                end
            end
        end
    end
    create_custom_incident_container(i)
end

function create_custom_incident_container(i)
    -- Container
    local custom_incident_container = createPanel(NewMatchFixForm.MatchIncidentsScroll)
    custom_incident_container.Name = string.format('CustomIncidentContainerPanel%d', i+1)
    custom_incident_container.BevelOuter = bvNone
    custom_incident_container.Caption = ''

    custom_incident_container.Color = '0x001B1A1A'
    custom_incident_container.Width = 330
    custom_incident_container.Height = 175
    custom_incident_container.Left = 0
    custom_incident_container.Top = 10 + 165*i

    -- Incident type label
    local available_incidents = {
        'Goal'
    }
    local incident_type_label = createLabel(custom_incident_container)
    incident_type_label.Name = string.format('IncidentTypeLabel%d', i+1)
    incident_type_label.Caption = available_incidents[NewMatchFixForm.IncidentTypeCB.ItemIndex+1]
    incident_type_label.Visible = true
    incident_type_label.AutoSize = false
    incident_type_label.Left = 110
    incident_type_label.Height = 19
    incident_type_label.Width = 90
    incident_type_label.Top = 5
    incident_type_label.Font.Size = 12
    incident_type_label.Font.Color = '0xC0C0C0'
    incident_type_label.Alignment = 'taCenter'

    local playerid = NewMatchFixForm.GoalScorerEdit.Text
    -- Headshot
    find_player_by_id(playerid)
    local headshot_img = createImage(custom_incident_container)
    local stream = load_headshot(
        tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['PLAYERID']).Value),
        tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['SKINTONECODE']).Value),
        tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['HEADTYPECODE']).Value),
        tonumber(ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['HAIRCOLORCODE']).Value)
    )
    headshot_img.Picture.LoadFromStream(stream)
    stream.destroy()
    
    headshot_img.Name = string.format('HeadshotImage%d', i+1)
    headshot_img.Left = 110
    headshot_img.Top = 35
    headshot_img.Height = 90
    headshot_img.Width = 90
    headshot_img.Stretch = true

    local playerid_label = createLabel(custom_incident_container)
    playerid_label.Name = string.format('PlayerIDLabel%d', i+1)
    playerid_label.Caption = playerid
    playerid_label.Visible = true
    playerid_label.AutoSize = false
    playerid_label.Left = 110
    playerid_label.Height = 19
    playerid_label.Width = 90
    playerid_label.Top = 135
    playerid_label.Font.Size = 12
    playerid_label.Font.Color = '0xC0C0C0'
    playerid_label.Alignment = 'taCenter'

    INCIDENTS['SCORE']['UNIQUE_SCORERS'] = INCIDENTS['SCORE']['UNIQUE_SCORERS'] + 1
end