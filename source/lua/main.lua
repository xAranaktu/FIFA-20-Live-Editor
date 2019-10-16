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

do_log('New session started', 'INFO')

-- DEFAULT GLOBALS, better leave it as is
HOMEDRIVE = os.getenv('HOMEDRIVE') or os.getenv('SystemDrive') or 'C:'

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
