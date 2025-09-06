-- Internal Helper Functions
local function get_eye_pos(player)
    if not player:is_player() then
        return {x = 0, y = 0, z = 0}
    end
    local pos = player:get_pos()
    local eye_height = player:get_properties().eye_height
    local look_dir = player:get_look_horizontal()
    local eye_offset = player:get_eye_offset()
    eye_offset = vector.rotate(vector.divide(eye_offset, 10), {x = 0, y = look_dir, z = 0})
    pos = vector.add(pos, eye_offset)
    return {x = pos.x, y = pos.y + eye_height, z = pos.z}
end


-- API
function dice.generate_number_texture(number, font, max, tint)
    local texture = "dice_api_popup_numbers.png"
    local size = 14
    if font and font.texture and size then
        texture = font.texture
        size = font.size
    end
    local color = "#ffffff"
    if tint then
        if #tint == 1 then
            color = tint[1]
        elseif #tint > 1 then
            local num_tint = math.floor(((number - 1) / max) * #tint) + 1
            local num_color = tint[num_tint] or "#ffffff"
            color = num_color
        end
    end
    if number < 10 then
        return 1, "("..texture.."^[verticalframe:10:"..number..")^[multiply:"..color
    elseif number >= 10 and number < 100 then
        local number1 = math.floor(number/10)
        local number2 = number-(number1*10)

        local n1 = texture.."\\^[verticalframe\\:10\\:"..number1
        local n2 = texture.."\\^[verticalframe\\:10\\:"..number2
        return 2, "([combine:"..(size*2).."x"..(size*2)..":3,0="..n1..":"..(size-3)..",0="..n2..")^[multiply:"..color
    end
    return 1, "dice_api_popup_numbers.png^[verticalframe:10:0"
end

function dice.play_sound(object, skin, name, loop, fade)
    if not skin or not skin.definition or not skin.definition.sounds or not skin.definition.sounds[name] then
        return
    end
    local sound = skin:get("sounds")[name]
    local gain = 1
    if fade and loop then
        gain = 0
    end
    local id = core.sound_play(sound, {
        object = object,
        loop = loop or false,
        max_hear_distance = 32,
        gain = gain
    }, not loop)
    if gain == 0 then
        core.sound_fade(id, 2, 1)
    end
    return id
end


function dice.throw_die(playerRef, itemstack)
    local item = itemstack:get_name()
    local name = playerRef:get_player_name()
    local skin = dice.registered_skins[item]
    if not skin then
        return itemstack
    end
    local player = dice.players[name]
    local die = core.add_entity(get_eye_pos(playerRef), "dice_api:die", core.serialize({owner = name, skin=item, itemstack=itemstack:take_item(1):to_string()}))

    local throw_velocity = vector.multiply(playerRef:get_look_dir(), skin:get("throw_velocity"))
    if skin:get("throw_kick") > 0 then
        throw_velocity.y = math.max(throw_velocity.y+skin:get("throw_kick"), skin:get("throw_kick"))
    end
    die:set_velocity(throw_velocity)

    if skin.on_throw then
        skin.on_throw(die:get_luaentity(), playerRef, player.shake_duration)
    end
    player.shake_duration = 0

    -- Play throw sound effect
    dice.play_sound(playerRef, skin, "throw", false)
    return itemstack
end

dice.presets = {
    coin = {
        mesh = "dice_api_coin.b3d",
        textures = {"dice_api_coin_no_texture.png"},
        face_count = 2,
        collisionbox = {-0.03125, -0.03125, -0.03125, 0.03125, 0.03125, 0.03125},
        inventory_scale = 1.5,
        roll_animation = {x=3, y=33}, -- rolling animation
        animate = function()end, -- Override the default animate function for consistent spinning
        min_shake_time = 0,
        throw_velocity = 12,
        throw_kick = 5,
        face_dir = true,
        land_immediate = true,
        face_names = {
            "Heads",
            "Tails"
        },
        popup_size = 2,
        face_popup_textures = {
            "dice_api_popup_coin.png^[verticalframe:2:0",
            "dice_api_popup_coin.png^[verticalframe:2:1"
        },
        groups = {dice_coin = 1, dice_d2 = 1},
    },
    d6 = {
        mesh = "dice_api_d6.b3d",
        textures = {"dice_api_d6_no_texture.png"},
        face_count = 6,
        collisionbox = {-0.21875, -0.21875, -0.21875, 0.21875, 0.21875, 0.21875},
        inventory_scale = 2.4,
        roll_animation = {x=7, y=46},
        animation_speed = 2,
        min_shake_time = 0.2,
        throw_velocity = 12,
        face_dir = true,
        face_dir_pitch = true,
        face_popup_size = 1,
        groups = {dice_d6 = 1},
    },
    d12 = {
        mesh = "dice_api_d12.b3d",
        textures = {"dice_api_d12_no_texture.png"},
        face_count = 12,
        collisionbox = {-0.3, -0.3, -0.3, 0.3, 0.3, 0.3},
        inventory_scale = 2.2,
        roll_animation = {x=13, y=52},
        animation_speed = 3,
        min_shake_time = 0.2,
        throw_velocity = 12,
        face_dir = true,
        face_dir_pitch = true,
        face_popup_size = 1,
        groups = {dice_d12 = 1},
    },
    d20 = {
        face_count = 20,
        mesh = "dice_api_d20.b3d",
        textures = {"dice_api_d20_no_texture.png"},
        collisionbox = {-0.3, -0.3, -0.3, 0.3, 0.3, 0.3},
        inventory_scale = 2.2,
        roll_animation = {x=20, y=59},
        animation_speed = 1.8,
        min_shake_time = 0.2,
        throw_velocity = 12,
        face_dir = true,
        face_dir_pitch = true,
        face_popup_size = 1,
        groups = {dice_d20 = 1},
    }
}

local tableCopy
tableCopy = function(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = tableCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end


local function lerp(a, b, t) return a + (b - a) * t end

local function gradient_colorize(colors, text)
    local col1 = {
        r=tonumber(colors[1]:sub(2,3),16),
        g=tonumber(colors[1]:sub(4,5),16),
        b=tonumber(colors[1]:sub(6,7),16)
    }
    local col2 = {
        r=tonumber(colors[2]:sub(2,3),16),
        g=tonumber(colors[2]:sub(4,5),16),
        b=tonumber(colors[2]:sub(6,7),16)
    }
    local new_string = ""
    for i = 1, #text do
        local t = (i-1)/(#text-1)
        local col = {
            r = math.floor(lerp(col1.r, col2.r, t)),
            g = math.floor(lerp(col1.g, col2.g, t)),
            b = math.floor(lerp(col1.b, col2.b, t))
        }
        local hex = string.format("#%02x%02x%02x", col.r, col.g, col.b)
        new_string = new_string..core.get_color_escape_sequence(hex) .. text:sub(i,i)
    end
    return new_string..core.get_color_escape_sequence("#ffffff")
end


local default_colors = {
    RED = "#ff0000",
    ORANGE = "#ff8000",
    YELLOW = "#ffff00",
    GREEN = "#00ff00",
    CYAN = "#00ffff",
    BLUE = "#0000ff",
    PURPLE = "#7700ff",
    PINK = "#ff00ff",
    WHITE = "#ffffff",
    SILVER = "#c0c0c0",
    GREY = "#505050",
    BLACK = "#000000",
    SLUDGE = "#847e68"
}

function dice.generate_description(tooltip, tooltip_colors, background_color)
    local str = core.get_background_escape_sequence(background_color or "#000000aa")

    if type(tooltip) == "string" then
        return str .. tooltip
    end
    if not tooltip_colors then
        tooltip_colors = default_colors
    else
        for name, color in pairs(default_colors) do
            if not tooltip_colors[name] then
                tooltip_colors[name] = color
            end
        end
    end

    local lines = tableCopy(tooltip)

    for _, line in ipairs(lines) do
        
        local index = 1
        local line_length = #line
        local new_string = core.get_color_escape_sequence("#ffffff")
        if line == "" or line == " " or line == "\n" then goto next_line end

        while index <= line_length do
            local start, end_index, tag = line:find("\\(%w+)\\", index)
            if not start then
                new_string = new_string .. line:sub(index)
                break
            end

            if start > index then
                new_string = new_string .. line:sub(index, start-1)
            end
            local next_start = line:find("\\(%w+)\\", end_index+1)
            local seg_end = next_start and (next_start - 1) or line_length
            local segment = line:sub(end_index+1, seg_end)

            local def = tooltip_colors[tag]
            if type(def) == "string" then
                new_string = new_string .. core.get_color_escape_sequence(def)..segment
            elseif type(def) == "table" then
                new_string = new_string .. gradient_colorize(def, segment)
            else
                new_string = new_string .. core.get_color_escape_sequence("#ffffff")..segment
            end

            
            index = next_start or (seg_end + 1)
        end

        ::next_line::
        str = str .. new_string .. core.get_color_escape_sequence("#ffffff") .. "\n"
    end

    return str:sub(1, -2).. core.get_color_escape_sequence("#ffffff")
end

core.register_globalstep(function(dtime)
    for _, playerRef in pairs(core.get_connected_players()) do
        local itemstack = playerRef:get_wielded_item()
        local item = itemstack:get_name()
        local def = core.registered_nodes[item]
        local name = playerRef:get_player_name()
        if not dice.players[name] then
            dice.players[name] = {
                was_shaking = false,
                shake_duration = 0,
            }
        end
        local player = dice.players[name]

        -- Make sure the player is holding a die
        if not def or not def.groups or not def.groups.dice then
            -- Stop the shake sound if the player is not holding a die
            if player.shake_handle then
                core.sound_fade(player.shake_handle, 2, 0)
                player.shake_handle = nil
                player.shake_duration = 0
            end
            goto next_player
        end
        
        local skin = dice.registered_skins[item]
        if not skin or skin and skin:get("min_shake_time") <= 0 then
            goto next_player
        end
        local controls = playerRef:get_player_control()
        if controls.RMB then
            player.shake_duration = player.shake_duration + dtime
            if skin.on_shake then
                skin.on_shake(playerRef, player.shake_duration)
            end
        end

        if not controls.RMB and player.was_shaking or not controls.RMB and player.shake_handle then
            -- Stop the shake sound
            if player.shake_handle then
                core.sound_fade(player.shake_handle, 2, 0)
                player.shake_handle = nil
            end
            if player.shake_duration > skin:get("min_shake_time") then
                local new_itemstack = dice.throw_die(playerRef, itemstack)
                playerRef:set_wielded_item(new_itemstack)
            end
        end

        player.was_shaking = controls.RMB
        ::next_player::
    end
end)

core.register_chatcommand("rename_die", {
    description = "Rename a die",
    params = "<name>",
    privs = {interact=true, shout=true},
    func = function(name, param)
        local player = core.get_player_by_name(name)
        local itemstack = player:get_wielded_item()
        local item_name = itemstack:get_name()
        local def = core.registered_nodes[item_name]
        if not def or not def.groups or not def.groups.dice then
            return false, "You are not holding a die."
        end
        local skin = dice.registered_skins[item_name]
        if not skin or not skin.definition then
            return false, "You are not holding a die."
        end

        if skin:get("disable_rename") then
            return false, "This die cannot be renamed."
        end

        if string.len(param) >= 64 then
            return false, "Name too long."
        end

        if not param or param == "" then
            -- Reset the name
            itemstack:get_meta():set_string("description", "")
            player:set_wielded_item(itemstack)
            return true, "Name reset."
        end


        -- Recostruct the tooltip with the new name
        local tooltip = skin:get("tooltip")
        local new_tooltip = tableCopy(type(tooltip) == "table" and tooltip or {tooltip})
        new_tooltip[1] = '\\WHITE\\"'..param..'\\WHITE\\"'
        local str = dice.generate_description(new_tooltip, skin:get("tooltip_colors"), skin:get("tooltip_tooltip_background_color"))
        itemstack:get_meta():set_string("description", str)
        player:set_wielded_item(itemstack)

        -- Insert the first line of str
        return true, "Die renamed to "..str:match("^[^\n]*")
    end
})