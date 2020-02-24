--- This script will set all players attributes on 1 and potential on 99

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

local attributes_to_change = {
    "Overall",
    "Crossing",
    "Finishing",
    "HeadingAccuracy",
    "ShortPassing",
    "Volleys",
    "Marking",
    "StandingTackle",
    "SlidingTackle",
    "Dribbling",
    "Curve",
    "FreeKickAccuracy",
    "LongPassing",
    "BallControl",
    "GKDiving",
    "GKHandling",
    "GKKicking",
    "GKPositioning",
    "GKReflex",
    "ShotPower",
    "Jumping",
    "Stamina",
    "Strength",
    "LongShots",
    "Acceleration",
    "SprintSpeed",
    "Agility",
    "Reactions",
    "Balance",
    "Aggression",
    "Composure",
    "Interceptions",
    "AttackPositioning",
    "Vision",
    "Penalties",
}

-- players table
local sizeOf = 112 -- Size of one record in players database table (0x64)

-- iterate over all players in 'players' database table
local i = 0
local current_playerid = 0
local updated_players = 0
while true do
    local playerid_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['PLAYERID'])
    local current_playerid = bAnd(bShr(readInteger(string.format('[%s]+%X', 'firstPlayerDataPtr', playerid_record.getOffset(0)+(i*sizeOf))), playerid_record.Binary.Startbit), (bShl(1, playerid_record.Binary.Size) - 1))

    if current_playerid > 0 then
        writeQword('playerDataPtr', readPointer('firstPlayerDataPtr') + i*sizeOf)
    
        for j=1, #attributes_to_change do
            local attr_name = attributes_to_change[j] .. 'Edit'
            ADDR_LIST.getMemoryRecordByID(comp_desc[attr_name]['id']).Value = 0
        end
        ADDR_LIST.getMemoryRecordByID(comp_desc['PotentialEdit']['id']).Value = 98
    end

    i = i + 1
    if i >= 26000 then
        break
    end
end

showMessage("Done")
