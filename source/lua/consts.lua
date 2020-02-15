-- FIFA Edition
FIFA = "20"

-- PROCESS BASE ADDRESS - Updated after attach
BASE_ADDRESS = nil

-- Size of FIFA module
FIFA_MODULE_SIZE = nil

-- Live Editor ADDRESS LIST
ADDR_LIST = getAddressList()

-- Ultimate Team URLS for FUT Clone feature.
FUT_URLS = {
    player_details = 'https://www.futbin.com/%d/player/%d/',
    player_search = 'https://www.futbin.com/search',
    card_bg = 'https://cdn.futbin.com/content/fifa20/img/cards/',
}

-- SOME Live Editor MEMORY RECORDS
CT_MEMORY_RECORDS = {
    GUI_SCRIPT = 6,
    CURRENT_DATE_SCRIPT = 4406,
    CURRENT_DATE_DAY = 4408,
    CURRENT_DATE_MONTH = 4410,
    CURRENT_DATE_YEAR = 4409,

    -- Injury
    INJURY_TYPE = 2459,

    -- PlayerNames
    PLAYERNAMES_NAMEID = 4830,

    -- DCPlayerNames
    DCPLAYERNAMES_NAMEID = 4825,
    DCPLAYERNAMES_NAME = 4826,

    -- EditedPlayerNames
    EDITEDPLAYERNAMES_COMMONNAME = 4819,
    EDITEDPLAYERNAMES_FIRSTNAME = 4820,
    EDITEDPLAYERNAMES_PLAYERID = 4821,
    EDITEDPLAYERNAMES_PLAYERJERSEYNAME = 4822,
    EDITEDPLAYERNAMES_SURNAME= 4823,

    -- PLAYERS
    HEADTYPECODE = 50,
    BIRTHDATE = 59,
    PLAYERID = 110,
    SKINTONECODE = 117,
    HAIRCOLORCODE = 14,
    FIRSTNAMEID = 51,
    LASTNAMEID = 74,
    COMMONNAMEID = 129,
    PLAYERJERSEYNAMEID = 126,


    -- TEAMS
    TEAMID = 4589,
    TEAMNAME = 4590,

    -- FORMATIONS
    FORMATION_TEAMID = 4603,

    -- default_mentalities
    DEFAULT_MENTALITIES_TEAMID = 4737,

    -- default_teamsheets
    DEFAULT_TEAMSHEETS_TEAMID = 4669,

    -- Teamplayerlinks
    TPLINKS_PLAYERID = 3533,
    TPLINKS_TEAMID = 3527,

    -- Leagueteamlinks
    LEAGUEID = 4239,
    LTL_TEAMID = 4246, 

    -- Calendar
    CURRDATE = 4362,

    -- TransferPlayersScript
    TRANSFER_PLAYERS_ID = 3034,

    SCHEDULEEDITOR_SCRIPT = 2974,
    MATCHFIXING_SCRIPT = 3511,

    -- career_playercontract
    CONTRACT_DATE = 4346,
    CONTRACT_STATUS = 4347,
    CONTRACT_DURATION_MONTHS = 4348,
    CONTRACT_IS_BONUS_ACHIEVED = 4349,
    CONTRACT_LAST_STATUS_CHANGE_DATE = 4350,
    CONTRACT_LOAN_WAGE_SPLIT = 4351,
    CONTRACT_PERFORMANCE_BONUS_COUNT = 4352,
    CONTRACT_PERFORMANCE_BONUS_COUNT_ACHIEVED = 4353,
    CONTRACT_PERFORMANCE_BONUS_TYPE = 4354,
    CONTRACT_PERFORMANCE_BONUS_VALUE = 4355,
    CONTRACT_PLAYERID = 4356,
    CONTRACT_PLAYER_ROLE = 4357,
    CONTRACT_SIGN_ON_BONUS = 4358,
    CONTRACT_TEAMID = 4359,
    CONTRACT_WAGE = 4360,
}

--[[
CZUM size: 112 
lyxL size: 156 
nQVU size: 184 
RrqT size: 16 
qdZF size: 28 
BGwe size: 12 
cQNG size: 8 
EVxj size: 4 
mDGw size: 208 
bneD size: 40 
DvsP size: 28 
onMQ size: 128 
FMpz size: 60 
GdtI size: 64 

to_ignore = {}

function ignore(val)
    for i, junk in ipairs(to_ignore) do
      if junk == val then return true end
    end
    return false
end

function debugger_onBreakpoint()
  local shorname=readString(RDI+0x8) or ""
  shorname = string.sub(shorname, 1, 4)
  if not ignore(shorname) then
      table.insert(to_ignore, shorname)
      local size = readInteger(RSI+0x44)
      print(shorname .. " size: " .. size)
  end

  return 1 -- continue without breaking
end
debug_setBreakpoint(0x1410E78F1)
]]

DB_TABLE_SIZEOF = {
    PLAYERS = 112,
    TEAMS = 156,
    TEAMPLAYERLINKS = 16,
    LEAGUETEAMLINKS = 28,
    CAREER_PLAYERCONTRACT = 28,
    FORMATIONS = 208,
    DEFAULT_MENTALITIES = 204,
    DEFAULT_TEAMSHEETS = 160,
    DCPLAYERNAMES = 40,
    EDITEDPLAYERNAMES = 184
}

DB_TABLE_RECORDS_LIMIT = {
    PLAYERS = 26000,
    TEAMS = 1200,
    TEAMPLAYERLINKS = 27000,
    LEAGUETEAMLINKS = 1700,
    CAREER_PLAYERCONTRACT = 73,
    FORMATIONS = 1200,
    DEFAULT_MENTALITIES = 4500,
    DEFAULT_TEAMSHEETS = 850,
    DCPLAYERNAMES = 6000,
    EDITEDPLAYERNAMES = 1530
}


-- Structrs

-- us002
ROLE_STRUCT = {
    size=0xC,
    pid=0x0,
    role=0x4,
    unk=0x8,    -- first byte is bool? rest?
}

INJ_FIT_STRUCT = {
    size = 0x28,
    pid = 0x0,
    tid = 0x4,  -- or -1
    has_data = 0x8,
    fitness = 0xC,
    unk1 = 0x10,
    unk2 = 0x14,
    inj_type = 0x18,
    fit_on = 0x1C,
    unk3 = 0x20, -- 3 for injured
    regenerated = 0x24  -- higher than 0 for non injured, higher each day
}

RLC_STRUCT = {
    size = 0xC,
    pid = 0x0,
    tid = 0x4,
    value = 0x8,
    end_offset = 0x180,
}

PLAYERFORM_STRUCT = {
    size = 0x74,
    pid = 0x0,
    recent_avg = 0x4,
    form = 0x8,
    last_games_avg_1 = 0xC
}

PLAYERMORALE_STRUCT = {
    size = 0x60,
    pid = 0x0,
    contract = 0x24,
    morale_val = 0x28,
    playtime = 0x30,
}

-- All available forms
FORMS = {
    MainWindowForm, SettingsForm, PlayersEditorForm, TeamsEditorForm, TransferPlayersForm,
    MatchScheduleEditorForm, MatchFixingForm, NewMatchFixForm, FindTeamForm
}


function get_components_description_manager_edit()
    return {
        BodyTypeEdit = {id = 3653, modifier = 1, db_col = "bodytypecode"},
        CommonNameEdit = {id = 3636, modifier = 0, db_col = "commonname"},
        EthnicityEdit = {id = 3638, modifier = 1, db_col = "ethnicity"},
        EyebrowcodeEdit = {id = 3642, modifier = 0, db_col = "eyebrowcode"},
        EyecolorcodeEdit = {id = 3643, modifier = 1, db_col = "eyecolorcode"},
        FaceposerpresetEdit = {id = 3640, modifier = 0, db_col = "faceposerpreset"},
        FacialhaircolorcodeEdit = {id = 3654, modifier = 0, db_col = "facialhaircolorcode"},
        FacialhairtypecodeEdit = {id = 3632, modifier = 0, db_col = "facialhairtypecode"},
        FirstnameEdit = {id = 3630, modifier = 0, db_col = "firstname"},
        GenderEdit = {id = 3635, modifier = 0, db_col = "gender"},
        HaircolorcodeEdit = {id = 3625, modifier = 0, db_col = "haircolorcode"},
        HairstylecodeEdit = {id = 3652, modifier = 0, db_col = "hairstylecode"},
        HairtypecodeEdit = {id = 3628, modifier = 0, db_col = "hairtypecode"},
        HashighqualityheadEdit = {id = 3634, modifier = 0, db_col = "hashighqualityhead"},
        HeadassetidEdit = {id = 3637, modifier = 0, db_col = "headassetid"},
        HeadclasscodeEdit = {id = 3645, modifier = 0, db_col = "headclasscode"},
        HeadtypecodeEdit = {id = 3629, modifier = 0, db_col = "headtypecode"},
        HeadvariationEdit = {id = 3649, modifier = 0, db_col = "headvariation"},
        HeightEdit = {id = 3631, modifier = 130, db_col = "height"},
        ManageridEdit = {id = 3627, modifier = 0, db_col = "managerid"},
        NationalityEdit = {id = 3646, modifier = 0, db_col = "nationality"},
        OutfitidEdit = {id = 3651, modifier = 0, db_col = "outfitid"},
        PersonalityidEdit = {id = 3644, modifier = 0, db_col = "personalityid"},
        SeasonaloutfitidEdit = {id = 3632, modifier = 0, db_col = "seasonaloutfitid"},
        SideburnscodeEdit = {id = 3647, modifier = 0, db_col = "sideburnscode"},
        SkintonecodeEdit = {id = 3650, modifier = 1, db_col = "skintonecode"},
        SkintypecodeEdit = {id = 3648, modifier = 0, db_col = "skintypecode"},
        SurnameEdit = {id = 3639, modifier = 0, db_col = "surname"},
        TeamidEdit = {id = 3641, modifier = 1, db_col = "teamid"},
        WeightEdit = {id = 3633, modifier = 30, db_col = "weight"}
    }
end
