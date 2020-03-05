-- requirements section

-- Lua INI Parser
-- https://github.com/Dynodzzo/Lua_INI_Parser
LIP = require 'lua/requirements/LIP';

mo = require 'lua/requirements/mo';
_ = nil

-- CONSTS
require 'lua/consts';

-- Helper functions
require 'lua/helpers';

-- GUI Events
require 'lua/GUI/forms/mainform/events';
require 'lua/GUI/forms/settingsform/events';
require 'lua/GUI/forms/playerseditorform/events';
require 'lua/GUI/forms/teamseditorform/events';
require 'lua/GUI/forms/transferplayersform/events';
require 'lua/GUI/forms/matchfixingform/events';
require 'lua/GUI/forms/newmatchfixform/events';
require 'lua/GUI/forms/matchscheduleeditorform/events';
require 'lua/GUI/forms/findteamform/events';
require 'lua/GUI/forms/findplayerform/events';

do_log('New session started', 'INFO')
if cheatEngineIs64Bit() == false then
    do_log('Run 64-bit cheat engine', 'Error')
    assert(false, 'Run 64-bit cheat engine')
end

-- DEFAULT GLOBALS, better leave it as is

if os.getenv('HOMEDRIVE') then
    do_log("os.getenv('HOMEDRIVE') " .. os.getenv('HOMEDRIVE'))
else
    do_log('No HOMEDRIVE env var')
end
if os.getenv('SystemDrive') then
    do_log("os.getenv('SystemDrive') " .. os.getenv('SystemDrive'))
else
    do_log('No SystemDrive env var')
end
HOMEDRIVE = os.getenv('HOMEDRIVE') or os.getenv('SystemDrive') or 'C:'
do_log(string.format("HOMEDRIVE: %s", HOMEDRIVE))

FIFA_SETTINGS_DIR = string.format(
    "%s/Users/%s/Documents/FIFA %s/",
    HOMEDRIVE, os.getenv('USERNAME'), FIFA
);
DATA_DIR = FIFA_SETTINGS_DIR .. 'Live Editor/data/';
CONFIG_FILE_PATH = DATA_DIR .. 'config.ini'; --> 'path to config.ini file 
OFFSETS_FILE_PATH = DATA_DIR .. 'offsets.ini'; --> 'path to offsets.ini file

SETTINGS_INDEX = 0
-- DEFAULT GLOBALS, better leave it as is


-- DEFAULT GLOBALS, may be overwritten in load_cfg()
CACHE_DIR = FIFA_SETTINGS_DIR .. 'Live Editor/cache/';
DEBUG_MODE = false

-- end

-- OTHER GLOBALS
NO_INTERNET = false
IS_SMALL_WINDOW = false

FIFA_PLAYERNAMES = {}
CACHED_PLAYERS = {}

TEAMS_SEARCH_TEAMS_FOUND = {}
PLAYERS_SEARCH_PLAYERS_FOUND = {}

-- SHOW CE
SHOW_CE = true

SCHEDULEEDIT_HOTKEYS_OBJECTS = {}
PLAYEREDIT_HOTKEYS_OBJECTS = {}

COPY_FROM_CM_PLAYER_ID = nil
FUT_API_PAGE = 1
FOUND_FUT_PLAYERS = nil

MENTALITIES_DESC = get_default_mentalities_desc()
TEAMSHEETS_DESC = get_default_teamsheets_desc()
TEAM_PLAYERS = {}
TEAM_MENTALITIES = {}
TEAM_KITS = {}
TEAM_COMPETITION_KITS = {}
TEAM_MANAGER_ADDR = nil
DEFAULT_TSHEET_ADDR = nil
FORMATION_PLAYER_SWAP_0 = nil
SWAP_IMG = nil

CUSTOM_TRANSFERS = 0
MAX_TRANSFERS_PER_PAGE = 3
CUSTOM_TRANSFERS_PAGE = 1

-- Make window resizeable
RESIZER= {
    allow_resize = false
}
RESIZE_MAIN_WINDOW = {
    allow_resize = false
}
-- end

-- start code
-- Activate "GUI" script
MainWindowForm.LoadingPanel.Visible = true
MainWindowForm.LoadingPanel.Caption = _translate('Loading data...')
update_status_label("Waiting for FIFA 20...")
ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['GUI_SCRIPT']).Active = true

-- Check version of Live Editor and Cheat Engine
check_ce_version()
check_le_version()

AOB_DATA = load_aobs()
CFG_DATA = load_cfg()
OFFSETS_DATA = load_offsets()

load_theme()
load_lang()
-- CHECK_CT_UPDATE = check_for_ct_update()

start()

-- end
