local defaults = {
    tooltip_colors = {
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
    },
    tooltip = {
        "\\PINK\\NO TOOLTIP",
    },
    tooltip_background_color = "#000000aa",
    disable_rename = false,
    face_count = 1,
    textures = {"dice_api_d6_no_texture.png"},
    die_size = 1,
    inventory_scale = 1,
    mesh = "dice_api_d6.b3d",
    roll_animation = {x = 0, y = 0},
    animation_speed = 1,
    fade_fly_sounds = true,
    collisionbox = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
    physics_properties = {
        gravity = -9.81,
        drag = {
            air = 0.98,
            ground = 0.7,
            other = 0.7,
        },
        bounce_loss = {
            wall = 0.5,
            wall_leftover = 0,
            ground = 0.4,
            ground_leftover = 1,
        }
    },
    min_shake_time = 0.2,
    throw_velocity = 12,
    throw_kick = 0,
    face_dir = false,
    lock_face_dir_pitch = false,
    land_immediate = false,
    stopping_velocity = 1,
    rest_time = 3,
    font = {
        texture = "dice_api_popup_numbers.png",
        size = 14,
    },
    disable_popup = false,
    disable_message = false,
    popup_size = 1,
    popup_height = 1.5,
    groups = {dice = 1},
    on_shake = false,
    on_throw = false,
    animate = function(self, speed)
        if speed >= 1.5 then
            local inout = 60 * (speed/12)
            self.object:set_animation_frame_speed(inout * self.skin:get("animation_speed"))
        end
    end,
    on_step = false,
    on_hit = false,
    on_land = false,
    on_return = false,
    on_collect = false,
}


--Rather than setting the default or the set value, we merge tables for these properties
local merge = {
    physics_properties = true,
    tooltip_colors = true,
    groups = true,
}


local tableCopy, merge_tables
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
merge_tables = function(t, merge_table)
    t = t or {}
    for key, value in pairs(merge_table) do
        if type(value) == "table" then
            t[key] = merge_tables(t[key] or {}, value)
        elseif t[key] == nil then
            t[key] = value
        end
    end
    return t
end
local version_numbers = {}
for n in string.gmatch(core.get_version().string, "%d+") do
    table.insert(version_numbers, tonumber(n))
end

-- Make sure Luanti version is 5.13 or higher
local b3d_visual_size = version_numbers[1] == 5 and version_numbers[2] >= 13 or version_numbers[1] > 5

local Skin = {}
Skin.__index = Skin

local newSkin = function (definition)
    local self = {
        definition = definition,
    }
    if type(self.definition) ~= "table" then
        self.definition = {}
    end

    -- Glow for no texture dice
    if self.definition.textures == nil then
        self.definition.glow = 16
    end

    self.definition.groups = self.definition.groups or {}

    -- Check the merge properties
    for property, _ in pairs(merge) do
        if self.definition[property] ~= nil then
            self.definition[property] = merge_tables(self.definition[property], defaults[property])
        end

        -- Check if the preset has a merge property
        if self.definition.preset ~= nil and dice.presets[self.definition.preset] ~= nil and
        dice.presets[self.definition.preset][property] ~= nil then
            self.definition[property] = merge_tables(self.definition[property], dice.presets[self.definition.preset][property])
        end
    end

    for property, value in pairs(self.definition) do
        if type(value) == "function" then
            self[property] = value
        end
    end

    if self.definition.tooltip then
        self.definition.description = dice.generate_description(self.definition.tooltip, self.definition.tooltip_colors, definition.tooltip_background_color)
    end

    return setmetatable(
        self, Skin)
end

function Skin.get(self, name)
    if self.definition[name] ~= nil then
        -- Return property value
        return self.definition[name]
    else
        -- Check if property is in preset
        if dice.presets[self.definition.preset] ~= nil and
        dice.presets[self.definition.preset][name] ~= nil then
            -- Return preset value
            return dice.presets[self.definition.preset][name]
        else
            -- Return the global default value
            return defaults[name] or nil
        end
    end
end


function dice.register_die(name, definition)
    local skin = newSkin(definition)
    -- Get first frames for the animated textures
    local nodeTextures = tableCopy(skin:get("textures"))
    for i, tex in ipairs(nodeTextures) do
        if type(tex) == "table" then
            nodeTextures[i] = tex.texture.."^[verticalframe:"..tex.frame_count..":0"
        end
    end

    core.register_node(name, {
        description = skin:get("description"),
        drawtype = "mesh",
        mesh = skin:get("mesh"),
        visual_scale = b3d_visual_size and skin:get("inventory_scale") or {x = 1, y = 1, z = 1},
        tiles = nodeTextures,
        groups = skin:get("groups"),
        node_placement_prediction = "",
        on_place = function(itemstack, placer, pointed_thing)
            local under = pointed_thing.under
            local node = core.get_node(under)
            local def = core.registered_nodes[node.name]

            if def and def.on_rightclick and not (placer and placer:is_player() and placer:get_player_control().sneak) then
                return def.on_rightclick(under, node, placer, itemstack, pointed_thing)
            end

            if not placer:is_player() then return itemstack end
            if skin:get("min_shake_time") <= 0 then
                return dice.throw_die(placer, itemstack)
            end
            local player_name = placer:get_player_name()
            if not dice.players[player_name].shake_handle then
                dice.players[player_name].shake_handle = dice.play_sound(placer, skin, "shake", true)
            end
            return itemstack
        end,
        on_secondary_use = function(itemstack, user, pointed_thing)
            if not user:is_player() then return itemstack end
            if skin:get("min_shake_time") <= 0 then
                return dice.throw_die(user, itemstack)
            end
            local player_name = user:get_player_name()
            if not dice.players[player_name].shake_handle then
                dice.players[player_name].shake_handle = dice.play_sound(user, skin, "shake", true)
            end
            return itemstack
        end
    })

    dice.registered_skins[name] = skin

end