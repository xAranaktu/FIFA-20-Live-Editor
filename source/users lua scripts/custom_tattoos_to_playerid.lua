--- This script can add/update leftarm tattoos from your frostymod
--- You need to edit "tattoos_map" by yourself, pattern is simple:
--- [playerid] = tattooid,
--- by default it updates these tattoos:
--- 070 : Roberto Firmino 201942
--- 071 : Manuel Lanzini 188988
--- 072 : Dani Ceballos 222509
--- 073 : Emerson Palmieri 210736
--- 074 : Isco 197781
--- 075 : James Maddison 220697
--- 076 : Christian Pulisic 227796
--- 077 : Ricardo Quaresma 20775
--- 078 : Santi Mina 212623
--- 079 : Saul 208421
--- 080 : Arturo Vidal 181872
--- 081 : Maro Icardi 201399
--- 082 : Marcelo 176676
--- 083 : Nainggolan 178518
--- 084 : Gabriel Jesus 230666
--- 085 : Leonardo Bonucci 184344
--- 086 : Samu Castillejo 210617
--- 087 : Coutinho 189242
--- 088 : Joao Cancelo 210514
--- 089 : Milinkovic-Savic 223848
--- 090 : Perotti 183900
--- 091 : Pellegrini 228251
--- 092 : Spinazzola 202884
--- 093 : Douglas Costa 190483
--- 666 : Sergio Ramos 155862


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

local tattoos_map = {
    [201942] = 70,
    [188988] = 71,
    [222509] = 72,
    [210736] = 73,
    [197781] = 74,
    [220697] = 75,
    [227796] = 76,
    [20775] = 77,
    [212623] = 78,
    [208421] = 79,
    [181872] = 80,
    [201399] = 81,
    [176676] = 82,
    [178518] = 83,
    [230666] = 84,
    [184344] = 85,
    [210617] = 86,
    [189242] = 87,
    [210514] = 88,
    [223848] = 89,
    [183900] = 90,
    [228251] = 91,
    [202884] = 92,
    [190483] = 93,
    [155862] = 666,
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
    
    local tattooid = tattoos_map[current_playerid]
    if tattooid then
        updated_players = updated_players + 1
        ADDR_LIST.getMemoryRecordByID(comp_desc['TattooLeftArmEdit']['id']).Value = tattooid
    end


    i = i + 1
    if i >= 26000 then
        break
    end
end

showMessage(string.format("Done\nUpdated tattoos: %d", updated_players))