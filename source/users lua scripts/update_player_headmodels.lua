--- This script will update head models in your current save.
--- Head models added in Patches 5,6,7,8 and 9.

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
	169078,
	184274,
	190362,
	192449,
	199383,
	200855,
	201368,
	202541,
	204193,
	206517,
	210881,
	212300,
	216433,
	220197,
	221982,
	225748,
	225793,
	226078,
	226162,
	227222,
	231743,
	232381,
	239097,
	240060,
	249119,
	249179,
    53050,
    116308,
    152997,
    156519,
    156616,
    163050,
    164491,
    167665,
    167943,
    169607,
    172143,
    176930,
    177937,
    179605,
    180818,
    182837,
    182879,
    183900,
    186143,
    188154,
    188289,
    189177,
    189388,
    190752,
    192546,
    193141,
    193849,
    199827,
    200746,
    200807,
    201155,
    201519,
    204210,
    204936,
    207863,
    208268,
    208808,
    210828,
    210985,
    212214,
    213260,
    214153,
    214378,
    215135,
    215162,
    218464,
    218731,
    219455,
    219754,
    219806,
    219914,
    221363,
    222404,
    223113,
    223885,
    225028,
    225252,
    225647,
    225878,
    226110,
    226753,
    226783,
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
    228251,
    228618,
    228687,
    229582,
    230613,
    231292,
    231478,
    231507,
    231979,
    232363,
    232757,
    232758,
    234236,
    234906,
    235569,
    235889,
    236401,
    236441,
    237604,
    238067,
    239380,
    241461,
    241711,
    242444,
    242491,
    243249,
    243812,
    246104,
    251804,
	237183,
	201953,
	207439,
	214781,
	213619,
	252238,
	225236,
	214971,
	252466,
	242437,
	221564,
	215079,
	244987,
	178566,
	140293,
	224065,
	228682,
	227274,
	226265,
	224367,
	244363,
	214770,
	214404,
	237242,
	239961,
	170719,
	247393,
	235926,
	189357,
	212715,
	222358,
	245061,
	214989,
	183569,
	243384,
	191488,
	216054,
	234221,
	225423,
	226646,
	214131,
	226798,
	205941,
	220597,
	246861,
	232425,
	209744,
	225435,
	226215,
	230598,
	196069,
	239681,
	243386,
	239838,
	245237,
	229749,
	173434,
	177896,
	186116,
	189099,
	192317,
	198904,
	202017,
	206152,
	207935,
	209660,
	211382,
	213591,
	214659,
	217710,
	218208,
	219841,
	220702,
	222994,
	227394,
	227678,
	239322,
	239454,
	239461,
	242479,
	244288,
	245725,
	249224
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
