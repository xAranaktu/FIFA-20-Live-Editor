--- This script can add/update headmodels from your frostymod
--- You need to edit "headmodels_map" by yourself, pattern is simple:
--- [playerid] = headassetid,
--- by default it updates these faces:
--- paqueta 205361
--- semedo 215556
--- de jong 235526
--- arthur 122574
--- ansu 230899
--- b fernandes 192565
--- tonali 202223
--- haaland 192641
--- neres 231436
--- odegaard 241651
--- Nicolas Pepe 226110
--- Sensi 183795
--- Kubo 232730
--- Carles Perez 230065
--- Yari Verscharen 208549
--- Which are part of Master Patch Revolution 1.0 by (MPR united modders).

--- HOW TO USE:
--- https://i.imgur.com/xZMqzTc.gifv
--- 1. Open Cheat table as usuall and enter your career.
--- 2. In Cheat Engine click on "Memory View" button.
--- 3. Press "CTRL + L" to open lua engine
--- 4. Then press "CTRL + O" and open this script
--- 5. Click on 'Execute' button to execute script and wait for 'done' message box.

--- AUTHOR: ARANAKTU

require 'lua/GUI/forms/playerseditorform/consts';
require 'lua/consts';

local comp_desc = get_components_description_player_edit()

local headmodels_map = {
    [233927] = 205361,
    [227928] = 215556,
    [228702] = 235526,
    [230658] = 122574,
    [253004] = 230899,
    [212198] = 192565,
    [241096] = 202223,
    [239085] = 192641,
    [236632] = 231436,
    [222665] = 241651,
    [226110] = 226110,
    [229857] = 183795,
    [237681] = 232730,
    [240654] = 230065,
    [246419] = 208549
}

-- players table
local sizeOf = 112 -- Size of one record in players database table

-- iterate over all players in 'players' database table
local i = 0
local current_playerid = 0
local updated_players = 0
while true do
    local playerid_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['PLAYERID'])
    local current_playerid = bAnd(bShr(readInteger(string.format('[%s]+%X', 'firstPlayerDataPtr', playerid_record.getOffset(0)+(i*sizeOf))), playerid_record.Binary.Startbit), (bShl(1, playerid_record.Binary.Size) - 1))
    if current_playerid == 0 then
        break
    end

    writeQword('playerDataPtr', readPointer('firstPlayerDataPtr') + i*sizeOf)
    
    local headassetid = headmodels_map[current_playerid]
    if headassetid then
        updated_players = updated_players + 1
        ADDR_LIST.getMemoryRecordByID(comp_desc['HasHighQualityHeadCB']['id']).Value = 1
        ADDR_LIST.getMemoryRecordByID(comp_desc['HeadClassCodeEdit']['id']).Value = 0
        ADDR_LIST.getMemoryRecordByID(comp_desc['HeadAssetIDEdit']['id']).Value = headassetid
    end


    i = i + 1
    if i >= 26000 then
        break
    end
end

showMessage(string.format("Done\nUpdated head models: %d", updated_players))