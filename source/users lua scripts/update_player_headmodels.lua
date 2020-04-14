--- This script will update head models in your current save.
--- Head models added in Patches 5,6,7,8,9,10,11,12,13,14

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

-- Players with updated head models
-- http://soccergaming.com/index.php?threads/list-of-all-new-faces-added-in-title-update-6-tutorial-to-enable-faces.6467431/
local new_headmodels = {
    53050,
    116308,
    140293,
    152997,
    156519,
    156616,
    163050,
    164491,
    167665,
    167943,
    169078,
    169607,
    170719,
    171378,
    172143,
    173434,
    176930,
    177896,
    177937,
    178566,
    179605,
    179731,
    180818,
    182837,
    182879,
    183569,
    183900,
    184274,
    186116,
    186143,
    188154,
    188289,
    189099,
    189177,
    189357,
    189388,
    190362,
    190752,
    191488,
    192317,
    192449,
    192546,
    193141,
    193849,
    196069,
    198904,
    199151,
    199383,
    199827,
    200746,
    200807,
    200855,
    201155,
    201368,
    201519,
    201953,
    202017,
    202541,
    204131,
    204193,
    204210,
    204738,
    204936,
    205941,
    206152,
    206517,
    207439,
    207763,
    207863,
    207935,
    208268,
    208808,
    209660,
    209744,
    210828,
    210881,
    210985,
    211382,
    212214,
    212300,
    212715,
    212878,
    213260,
    213591,
    213619,
    213620,
    214131,
    214153,
    214378,
    214404,
    214659,
    214770,
    214781,
    214971,
    214989,
    215079,
    215135,
    215162,
    216054,
    216433,
    217710,
    218208,
    218464,
    218731,
    219455,
    219754,
    219797,
    219806,
    219841,
    219914,
    220197,
    220597,
    220702,
    221363,
    221564,
    221982,
    222319,
    222358,
    222404,
    222994,
    223113,
    223243,
    223885,
    224065,
    224367,
    225028,
    225236,
    225252,
    225356,
    225423,
    225435,
    225647,
    225659,
    225748,
    225793,
    225878,
    226078,
    226110,
    226162,
    226215,
    226265,
    226501,
    226646,
    226753,
    226783,
    226797,
    226798,
    226911,
    226912,
    226913,
    226915,
    226917,
    226922,
    226923,
    226927,
    226929,
    227145,
    227222,
    227274,
    227394,
    227678,
    228251,
    228618,
    228682,
    228687,
    229582,
    229749,
    230598,
    230613,
    230829,
    231292,
    231478,
    231507,
    231743,
    231979,
    232363,
    232381,
    232425,
    232757,
    232758,
    234221,
    234236,
    234906,
    235123,
    235569,
    235889,
    235926,
    236401,
    236441,
    237183,
    237242,
    237388,
    237604,
    238067,
    238114,
    239097,
    239322,
    239380,
    239454,
    239461,
    239681,
    239838,
    239961,
    240060,
    241376,
    241461,
    241711,
    242437,
    242444,
    242479,
    242491,
    243249,
    243384,
    243386,
    243812,
    244288,
    244363,
    244558,
    244987,
    245061,
    245237,
    245725,
    246104,
    246861,
    247393,
    249119,
    249179,
    249224,
    251804,
    252238,
    252454,
    252460,
    252466,
    23174,
    169321,
    187208,
    192922,
    210374,
    210653,
    213444,
    214718,
    220945,
    222645,
    224151,
    225722,
    228729,
    229699,
    233493,
    235732,
    242118,
    244835,
    162409,
    190720,
    230847
}

function has_new(playerid)
    for j=1, #new_headmodels do
        if (new_headmodels[j] == playerid) then
            table.remove(new_headmodels, j)
            return true
        end
    end
   return false
end

-- players table
local sizeOf = 112 -- Size of one record in players database table (0x64)

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
    
    if has_new(current_playerid) then
        if (
            tonumber(ADDR_LIST.getMemoryRecordByID(comp_desc['HasHighQualityHeadCB']['id']).Value) ~= 1 or
            tonumber(ADDR_LIST.getMemoryRecordByID(comp_desc['HeadClassCodeEdit']['id']).Value) ~= 0 or
            tonumber(ADDR_LIST.getMemoryRecordByID(comp_desc['HeadAssetIDEdit']['id']).Value) ~= current_playerid
        ) then
            updated_players = updated_players + 1
            ADDR_LIST.getMemoryRecordByID(comp_desc['HasHighQualityHeadCB']['id']).Value = 1
            ADDR_LIST.getMemoryRecordByID(comp_desc['HeadClassCodeEdit']['id']).Value = 0
            ADDR_LIST.getMemoryRecordByID(comp_desc['HeadAssetIDEdit']['id']).Value = current_playerid
        end
    end
    
    i = i + 1
    if i >= 26000 then
        break
    end
end

showMessage(string.format("Done\nUpdated head models: %d", updated_players))
