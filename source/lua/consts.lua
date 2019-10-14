-- FIFA Edition
FIFA = "20"

-- PROCESS BASE ADDRESS - Updated after attach
BASE_ADDRESS = nil

-- Size of FIFA module
FIFA_MODULE_SIZE = nil

-- Live Editor ADDRESS LIST
ADDR_LIST = getAddressList()

-- SOME Live Editor MEMORY RECORDS
CT_MEMORY_RECORDS = {
    GUI_SCRIPT = 6,

    HEADTYPECODE = 50,
    BIRTHDATE = 59,
    PLAYERID = 110,
    HAIRCOLORCODE = 14,
    TEAMID = 3527,
}

-- All available forms
FORMS = {
    MainWindowForm, SettingsForm
}

function get_components_description_player_edit()
    return {
        PlayerIDEdit = {id = CT_MEMORY_RECORDS['PLAYERID'], modifier = 0},
        TeamIDEdit = {id = CT_MEMORY_RECORDS['TEAMID'], modifier = 1},
        OverallEdit = {id = 119, modifier = 1},
        PotentialEdit = {id = 37, modifier = 1},
        
        AgeEdit = {
            id = CT_MEMORY_RECORDS['BIRTHDATE'],
            current_date_rec_id = CT_MEMORY_RECORDS['CURRDATE'], 
            modifier = 0,
            valFromFunc = birthdate_to_age,
            onApplyChanges = age_to_birthdate
        },
        FirstNameIDEdit = {id = 51, modifier = 0},
        LastNameIDEdit = {id = 74, modifier = 0},
        CommonNameIDEdit = {id = 129, modifier = 0},
        JerseyNameIDEdit = {id = 126, modifier = 0},
        NationalityCB = {id = 101, modifier = 0},
        ContractValidUntilEdit = {id = 43, modifier = 0},
        PlayerJoinTeamDateEdit = {
            id = 97,
            current_date_rec_id = 2908,
            modifier = 0,
            valFromFunc = days_to_date,
            onApplyChanges = date_to_days
        },
        JerseyNumberEdit = {id = 3524, modifier = 1},
        GKSaveTypeEdit = {id = 21, modifier = 0},
        GKKickStyleEdit = {id = 108, modifier = 0},

        PreferredPosition1CB = {id = 60, modifier = 0},
        PreferredPosition2CB = {id = 56, modifier = -1},
        PreferredPosition3CB = {id = 26, modifier = -1},
        PreferredPosition4CB = {id = 133, modifier = -1},
    
        AttackingWorkRateCB = {id = 83, modifier = 0},
        DefensiveWorkRateCB = {id = 99, modifier = 0},
        SkillMovesCB = {id = 79, modifier = 0},
        WeakFootCB = {id = 104, modifier = 1},
    
        IsRetiringCB = {id = 31, modifier = 0},
        InternationalReputationCB = {id = 75, modifier = 1},
        PreferredFootCB = {id = 102, modifier = 1},
        GenderCB = {id = 71, modifier = 0},
        
        AttackTrackBar = {
            valFromFunc = AttributesTrackBarVal,
            group = 'Attack',
            components_inheriting_value = {
                "AttackValueLabel",
            },
            depends_on = {
                "CrossingEdit", "FinishingEdit", "HeadingAccuracyEdit",
                "ShortPassingEdit", "VolleysEdit"
            },
            events = {
                OnChange = AttributesTrackBarOnChange,
            },
        },
        CrossingEdit = {
            id = 36, 
            modifier = 1,
            group = 'Attack',
            events = {
                OnChange = AttrOnChange,
            },
        },
        FinishingEdit = {
            id = 45, 
            modifier = 1,
            group = 'Attack',
            events = {
                OnChange = AttrOnChange,
            },
        },
        HeadingAccuracyEdit = {
            id = 87, 
            modifier = 1,
            group = 'Attack',
            events = {
                OnChange = AttrOnChange,
            },
        },
        ShortPassingEdit = {
            id = 77,
            modifier = 1,
            group = 'Attack',
            events = {
                OnChange = AttrOnChange,
            },
        },
        VolleysEdit = {
            id = 134,
            modifier = 1,
            group = 'Attack',
            events = {
                OnChange = AttrOnChange,
            },
        },
        
        DefendingTrackBar = {
            valFromFunc = AttributesTrackBarVal,
            group = 'Defending',
            components_inheriting_value = {
                "DefendingValueLabel",
            },
            depends_on = {
                "MarkingEdit", "StandingTackleEdit", "SlidingTackleEdit",
            },
            events = {
                OnChange = AttributesTrackBarOnChange,
            },
        },
        MarkingEdit = {
            id = 111, 
            modifier = 1,
            group = 'Defending',
            events = {
                OnChange = AttrOnChange,
            },
        },
        StandingTackleEdit = {
            id = 25, 
            modifier = 1,
            group = 'Defending',
            events = {
                OnChange = AttrOnChange,
            },
        },
        SlidingTackleEdit = {
            id = 47,
            modifier = 1,
            group = 'Defending',
            events = {
                OnChange = AttrOnChange,
            },
        },
        
        SkillTrackBar = {
            valFromFunc = AttributesTrackBarVal,
            group = 'Skill',
            components_inheriting_value = {
                "SkillValueLabel",
            },
            depends_on = {
                "DribblingEdit", "CurveEdit", "FreeKickAccuracyEdit",
                "LongPassingEdit", "BallControlEdit",
            },
            events = {
                OnChange = AttributesTrackBarOnChange,
            },
        },
        DribblingEdit = {
            id = 46, 
            modifier = 1,
            group = 'Skill',
            events = {
                OnChange = AttrOnChange,
            },
        },
        CurveEdit = {
            id = 16, 
            modifier = 1,
            group = 'Skill',
            events = {
                OnChange = AttrOnChange,
            },
        },
        FreeKickAccuracyEdit = {
            id = 78, 
            modifier = 1,
            group = 'Skill',
            events = {
                OnChange = AttrOnChange,
            },
        },
        LongPassingEdit = {
            id = 27,
            modifier = 1,
            group = 'Skill',
            events = {
                OnChange = AttrOnChange,
            },
        },
        BallControlEdit = {
            id = 62,
            modifier = 1,
            group = 'Skill',
            events = {
                OnChange = AttrOnChange,
            },
        },
        
        GoalkeeperTrackBar = {
            valFromFunc = AttributesTrackBarVal,
            group = 'Goalkeeper',
            components_inheriting_value = {
                "GoalkeeperValueLabel",
            },
            depends_on = {
                "GKDivingEdit", "GKHandlingEdit", "GKKickingEdit",
                "GKPositioningEdit", "GKReflexEdit",
            },
            events = {
                OnChange = AttributesTrackBarOnChange,
            },
        },
        GKDivingEdit = {
            id = 33, 
            modifier = 1,
            group = 'Goalkeeper',
            events = {
                OnChange = AttrOnChange,
            },
        },
        GKHandlingEdit = {
            id = 92,
            modifier = 1,
            group = 'Goalkeeper',
            events = {
                OnChange = AttrOnChange,
            },
        },
        GKKickingEdit = {
            id = 73,
            modifier = 1,
            group = 'Goalkeeper',
            events = {
                OnChange = AttrOnChange,
            },
        },
        GKPositioningEdit = {
            id = 113,
            modifier = 1,
            group = 'Goalkeeper',
            events = {
                OnChange = AttrOnChange,
            },
        },
        GKReflexEdit = {
            id = 38,
            modifier = 1,
            group = 'Goalkeeper',
            events = {
                OnChange = AttrOnChange,
            },
        },
        
        PowerTrackBar = {
            valFromFunc = AttributesTrackBarVal,
            group = 'Power',
            components_inheriting_value = {
                "PowerValueLabel",
            },
            depends_on = {
                "ShotPowerEdit", "JumpingEdit", "StaminaEdit",
                "StrengthEdit", "LongShotsEdit",
            },
            events = {
                OnChange = AttributesTrackBarOnChange,
            },
        },
        ShotPowerEdit = {
            id = 63,
            modifier = 1,
            group = 'Power',
            events = {
                OnChange = AttrOnChange,
            },
        },
        JumpingEdit = {
            id = 105,
            modifier = 1,
            group = 'Power',
            events = {
                OnChange = AttrOnChange,
            },
        },
        StaminaEdit = {
            id = 109,
            modifier = 1,
            group = 'Power',
            events = {
                OnChange = AttrOnChange,
            },
        },
        StrengthEdit = {
            id = 57,
            modifier = 1,
            group = 'Power',
            events = {
                OnChange = AttrOnChange,
            },
        },
        LongShotsEdit = {
            id = 32,
            modifier = 1,
            group = 'Power',
            events = {
                OnChange = AttrOnChange,
            },
        },
        
        MovementTrackBar = {
            valFromFunc = AttributesTrackBarVal,
            group = 'Movement',
            components_inheriting_value = {
                "MovementValueLabel",
            },
            depends_on = {
                "AccelerationEdit", "SprintSpeedEdit", "AgilityEdit",
                "ReactionsEdit", "BalanceEdit",
            },
            events = {
                OnChange = AttributesTrackBarOnChange,
            },
        },
        AccelerationEdit = {
            id = 86,
            modifier = 1,
            group = 'Movement',
            events = {
                OnChange = AttrOnChange,
            },
        },
        SprintSpeedEdit = {
            id = 52, 
            modifier = 1,
            group = 'Movement',
            events = {
                OnChange = AttrOnChange,
            },
        },
        AgilityEdit = {
            id = 18,
            modifier = 1,
            group = 'Movement',
            events = {
                OnChange = AttrOnChange,
            },
        },
        ReactionsEdit = {
            id = 40,
            modifier = 1,
            group = 'Movement',
            events = {
                OnChange = AttrOnChange,
            },
        },
        BalanceEdit = {
            id = 70,
            modifier = 1,
            group = 'Movement',
            events = {
                OnChange = AttrOnChange,
            },
        },
        
        MentalityTrackBar = {
            valFromFunc = AttributesTrackBarVal,
            group = 'Mentality',
            components_inheriting_value = {
                "MentalityValueLabel",
            },
            depends_on = {
                "AggressionEdit", "ComposureEdit", "InterceptionsEdit",
                "AttackPositioningEdit", "VisionEdit", "PenaltiesEdit",
            },
            events = {
                OnChange = AttributesTrackBarOnChange,
            },
        },
        AggressionEdit = {
            id = 85,
            modifier = 1,
            group = 'Mentality',
            events = {
                OnChange = AttrOnChange,
            },
        },
        ComposureEdit = {
            id = 41,
            modifier = 1,
            group = 'Mentality',
            events = {
                OnChange = AttrOnChange,
            },
        },
        InterceptionsEdit = {
            id = 34,
            modifier = 1,
            group = 'Mentality',
            events = {
                OnChange = AttrOnChange,
            },
        },
        AttackPositioningEdit = {
            id = 22,
            modifier = 1,
            group = 'Mentality',
            events = {
                OnChange = AttrOnChange,
            },
        },
        VisionEdit = {
            id = 42,
            modifier = 1,
            group = 'Mentality',
            events = {
                OnChange = AttrOnChange,
            },
        },
        PenaltiesEdit = {
            id = 28,
            modifier = 1,
            group = 'Mentality',
            events = {
                OnChange = AttrOnChange,
            },
        },
    
        -- LongThrowInCB = {id = 1809,},
        -- PowerFreeKickCB = {id = 2079,},
        -- InjuryProneCB = {id = 1812,},
        -- SolidPlayerCB = {id = 1813,},
        -- LeadershipCB = {id = 1822,},
        -- EarlyCrosserCB = {id = 1820,},
        -- FinesseShotCB = {id = 1819,},
        -- FlairCB = {id = 1818,},
        -- SpeedDribblerCB = {id = 1823,},
        -- GKLongthrowCB = {id = 1829,},
        -- PowerheaderCB = {id = 1828,},
        -- GiantthrowinCB = {id = 1832,},
        -- OutsitefootshotCB = {id = 1833,},
        -- SwervePassCB = {id = 1835,},
        -- SecondWindCB = {id = 1834,},
        -- SkilledDribblingCB = {id = 1299,},
        -- FlairPassesCB = {id = 1838,},
        -- ChippedPenaltyCB = {id = 1842,},
        -- BicycleKicksCB = {id = 1841,},
        -- GKFlatKickCB = {id = 1845,},
        -- OneClubPlayerCB = {id = 1846,},
        -- TeamPlayerCB = {id = 1847,},
        -- RushesOutOfGoalCB = {id = 1850,},
        -- CautiousWithCrossesCB = {id = 1856,},
        -- ComesForCrossessCB = {id = 1855,},
        -- SaveswithFeetCB = {id = 1960,},
        -- SetPlaySpecialistCB = {id = 1959,},
        -- InflexibilityCB = {id = 1298,},
        -- DiverCB = {id = 1811,},
        -- AvoidsusingweakerfootCB = {id = 1814,},
        -- TriestobeatdefensivelineCB = {id = 1816,},
        -- SelfishCB = {id = 1817,},
        -- ArguesWithRefereeCB = {id = 1821,},
        -- GKupforcornersCB = {id = 1831,},
        -- PuncherCB = {id = 1830,},
        -- GKOneonOneCB = {id = 1827,},
        -- FansfavouriteCB = {id = 1873,},
        -- AcrobaticClearanceCB = {id = 1836,},
        -- FancyFlicksCB = {id = 1844,},
        -- StutterPenaltyCB = {id = 1843,},
        -- DivingHeaderCB = {id = 1840,},
        -- DrivenPassCB = {id = 1839,},
        -- BacksBacksIntoPlayerCB = {id = 1851,},
        -- HiddenSetPlaySpecialistCB = {id = 1852,},
        -- TakesFinesseFreeKicksCB = {id = 1853,},
        -- TargetForwardCB = {id = 1857,},
        -- BlamesTeammatesCB = {id = 1961,},
        -- TornadoSkillmoveCB = {id = 2078,},
        -- DivesIntoTacklesCB = {id = 1815,},
        -- LongPasserCB = {id = 1825,},
        -- LongShotTakerCB = {id = 1824,},
        -- PlaymakerCB = {id = 1826,},
        -- ChipShotCB = {id = 1848,},
        -- TechnicalDribblerCB = {id = 1849,},
    
        HeightEdit = {id = 53, modifier = 130},
        WeightEdit = {id = 66, modifier = 30},
        BodyTypeCB = {id = 130, modifier = 1},
        HeadTypeCodeCB = {
            id = CT_MEMORY_RECORDS['HEADTYPECODE'],
            modifier = 0,
            already_filled = true,
            events = {
                OnChange = HeadTypeCodeCBOnChange,
                OnDropDown = CommonCBOnDropDown,
                OnMouseEnter = CommonCBOnMouseEnter,
                OnMouseLeave = CommonCBOnMouseLeave,
            },
        },
        HeadTypeGroupCB = {
            valFromFunc = FillHeadTypeCB,
            events = {
                OnChange = HeadTypeGroupCBOnChange,
                OnDropDown = CommonCBOnDropDown,
                OnMouseEnter = CommonCBOnMouseEnter,
                OnMouseLeave = CommonCBOnMouseLeave,
            },
        },
        HairTypeEdit = {id = 24, modifier = 0},
        HairStyleEdit = {id = 128, modifier = 0},
        HairColorCB = {
            id = CT_MEMORY_RECORDS['HAIRCOLORCODE'], 
            modifier = 0,
            events = {
                OnChange = HeadTypeCodeCBOnChange,
                OnDropDown = CommonCBOnDropDown,
                OnMouseEnter = CommonCBOnMouseEnter,
                OnMouseLeave = CommonCBOnMouseLeave,
            },
        },
        FacialHairTypeEdit = {id = 15, modifier = 0},
        FacialHairColorEdit = {id = 137, modifier = 0},
        SideburnsEdit = {id = 103, modifier = 0},
        EyebrowEdit = {id = 89, modifier = 0},
        EyeColorEdit = {id = 93, modifier = 0},
        SkinTypeEdit = {id = 89, modifier = 0},
        SkinColorCB = {id = 117, modifier = 1},

        HasHighQualityHeadCB = {id = 67, modifier = 0},
        HeadAssetIDEdit = {id = 72, modifier = 0},
        HeadVariationEdit = {id = 114, modifier = 0},
        HeadClassCodeEdit = {id = 98, modifier = 0},

        JerseyStyleEdit = {id = 17, modifier = 0},
        JerseyFitEdit = {id = 123, modifier = 0},
        jerseysleevelengthEdit = {id = 94, modifier = 0},
        hasseasonaljerseyEdit = {id = 54, modifier = 0},
        shortstyleEdit = {id = 118, modifier = 0},
        socklengthEdit = {id = 65, modifier = 0},
    
        GKGloveTypeEdit = {id = 68, modifier = 0},
        shoetypeEdit = {id = 58, modifier = 0},
        shoedesignEdit = {id = 125, modifier = 0},
        shoecolorEdit1 = {id = 127, modifier = 0},
        shoecolorEdit2 = {id = 35, modifier = 0},
        AccessoryEdit1 = {id = 96, modifier = 0},
        AccessoryColourEdit1 = {id = 49, modifier = 0},
        AccessoryEdit2 = {id = 124, modifier = 0},
        AccessoryColourEdit2 = {id = 135, modifier = 0},
        AccessoryEdit3 = {id = 48, modifier = 0},
        AccessoryColourEdit3 = {id = 95, modifier = 0},
        AccessoryEdit4 = {id = 20, modifier = 0},
        AccessoryColourEdit4 = {id = 112, modifier = 0},
    
        runningcodeEdit1 = {id = 132, modifier = 0},
        runningcodeEdit2 = {id = 90, modifier = 0},
        FinishingCodeEdit1 = {id = 39, modifier = 0},
        FinishingCodeEdit2 = {id = 84, modifier = 0},
        AnimFreeKickStartPosEdit = {id = 29, modifier = 0},
        AnimPenaltiesStartPosEdit = {id = 131, modifier = 0},
        AnimPenaltiesKickStyleEdit = {id = 30, modifier = 0},
        AnimPenaltiesMotionStyleEdit = {id = 76, modifier = 0},
        AnimPenaltiesApproachEdit = {id = 44, modifier = 0},
        FacePoserPresetEdit = {id = 80, modifier = 0},
        EmotionEdit = {id = 121, modifier = 0},
        SkillMoveslikelihoodEdit = {id = 115, modifier = 0},
        ModifierEdit = {id = 91, modifier = -5},
        IsCustomizedEdit = {id = 88, modifier = 0},
        UserCanEditNameEdit = {id = 81, modifier = 0},
    }
end

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
        ManageridEdit = {id = 3627, modifier = 1, db_col = "managerid"},
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
