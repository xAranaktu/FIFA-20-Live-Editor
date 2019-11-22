--- This script will edit players shoes. 
--- By default only Black/White shoes will be replaced by a random shoe model from the "shoe_id_list" with random color.
--- You can set 'randomize_all' variable to true if you want to randoize all shoes. 
--- It may take a few mins. Cheat Engine will stop responding and it's normal behaviour. Wait until you get 'Done' message.

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

local shoe_id_list = {
    16, --- adidas NEMEZIZ MESSI 19.1 302 REDIRECT
    17, --- adidas COPA 19+ 302 REDIRECT
    18, --- adidas NEMEZIZ 19+ 302 REDIRECT
    19, --- adidas PREDATOR 19+ 302 REDIRECT
    20, --- adidas X19+ 302 REDIRECT
    21, --- adidas COPA 19+ INPUT CODE
    22, --- adidas NEMEZIZ 19+ INNER GAME
    23, --- adidas PREDATOR 19+ INPUT CODE
    24, --- adidas X19+ INNER GAME
    25, --- adidas COPA 19+ HARD WIRED
    26, --- adidas NEMEZIZ 19+ HARD WIRED
    27, --- adidas PREDATOR 19+ HARD WIRED
    28, --- adidas X19+ HARD WIRED
    33, --- Lotto Solista 100 III Gravity
    34, --- JOMA Propulsion
    35, --- ASICS DS LIGHT X-FLY 4
    36, --- ASICS DS LIGHT AVANTE
    37, --- Hummel Rapid X Blade Bluebird
    38, --- New Balance Furon V5 - Bayside/Supercell
    39, --- New Balance Tekela V2 - Supercell/Bayside
    45, --- UA Magnetico Control - Black/Glow Orange/White
    46, --- UA Magnetico Control - Glow Orange/White/Black
    47, --- UA Magnetico Pro - Glow Orange/White/Black
    48, --- UA Magnetico Pro - White/Glow Orange/Black
    49, --- Pirma Gladiator Activity
    50, --- Pirma Supreme Legion
    51, --- Mizuno Morelia Neo II - Chinese Red/Silver
    54, --- Mizuno Morelia Neo II Beta - Silver/Gold
    57, --- PUMA FUTURE Anthem
    58, --- PUMA ONE Anthem
    59, --- PUMA FUTUE Rush
    60, --- PUMA ONE Rush
    61, --- umbro Medusae 3 Elite – Black/White
    62, --- umbro Velocita 4 Pro - Black/White
    63, --- umbro Medusae 3 Elite – White/Plum
    64, --- umbro Velocita 4 Pro - White/Plum
    69, --- Nike Mercurial Superfly Elite - Blue
    70, --- Nike PHANTOM VSN - Volt
    71, --- Nike PHANTOM VNM - Volt
    72, --- Nike Tiempo Elite - Black
    73, --- Nike Neymar Jr. Vapor Elite
    130, --- adidas PREDATOR 18+ SHADOW MODE
    131, --- adidas X 18+ SHADOW MODE
    132, --- adidas NEMEZIZ 18+ SHADOW MODE
    133, --- adidas PREDATOR 18.1 W
    134, --- adidas NEMEZIZ 18.1 W
    135, --- adidas PREDATOR 18+ TEAM MODE
    136, --- adidas X 18+ TEAM MODE
    137, --- adidas NEMEZIZ 18+ TEAM MODE
    138, --- adidas PAUL POGBA PREDATOR 18+
    139, --- adidas PREDATOR 18+ SPECTRAL MODE
    140, --- adidas X 18+ SPECTRAL MODE
    141, --- adidas NEMEZIZ 18+ SPECTRAL MODE
    142, --- adidas COPA 18.1 SPECTRAL MODE
    143, --- adidas PREDATOR 18+ COLD MODE
    144, --- adidas X 18+ COLD MODE
    145, --- adidas NEMEZIZ 18+ COLD MODE
    146, --- adidas COPA MID GTX
    147, --- adidas COPA 19+ INITIATOR
    148, --- adidas PREDATOR 19+ INITIATOR
    149, --- adidas X 19+ INITIATOR
    150, --- adidas NEMEZIZ 19+ INITIATOR
    151, --- adidas COPA 19+ ARCHETIC
    152, --- adidas PREDATOR 19+ ARCHETIC
    153, --- adidas X 19+ ARCHETIC
    154, --- adidas NEMEZIZ 19+ ARCHETIC
    155, --- adidas COPA 19+ EXHIBIT
    156, --- adidas PREDATOR 19+ EXHIBIT
    157, --- adidas X 19+ EXHIBIT
    158, --- adidas NEMEZIZ 19+ EXHIBIT
    159, --- adidas COPA 19+ VIRTUSO
    160, --- adidas PREDATOR 19+ VIRTUSO
    161, --- adidas X 19+ VIRTUSO
    162, --- adidas NEMEZIZ 19+ VIRTUSO
    163, --- adidas COPA 19.1 W
    164, --- adidas PREDATOR 19.1 W
    165, --- Pantofola Superleggera
    166, --- adidas COPA 18.1 SHADOW MODE
    167, --- adidas NEMEZIZ MESSI 18.1 SPECTRAL MODE
    168, --- adidas NEMEZIZ MESSI 18.1 TEAM MODE
    169, --- adidas COPA 18.1 TEAM MODE
    170, --- Nike Hypervenom 3PLUS Phantom - Pure Platinum/Alt. Crimson
    171, --- Nike Hypervenom 3PLUS Phantom - Black
    172, --- Nike Hypervenom Phantom Elite DF - Black
    173, --- Nike Hypervenom Phantom Elite DF - Crimson/Wolf Grey
    174, --- Nike Mercurial Superfly Elite - Black
    175, --- Nike Mercurial Superfly Elite - Team Red
    176, --- Nike Mercurial Superfly Elite - Wolf Grey
    177, --- Nike PHANTOM VSN - Black
    178, --- Nike PHANTOM VSN - Pure Platinum
    179, --- Nike PHANTOM VSN - Team Red
    180, --- Nike Tiempo Legend Elite - Black
    181, --- Nike Tiempo Legend Elite - Black/Crimson
    182, --- Nike Neymar Vapor XII Elite
    183, --- Nike Vapor Elite - Black
    184, --- Nike Vapor Elite - Team Red
    185, --- Nike Vapor Elite - Wolf Grey
    186, --- Nike PHANTOM VSN Elite EA SPORTS
    187, --- Nike PHANTOM VSN Black Cat
    188, --- Nike Vapor Elite Black Cat
    189, --- Nike Tiempo 10R
    190, --- Nike Total 90
    191, --- Nike GS3
    192, --- adidas GLITCH Prep Skin 1
    193, --- adidas GLITCH Prep Skin 2
    194, --- adidas GLITCH Exert Skin
    195, --- Umbro Velocita 4 Pro - Black/White/Caribbean Sea
    196, --- Umbro Velocita 4 Pro - Bright Marigold/Peacoat/Spectrum Blue
    197, --- Umbro Velocita 4 Pro - White/Black/Acid Lime
    198, --- Umbro Medusae 2 Elite - White/Black/Acid Lime
    199, --- Umbro Medusae 2 Elite - Black/White/Caribbean Sea
    200, --- Umbro UX Accuro II Pro - Black/White/Caribbean Sea
    201, --- Umbro UX Accuro II Pro - White/Black/Acid Lime
    202, --- Umbro Velocita 4 Pro - Black/White/Marine Green
    203, --- Umbro Medusae 3 Elite - Black/Marine Green
    204, --- UA MAGNETICO PRO - Faded Gold/Black
    205, --- UA MAGNETICO PRO - Red
    206, --- UA Spotlight Pro - Grey
    207, --- UA MAGNETICO PRO - Blue/White
    208, --- UA Spotlight Pro - White/Blue
    209, --- Mizuno Morelia Neo II - Gold
    210, --- Mizuno Morelia Neo II Japan - Black
    211, --- Mizuno Rebula 2 V1 Japan - Gold
    212, --- Mizuno Morelia Neo II Japan - White/Blue
    213, --- Mizuno Rebula 2 V1 Japan - White/Blue
    214, --- Mizuno Morelia Wave Cup Legend - White/Blue
    215, --- adidas NEMEZIZ MESSI 19.1 INITIATOR
    216, --- Umbro Speciali 98 – Black/White/Royal Blue
    217, --- PUMA ONE 1 Lth - Silver/Black/Shocking Orange
    218, --- PUMA FUTURE 2.1 NETFIT - Black/Shocking Orange
    219, --- PUMA FUTURE 2.1 NETFIT - Black/Iron Gate
    220, --- PUMA ONE 1 Lth - Black/Iron Gate
    221, --- PUMA FUTURE 2.1 NETFIT - Silver/Peacoat
    222, --- PUMA ONE 1 Lth - Sodalite Blue/Silver
    223, --- PUMA FUTURE 2.1 NETFIT - Laurel Wreath/White
    224, --- PUMA ONE 1 Lth - Black/White/Laurel Wreath
    225, --- PUMA FUTURE 19.1 - Red Blast/Bleu Azure
    226, --- PUMA ONE 19.1 - Black.Bleu Azure/Red Blast
    227, --- New Balance Furon v4 Pro - Flame/Aztec Gold
    228, --- New Balance Tekela v1 Pro - Polaris/Galaxy
    229, --- New Balance Furon v4 Pro - Bright Cherry/Black
    230, --- New Balance Tekela v1 Pro - White/Bright Cherry
    231, --- Pirma Gladiator Veneno
    232, --- Joma Propulsion Lite
    233, --- Joma Numero 10 Pro FG
    234, --- Joma Propulsion 4.0
    235, --- Joma Aguila Gol FG
    236, --- ASICS Menace 3
    237, --- adidas GLITCH Exhibit Skin
    238, --- adidas GLITCH Initiator Skin
    240, --- BootName_240_Auth-FullChar
    504, --- Nike Tiempo Legend Elite - Black/Crimson
    505, --- Nike Vapor Elite - Wolf Grey
    506, --- Nike Neymar Vapor XII Silêncio
    507, --- adidas NEMEZIZ 19.1 302 REDIRECT
    508, --- adidas NEMEZIZ 19.1 HARD WIRED
    509, --- adidas PREDATOR 19.1 Black/Black/Matte Gold
    510, --- adidas Predator White and Gold
    511, --- adidas PREDATOR 19.1 HARD WIRED
    512, --- Nike Lunar Gato II
    514, --- New Balance Audazo V4 Pro
    516, --- PUMA 365 Roma 1TT - Gray Dawn/NRGY Red
    517, --- umbro Chaleira 2 Pro - White/Black/Regal Blue
    547, --- adidas Samba - Black
    548, --- adidas Samba - Blue
    549, --- adidas Samba - White
}

function inTable(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return key end
    end
    return false
end

-- players table
local sizeOf = 112 -- Size of one record in players database table (0x64)

-- iterate over all players in 'players' database table
local i = 0
local current_playerid = 0

-- false - Randomize only Black/White Boots
-- true  - Randomize all shoes
local randomize_all = false
while true do
    local playerid_record = ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['PLAYERID'])
    local current_playerid = bAnd(bShr(readInteger(string.format('[%s]+%X', 'firstPlayerDataPtr', playerid_record.getOffset(0)+(i*sizeOf))), playerid_record.Binary.Startbit), (bShl(1, playerid_record.Binary.Size) - 1))
    if current_playerid == 0 then
        break
    end

    writeQword('playerDataPtr', readPointer('firstPlayerDataPtr') + i*sizeOf)
    
    local current_shoe = tonumber(ADDR_LIST.getMemoryRecordByID(comp_desc['shoetypeEdit']['id']).Value)
    
    if randomize_all or not inTable(shoe_id_list, current_shoe) then
        -- Random Shoe
        local new_shoe_id = shoe_id_list[math.random(#shoe_id_list)]

        -- Random shoecolorcode1
        local new_color_one = math.random(0, 31)
        
        -- Random shoecolorcode2
        local new_color_two = math.random(0, 31)
        
        ADDR_LIST.getMemoryRecordByID(comp_desc['shoedesignEdit']['id']).Value = 0
        ADDR_LIST.getMemoryRecordByID(comp_desc['shoetypeEdit']['id']).Value = new_shoe_id
        ADDR_LIST.getMemoryRecordByID(comp_desc['shoecolorEdit1']['id']).Value = new_color_one
        ADDR_LIST.getMemoryRecordByID(comp_desc['shoecolorEdit2']['id']).Value = new_color_two
       
    end

    i = i + 1
end

showMessage("Done")