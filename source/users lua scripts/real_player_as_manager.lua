--- This script allows you to change headmodel of your manager to one of the existing scanned headmodels of real players like Giggs or Henry.
--- Make a backup save before you apply this just to be safe. Join this discord for help: https://discord.gg/QFyHUxe
--- It may take a few mins. Cheat Engine will stop responding and it's normal behaviour. Wait until you get 'Done' message.

--- HOW TO USE:
--- 1. Activate FIFA Database Tables script
--- 2. Load your career.
--- 3. In Cheat Engine click on "Memory View" button.
--- 4. Press "CTRL + L" to open lua engine
--- 5. Then press "CTRL + O" and open this script
--- 6. Click on 'Execute' button to execute script and wait for 'done' message box. It may take a few minutes, and the cheat engine will stop responding.

--- AUTHOR: ARANAKTU

require 'lua/GUI/forms/playerseditorform/consts';
require 'lua/consts';

-- EDIT

local user_teamid = 0
local playerid = 0
-- END

if user_teamid == 0 then
    showMessage("Change user_teamid first")
elseif playerid == 0 then
    showMessage("Change playerid first")
end

local comp_desc = get_components_description_manager_edit()

local fields_to_edit = {
    "BodyTypeEdit",
    "EyebrowcodeEdit",
    "EyecolorcodeEdit",
    "FaceposerpresetEdit",
    "FacialhaircolorcodeEdit",
    "FacialhairtypecodeEdit",
    "GenderEdit",
    "HaircolorcodeEdit",
    "HairstylecodeEdit",
    "HairtypecodeEdit",
    "HashighqualityheadEdit",
    "HeadassetidEdit",
    "HeadclasscodeEdit",
    "HeadtypecodeEdit",
    "HeadvariationEdit",
    "HeightEdit",
    "NationalityEdit",
    "SideburnscodeEdit",
    "SkintonecodeEdit",
    "SkintypecodeEdit",
    "WeightEdit"
}

local columns = {
    firstnameid = 1,
    lastnameid = 2,
    playerjerseynameid = 3,
    commonnameid = 4,
    skintypecode = 5,
    trait2 = 6,
    bodytypecode = 7,
    haircolorcode = 8,
    facialhairtypecode = 9,
    curve = 10,
    jerseystylecode = 11,
    agility = 12,
    tattooback = 13,
    accessorycode4 = 14,
    gksavetype = 15,
    positioning = 16,
    tattooleftarm = 17,
    hairtypecode = 18,
    standingtackle = 19,
    preferredposition3 = 20,
    longpassing = 21,
    penalties = 22,
    animfreekickstartposcode = 23,
    animpenaltieskickstylecode = 24,
    isretiring = 25,
    longshots = 26,
    gkdiving = 27,
    interceptions = 28,
    shoecolorcode2 = 29,
    crossing = 30,
    potential = 31,
    gkreflexes = 32,
    finishingcode1 = 33,
    reactions = 34,
    composure = 35,
    vision = 36,
    contractvaliduntil = 37,
    animpenaltiesapproachcode = 38,
    finishing = 39,
    dribbling = 40,
    slidingtackle = 41,
    accessorycode3 = 42,
    accessorycolourcode1 = 43,
    headtypecode = 44,
    sprintspeed = 45,
    height = 46,
    hasseasonaljersey = 47,
    tattoohead = 48,
    preferredposition2 = 49,
    strength = 50,
    shoetypecode = 51,
    birthdate = 52,
    preferredposition1 = 53,
    tattooleftleg = 54,
    ballcontrol = 55,
    shotpower = 56,
    trait1 = 57,
    socklengthcode = 58,
    weight = 59,
    hashighqualityhead = 60,
    gkglovetypecode = 61,
    tattoorightarm = 62,
    balance = 63,
    gender = 64,
    headassetid = 65,
    gkkicking = 66,
    internationalrep = 67,
    animpenaltiesmotionstylecode = 68,
    shortpassing = 69,
    freekickaccuracy = 70,
    skillmoves = 71,
    faceposerpreset = 72,
    usercaneditname = 73,
    avatarpomid = 74,
    attackingworkrate = 75,
    finishingcode2 = 76,
    aggression = 77,
    acceleration = 78,
    headingaccuracy = 79,
    iscustomized = 80,
    eyebrowcode = 81,
    runningcode2 = 82,
    modifier = 83,
    gkhandling = 84,
    eyecolorcode = 85,
    jerseysleevelengthcode = 86,
    accessorycolourcode3 = 87,
    accessorycode1 = 88,
    playerjointeamdate = 89,
    headclasscode = 90,
    defensiveworkrate = 91,
    tattoofront = 92,
    nationality = 93,
    preferredfoot = 94,
    sideburnscode = 95,
    weakfootabilitytypecode = 96,
    jumping = 97,
    personality = 98,
    gkkickstyle = 99,
    stamina = 100,
    playerid = 101,
    marking = 102,
    accessorycolourcode4 = 103,
    gkpositioning = 104,
    headvariation = 105,
    skillmoveslikelihood = 106,
    skintonecode = 107,
    shortstyle = 108,
    overallrating = 109,
    smallsidedshoetypecode = 110,
    emotion = 111,
    runstylecode = 112,
    jerseyfit = 113,
    accessorycode2 = 114,
    shoedesigncode = 115,
    shoecolorcode1 = 116,
    hairstylecode = 117,
    animpenaltiesstartposcode = 118,
    runningcode1 = 119,
    preferredposition4 = 120,
    volleys = 121,
    accessorycolourcode2 = 122,
    tattoorightleg = 123,
    facialhaircolorcode = 124
}

-- manager table
local sizeOf = 0x10C -- Size of one record in manager database table (0x10C)

-- iterate over all managers in 'manager' database table
local i = 0
local current_teamid = 0

local teamid_record = ADDR_LIST.getMemoryRecordByID(comp_desc['TeamidEdit']['id'])

if teamid_record.Value == '??' then
   showMessage("Error\nActivate FIFA Database Tables script and reload your career save")
   return
end

local success = false

function change_vals()
    local fut_players_file_path = "other/fut/base_fut_players.csv"
    for line in io.lines(fut_players_file_path) do
        local values = split(line, ',')
        if playerid == tonumber(values[columns['playerid']]) then
            -- Fix women headassetid
            if values[columns['headassetid']] == '0' then
               values[columns['headassetid']] = values[columns['playerid']]
            end
        
            for j=1, #fields_to_edit do
                local rec = ADDR_LIST.getMemoryRecordByID(comp_desc[fields_to_edit[j]]['id'])
                if rec.Value == '??' then
                   showMessage("Error\nActivate FIFA Database Tables script and reload your career save")
                   return
                end
                rec.Value = math.floor(values[columns[comp_desc[fields_to_edit[j]]['db_col']]] - comp_desc[fields_to_edit[j]]['modifier'])
            end
            ADDR_LIST.getMemoryRecordByID(comp_desc['EthnicityEdit']['id']).Value = math.floor(values[columns['skintonecode']] - comp_desc['EthnicityEdit']['modifier'])
            
            -- +1 in game
            ADDR_LIST.getMemoryRecordByID(comp_desc['ManageridEdit']['id']).Value = 99998
            return true
        end
    end
    return false
end

local reason = "Invalid Teamid"
while true do
    if i >= 1800 then
        break
    end

    local current_teamid = bAnd(bShr(readInteger(string.format('[%s]+%X', 'firstptrManager', teamid_record.getOffset(0)+(i*sizeOf))), teamid_record.Binary.Startbit), (bShl(1, teamid_record.Binary.Size) - 1))

    if (current_teamid + 1) == user_teamid then
        writeQword('ptrManager', readPointer('firstptrManager') + i*sizeOf)
        if change_vals() then
            success = true
        else
            reason = 'Invalid Playerid'
        end
    end

    i = i + 1

end

if success then
    showMessage("Done")
else
    showMessage("Something went wrong... :(\n" .. reason)
end
