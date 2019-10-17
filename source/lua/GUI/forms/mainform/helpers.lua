-- MAIN FORM HELPERS

function set_ce_mem_scanner_state()
    -- Hide/show mem scanner
    local main_form = getMainForm()

    -- local min_h = 378 -- default one

    main_form.Panel5.Constraints.MinHeight = 65
    main_form.Panel5.Height = 65


    -- Works for Cheat Engine 6.8.1
    local comps = {
        "Label6", "foundcountlabel", "sbOpenProcess", "lblcompareToSavedScan",
        "ScanText", "lblScanType", "lblValueType", "SpeedButton2", "btnNewScan",
        "gbScanOptions", "Panel2", "Panel3", "Panel6", "Panel7", "Panel8",
        "btnNextScan", "ScanType", "VarType", "ProgressBar", "UndoScan",
        "scanvalue", "btnFirst", "btnNext", "LogoPanel", "pnlScanValueOptions",
        "Panel9", "Panel10", "Foundlist3", "SpeedButton3", "UndoScan"
    }

    for i=1, #comps do
        if main_form[comps[i]] then
            main_form[comps[i]].Visible = false
        end
    end
end

function update_status_label(text)
    MainWindowForm.LabelStatus.Caption = _translate(text)
end

function deactive_all(record)
    for i=0, record.Count-1 do
        if record[i].Active then record[i].Active = false end
        if record.Child[i].Count > 0 then
            deactive_all(record.Child[i])
        end
    end
end
