--- This script allows you to change headmodel of your manager to one of the existing scanned headmodels like Lampard or Klopp.
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

require 'lua/consts';

-- EDIT

local user_teamid = 0
local manager_from_teamid = 0

-- END

local comp_desc = get_components_description_manager_edit()

local fields_to_edit = {
    "BodyTypeEdit",
    "EthnicityEdit",
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
    "ManageridEdit",
    "NationalityEdit",
    "OutfitidEdit",
    "PersonalityidEdit",
    "SeasonaloutfitidEdit",
    "SideburnscodeEdit",
    "SkintonecodeEdit",
    "SkintypecodeEdit",
    "WeightEdit"
}

local columns = {
    firstname = 1,
    commonname = 2,
    surname = 3,
    skintypecode = 4,
    bodytypecode = 5,
    haircolorcode = 6,
    facialhairtypecode = 7,
    managerid = 8,
    hairtypecode = 9,
    headtypecode = 10,
    height = 11,
    seasonaloutfitid = 12,
    weight = 13,
    hashighqualityhead = 14,
    gender = 15,
    headassetid = 16,
    ethnicity = 17,
    faceposerpreset = 18,
    teamid = 19,
    eyebrowcode = 20,
    eyecolorcode = 21,
    personalityid = 22,
    headclasscode = 23,
    nationality = 24,
    sideburnscode = 25,
    headvariation = 26,
    skintonecode = 27,
    outfitid = 28,
    hairstylecode = 29,
    facialhaircolorcode = 30,
}

-- manager table
local sizeOf = 0x10C -- Size of one record in manager database table (0x10C)

-- iterate over all managers in 'manager' database table
local i = 0
local current_teamid = 0

local teamid_record = ADDR_LIST.getMemoryRecordByID(comp_desc['TeamidEdit']['id'])
local success = false
while true do
    if i >= 900 then
        break
    end

    local current_teamid = bAnd(bShr(readInteger(string.format('[%s]+%X', 'firstptrManager', teamid_record.getOffset(0)+(i*sizeOf))), teamid_record.Binary.Startbit), (bShl(1, teamid_record.Binary.Size) - 1))

    if (current_teamid + 1) == user_teamid then
        writeQword('ptrManager', readPointer('firstptrManager') + i*sizeOf)
        local managers_file_path = "other/manager.csv"
        for line in io.lines(managers_file_path) do
            local values = split(line, ',')
            if manager_from_teamid == tonumber(values[columns['teamid']]) then
                for j=1, #fields_to_edit do
                    ADDR_LIST.getMemoryRecordByID(comp_desc[fields_to_edit[j]]['id']).Value = values[columns[comp_desc[fields_to_edit[j]]['db_col']]] - comp_desc[fields_to_edit[j]]['modifier']
                end
            end
        end
        success = true
    end

    i = i + 1

end

if success then
    showMessage("Done")
else 
    showMessage("Something went wrong... :(")
end
