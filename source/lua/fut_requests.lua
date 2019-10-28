json = require 'lua/requirements/json';

-- FUT_URLS = {
--     card_bg = 'https://www.easports.com/fifa/ultimate-team/web-app/content/7D49A6B1-760B-4491-B10C-167FBC81D58A/2019/fut/items/images/backgrounds/itemCompanionBGs/large/cards_bg_e_1_',
--     display = 'https://www.easports.com/fifa/ultimate-team/api/fut/display',
--     player_search = 'https://www.easports.com/fifa/ultimate-team/api/fut/item?jsonParamObject='
-- }

FUT_URLS = {
    player_details = 'https://www.futbin.com/%d/player/%d/',
    player_search = 'https://www.futbin.com/search',
    card_bg = 'https://cdn.futbin.com/content/fifa20/img/cards/',
}

function encodeURI(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
            function (c) return string.format ("%%%02X", string.byte(c)) end)
        str = string.gsub (str, " ", "+")
   end
   return str
end

function fut_get_player_details(playerid, fut_fifa)
    do_log(string.format("Loading FUT%d player: %d", fut_fifa, playerid))
    local request = string.format(
        FUT_URLS['player_details'],
        fut_fifa,
        playerid
    )
    local r = getInternet()
    local reply = r.getURL(request)
    if reply == nil then
        do_log('No internet connection? No reply from: ' .. request, 'ERROR')
        return nil
    end
    do_log(string.format("Reply len: %d", string.len(reply)))

    local base_playerid = string.match(reply, 'data%-baseid="(%d+)"')

    local miniface_img = string.match(reply, '<img class="pcdisplay%-picture%-width " id="player_pic" src="(%a+://[%a+%./%d%?%=]+)')
    local club_img = string.match(reply, '<img id="player_club" src="(%a+://[%a+%./%d%?%=]+)')

    local club_id = 0
    if club_img ~= nil then
        club_id = string.match(club_img, 'clubs/(%d+).png')
    else
        do_log("club_img not found")
    end

    local nation_id = string.match(reply, '<img id="player_nation" src="(%a+://[%a+%./%d%?%=]+)')
    local nation_id = 0
    if nation_img ~= nil then
        nation_id = string.match(nation_img, 'nation/(%d+).png')
    else
        do_log("nation_img not found")
    end

    local ovr = string.match(reply, '<div style="color:[#%S+;|;]+" class="pcdisplay%-rat">(%d+)</div>')
    local name = string.match(reply, '<div style="color:[#%S+;|;]+" class="pcdisplay%-name">([%S-? ?]+)</div>')
    local pos = string.match(reply, '<div style="color:[#%S+;|;]+" class="pcdisplay%-pos">([%w]+)</div>')

    local stat1_name, stat1_val = string.match(reply, '<div%A+class="pcdisplay%-ovr1 stat%-val" data%-stat="(%w+)">(%d+)</div>')
    local stat2_name, stat2_val = string.match(reply, '<div%A+class="pcdisplay%-ovr2 stat%-val" data%-stat="(%w+)">(%d+)</div>')
    local stat3_name, stat3_val = string.match(reply, '<div%A+class="pcdisplay%-ovr3 stat%-val" data%-stat="(%w+)">(%d+)</div>')
    local stat4_name, stat4_val = string.match(reply, '<div%A+class="pcdisplay%-ovr4 stat%-val" data%-stat="(%w+)">(%d+)</div>')
    local stat5_name, stat5_val = string.match(reply, '<div%A+class="pcdisplay%-ovr5 stat%-val" data%-stat="(%w+)">(%d+)</div>')
    local stat6_name, stat6_val = string.match(reply, '<div%A+class="pcdisplay%-ovr6 stat%-val" data%-stat="(%w+)">(%d+)</div>')
    local stat_json = string.match(reply, '<div style="display: none;" id="player_stats_json">([{"%w:,}]+)</div>')

    local special_img, rev, lvl, rare_type = string.match(reply, '<div id="Player%-card" data%-special%-img="(%d)" data%-revision="([(%w+_?)"|"]+) data%-level="(%w+)" data%-rare%-type="(%d+)"')

    local card = nil
    local card_type = nil

    if rev == '"' then
        rev = nil
    elseif rev ~= nil then
        rev = string.gsub(rev, '"', '')
    end

    if fut_fifa == 20 and (rare_type ~= nil and lvl ~= nil)then
        if (rev == nil) or (rev == 'if') then
            -- TODO Other FIFAs
            card = string.format(
                "%d_%s.png",
                rare_type, lvl
            )
            card_type = string.format('%s-%s', rare_type, lvl)
        else
            card = string.format(
                "%d_%s.png",
                rare_type, rev
            )
            card_type = string.format('%s-%s', rare_type, rev)
        end
    else
        rare_type = 1
        rev = 'gold'
        card = string.format(
            "%d_%s.png",
            rare_type, rev
        )
        card_type = string.format('%s-%s', rare_type, rev)
    end

    if stat_json ~= nil then
        stat_json = json.decode(stat_json)
    end

    if DEBUG_MODE then
        do_log(card)
        do_log(card_type)
    end
    do_log(string.format("Loading FUT%d player: %d Finished", fut_fifa, playerid))

    return {
        base_playerid = base_playerid,
        special_img = special_img,
        card = card,
        card_type = card_type,
        miniface_img = miniface_img,
        club_img = club_img,
        nation_img = nation_img,
        club_id = club_id,
        nation_id = nation_id,
        ovr = ovr,
        name = name,
        pos = pos,
        stat1_name = stat1_name,
        stat1_val = stat1_val,
        stat2_name = stat2_name,
        stat2_val = stat2_val,
        stat3_name = stat3_name,
        stat3_val = stat3_val,
        stat4_name = stat4_name,
        stat4_val = stat4_val,
        stat5_name = stat5_name,
        stat5_val = stat5_val,
        stat6_name = stat6_name,
        stat6_val = stat6_val,
        stat_json = stat_json
    }
end

function fut_find_player(player_name, page, fut_fifa)
    -- print(fut_find_player('ronaldo')['items'][1]['age'])
    if string.match(player_name, '[0-9]') then
        -- TODO player name from playerid
    end

    if page == nil then
        page = 1
    end

    local request = FUT_URLS['player_search'] .. string.format(
        '?year=%d&extra=1&term=%s',
        fut_fifa, encodeURI(player_name)
    )

    local r = getInternet()
    local reply = r.getURL(request)
    if reply == nil then
        do_log('No internet connection? No reply from: ' .. request, 'ERROR')
        return nil
    end

    local status, response = pcall(
        json.decode,
        reply
    )

    if status == false then
        do_log('Futbin error: ' .. reply, 'ERROR')
        return nil
    elseif response['error'] then
        do_log('Futbin error: ' .. response['error'], 'ERROR')
        return nil
    end

    return response
end
