-- FIND PLAYER FORM HELPERS
function find_players_by_name(playername)
    local result = {}
    if type(playername) ~= 'string' then
        playername = tostring(playername)
    end

    if string.len(playername) < 3 then
        return result
    end
    playername = string.lower(playername)
    for key, value in pairs(CACHED_PLAYERS) do
        if string.match(value['fullname'], playername) then
            table.insert(result, value)
        end
    end
    return result
end

function clear_search_for_player()
    FindPlayerForm.FindPlayerListBox.clear()
    PLAYERS_SEARCH_PLAYERS_FOUND = {}
end
