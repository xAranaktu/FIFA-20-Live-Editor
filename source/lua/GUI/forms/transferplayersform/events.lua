require 'lua/GUI/forms/transferplayersform/helpers';

function TransferPlayersNewTransferBtnClick(sender)
    if TransferPlayersForm.NextTransfersPageBtn.Enabled then
        do_log("Go to last page before you create new transfer", 'ERROR')
        return
    end
    new_custom_transfer()
end
function TransferPlayersNewTransferLabelClick(sender)
    TransferPlayersNewTransferBtnClick(sender)
end

local function get_transfers_csv_header()
    local header = [[
        playerid,from,to,contract_length,release_clause
    ]]

    header = string.gsub(header, "%s+", "")
    return header
end

function ImportTransfersBtnClick(sender)
    if messageDialog("This action will remove all current custom transfers\nAre you sure?", mtInformation, mbYes,mbNo) == mrYes then
        -- pass
    else
        return false
    end

    local dialog = TransferPlayersForm.ImportTransfersDialog
    dialog.Filter = "*.csv"
    dialog.FileName = "Transfers.csv"
    dialog.execute()
    local fname = dialog.FileName
    local line_idx = 1
    if file_exists(fname) then
        do_log(string.format("Importing transfers from: %s", fname))
        for line in io.lines(fname) do
            if line_idx == 1 then
                if line ~= get_transfers_csv_header() then
                    do_log(string.format("Invalid csv file headers: %s", line), 'ERROR')
                end
            else
                local values = split(line, ',')
                if values == nil then break end

                local idx = line_idx - 2

                writeInteger('arr_NewTransfers', line_idx-1)
                -- PlayerID
                writeInteger(
                    string.format('arr_NewTransfers+%s', string.format('%X', (idx) * 20 + 4)),
                    values[1]
                )
                -- Current TeamID
                writeInteger(
                    string.format('arr_NewTransfers+%s', string.format('%X', (idx) * 20 + 12)),
                    values[2]
                )
                -- New TeamID
                writeInteger(
                    string.format('arr_NewTransfers+%s', string.format('%X', (idx) * 20 + 8)),
                    values[3]
                )
                -- Contract Length
                writeInteger(
                    string.format('arr_NewTransfers+%s', string.format('%X', (idx) * 20 + 20)),
                    values[4]
                )
                -- Release Clause
                writeInteger(
                    string.format('arr_NewTransfers+%s', string.format('%X', (idx) * 20 + 16)),
                    values[5]
                )
            end

            line_idx = line_idx + 1
        end
        do_log(string.format("Importing transfers done", fname))
        fill_custom_transfers()
    else
        do_log(string.format("File not exists: %s", fname), 'ERROR')
    end
end
function ExportTransfersBtnClick(sender)
    local dialog = TransferPlayersForm.ExportTransfersDialog
    dialog.FileName = "Transfers.csv"
    dialog.execute()
    if dialog.FileName == nil or dialog.FileName == '' then
        do_log("Invalid file")
        return
    end

    file = io.open(dialog.FileName, "w+")
    file:write(get_transfers_csv_header() .. '\n')
    local num_of_transfers = readInteger('arr_NewTransfers')

    local new_line = {}
    for i=0, num_of_transfers-1 do
        local pid = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 4)))
        local ntid = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 8)))
        local ctid = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 12)))
        local rl_clause = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 16)))
        local cl = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 20)))

        table.insert(new_line, pid)
        table.insert(new_line, ctid)
        table.insert(new_line, ntid)
        table.insert(new_line, cl)
        table.insert(new_line, rl_clause)
        file:write(
            table.concat(new_line, ",") .. '\n'
        )
        new_line = {}
    end
    file:close()
    local success_msg = string.format(
        "%d confirmed custom transfers has been exported to file:\n%s",
        num_of_transfers, dialog.FileName
    )
    do_log(success_msg)
    showMessage(success_msg)
end

function TransferPlayersExitClick(sender)
    TransferPlayersForm.close()
    MainWindowForm.show()
end

function PrevTransfersPageBtnClick(sender)
    CUSTOM_TRANSFERS_PAGE = CUSTOM_TRANSFERS_PAGE - 1
    fill_custom_transfers()
    update_transfers_page()
end
function NextTransfersPageBtnClick(sender)
    CUSTOM_TRANSFERS_PAGE = CUSTOM_TRANSFERS_PAGE + 1
    fill_custom_transfers()
    update_transfers_page()
end

function TransferPlayersSettingsClick(sender)
    SettingsForm.show()
end

function TransferPlayersSyncImageClick(sender)
    fill_custom_transfers()

    -- Update Counter
    update_transfers_counter()
    CUSTOM_TRANSFERS_PAGE = 1
end

function TransferPlayersMinimizeClick(sender)
    TransferPlayersForm.WindowState = "wsMinimized"
end

function TransferPlayersTopPanelMouseDown(sender, button, x, y)
    TransferPlayersForm.dragNow()
end

function TransferTypeListBoxSelectionChange(sender, user)

end

local FillTransferPlayersFormTimer = createTimer(nil)
function TransferPlayersFormShow(sender)
    TransferPlayersForm.TransferTypeListBox.setItemIndex(0)
    -- Load Data
    timer_onTimer(FillTransferPlayersFormTimer, fill_transfers_on_show)
    timer_setInterval(FillTransferPlayersFormTimer, 100)
    timer_setEnabled(FillTransferPlayersFormTimer, true)
end

function fill_transfers_on_show()
    timer_setEnabled(FillTransferPlayersFormTimer, false)
    fill_custom_transfers()

    -- Update Counter
    update_transfers_counter()
end

function reload_team_to_crest(sender)
    local teamid = tonumber(sender.Text)
    if not teamid or teamid == 0 then
        return
    end

    local comp_id = string.gsub(sender.Name, "ToTeamId", "")
    local ToCrestImg = TransferPlayersForm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('ToCrestImage%d', comp_id)]
    local ss_c = load_crest(teamid)
    ToCrestImg.Picture.LoadFromStream(ss_c)
    ss_c.destroy()
end

function reload_team_from_crest(sender)
    local teamid = tonumber(sender.Items[sender.ItemIndex])
    if not teamid or teamid == 0 then
        return
    end

    local comp_id = string.gsub(sender.Name, "FromTeamId", "")
    comp_id = tonumber(comp_id)
    local FromCrestImg = TransferPlayersForm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('FromCrestImage%d', comp_id)]
    local ss_c = load_crest(teamid)
    FromCrestImg.Picture.LoadFromStream(ss_c)
    ss_c.destroy()
end

function confirm_transfer(sender)
    if ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['TRANSFER_PLAYERS_ID']).Active == false then 
        ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['TRANSFER_PLAYERS_ID']).Active = true 
    end
    local comp_id = nil
    if sender.ClassName == 'TCEImage' then
        comp_id = string.gsub(sender.Name, "ConfirmBtnImage", "")
    else
        comp_id = string.gsub(sender.Name, "ConfirmBtnLabel", "")
    end
    comp_id = tonumber(comp_id)
    TransferPlayersForm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('ConfirmBtnLabel%d', comp_id)].Visible = false
    TransferPlayersForm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('ConfirmBtnImage%d', comp_id)].Visible = false

    local num_of_transfers = readInteger('arr_NewTransfers')
    writeInteger('arr_NewTransfers', num_of_transfers + 1)

    -- append
    local playerid = tonumber(TransferPlayersForm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('PlayerIDLabel%d', comp_id)].Caption)

    local current_teamid_comp = TransferPlayersForm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('FromTeamId%d', comp_id)]
    local current_teamid = nil
    if current_teamid_comp.ClassName == 'TEdit' or current_teamid_comp.ClassName == 'TCEEdit' then
        current_teamid = tonumber(current_teamid_comp.Text)
    else
        current_teamid = tonumber(current_teamid_comp.Items[current_teamid_comp.ItemIndex])
    end
    local new_teamid = tonumber(TransferPlayersForm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('ToTeamId%d', comp_id)].Text)
    local release_clause = tonumber(TransferPlayersForm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('ReleaseClauseValue%d', comp_id)].Text) or 0
    local contract_length = (tonumber(TransferPlayersForm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('ContractLengthCombo%d', comp_id)].ItemIndex) + 1) * 12

    writeInteger(
        string.format('arr_NewTransfers+%s', string.format('%X', (num_of_transfers) * 20 + 4)),
        playerid
    )
    writeInteger(
        string.format('arr_NewTransfers+%s', string.format('%X', (num_of_transfers) * 20 + 8)),
        new_teamid
    )
    writeInteger(
        string.format('arr_NewTransfers+%s', string.format('%X', (num_of_transfers) * 20 + 12)),
        current_teamid
    )
    writeInteger(
        string.format('arr_NewTransfers+%s', string.format('%X', (num_of_transfers) * 20 + 16)),
        release_clause
    )
    writeInteger(
        string.format('arr_NewTransfers+%s', string.format('%X', (num_of_transfers) * 20 + 20)),
        contract_length
    )
    do_log(string.format("Confirm transfer. PlayerID: %d, CurrentTeamID: %d, NewTeamID: %d, Clause: %d, Length: %d", playerid, current_teamid, new_teamid, release_clause, contract_length), 'INFO')
    if ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['TRANSFER_PLAYERS_ID']).Active == false then
        do_log("Script -> Transfer players between teams is not active. Transfer will not be finalized", "ERROR")
    end
    update_transfers_counter()
end

function delete_transfer(sender)
    local comp_id = nil
    if sender.ClassName == 'TCEImage' then
        comp_id = string.gsub(sender.Name, "DeleteBtnImage", "")
    else
        comp_id = string.gsub(sender.Name, "DeleteBtnLabel", "")
    end
    comp_id = tonumber(comp_id)

    for i=comp_id, TransferPlayersForm.TransfersScroll.ComponentCount-1 do
        TransferPlayersForm.TransfersScroll.Component[i].Top = TransferPlayersForm.TransfersScroll.Component[i].Top - TransferPlayersForm.TransfersScroll.Component[i].Height
    end

    local num_of_transfers = readInteger('arr_NewTransfers')
    local playerid = tonumber(TransferPlayersForm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('PlayerIDLabel%d', comp_id)].Caption)
    local current_teamid_comp = TransferPlayersForm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('FromTeamId%d', comp_id)]
    local current_teamid = nil
    if current_teamid_comp.ClassName == 'TEdit' or current_teamid_comp.ClassName == 'TCEEdit' then
        current_teamid = tonumber(current_teamid_comp.Text)
    else
        current_teamid = tonumber(current_teamid_comp.Items[current_teamid_comp.ItemIndex])
    end
    local new_teamid = tonumber(TransferPlayersForm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('ToTeamId%d', comp_id)].Text)

    do_log(string.format("Delete Transfer. PlayerID: %d, CurrentTeamID: %d, NewTeamID: %d", playerid, current_teamid, new_teamid), 'INFO')

    rewrite_transfers = {}
    local transfer_is_in_queue = false
    for i=0, num_of_transfers do
        local pid = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 4)))
        local ntid = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 8)))
        local ctid = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 12)))
        local rl_clause = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 16)))
        local cl = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 20)))
        if pid == playerid and ctid == current_teamid and ntid == new_teamid then
            transfer_is_in_queue = true
        else
            table.insert(rewrite_transfers, pid)
            table.insert(rewrite_transfers, ntid)
            table.insert(rewrite_transfers, ctid)
            table.insert(rewrite_transfers, rl_clause)
            table.insert(rewrite_transfers, cl)
        end
    end

    if transfer_is_in_queue then
        do_log("^Transfer in queue", 'INFO')
        for i=1, #rewrite_transfers do
            writeInteger(
                string.format('arr_NewTransfers+%s', string.format('%X', i * 4)),
                rewrite_transfers[i]
            )
        end
        writeInteger('arr_NewTransfers', num_of_transfers - 1)
    end
    update_transfers_counter(num_of_transfers - 1)
    sender.Owner.Visible = false
    CUSTOM_TRANSFERS = CUSTOM_TRANSFERS - 1
end