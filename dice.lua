

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


local die = {
    initial_properties = {
        visual = "mesh",
        mesh = "dice_api_d6.b3d",
        textures = {"dice_api_d6_no_texture.png"},
        physical = true,
        makes_footstep_sound = true,
        backface_culling = false,
        collisionbox = {-0.21875, -0.21875, -0.21875, 0.21875, 0.21875, 0.21875},
    }
}

function die.remove(self, player)
    local item = ItemStack(self.itemstack)
    local pos = self.object:get_pos()
    if not player or not player:get_inventory():room_for_item("main", item) then
        core.add_item(pos, item)
        if self.skin and self.skin.on_death then
            self.skin.on_death(player, pos, self.itemstack, "drop")
        end
        self.itemstack = ""
    else
        player:get_inventory():add_item("main", item)
        if self.skin.on_death then
            self.skin.on_death(player, pos, self.itemstack, "collect")
        end
        self.itemstack = ""
    end
    if self.popup then
        self.popup.parent_die = nil
        self.popup.animation_timer = 2
    end
    if self.sound_handle ~= nil then
        core.sound_fade(self.sound_handle, 2, 0)
        self.sound_handle = nil
    end
    self.removed = true
    self.object:remove()
end

function die.on_death(self, killer)
    if not self.removed and self.itemstack then
        self.remove(self)
    end
end

function die.on_activate(self, staticdata)
    local data = core.deserialize(staticdata)
    if not data or not data.owner or not data.itemstack then
        self.remove(self)
        return
    end
    self.object:set_armor_groups({immortal = 1})
    self.owner = data.owner
    self.itemstack = data.itemstack
    self.skin = dice.registered_skins[ItemStack(self.itemstack):get_name()]
    self.timers = data.timers or {}
    self.mode = data.mode or "flying"
    self.sound_handle = data.sound_handle
    if not self.skin then
        self.remove(self)
        return
    end

    self.hit_count = 0
    self.animations = {}

    local textures = tableCopy(self.skin:get("textures"))
    for i, tex in ipairs(textures) do
        if type(tex) == "table" then
            self.animations[i] = {
                definition = tex,
                timer = 0,
                frame = 0
            }
            textures[i] = tex.texture.."^[verticalframe:"..tex.frame_count..":0"
        end
    end
    local die_size = self.skin:get("die_size")
    self.object:set_properties({
        textures = textures,
        collisionbox = self.skin:get("collisionbox"),
        mesh = self.skin:get("mesh"),
        glow = self.skin:get("glow"),
        visual_size = {x = die_size, y = die_size},
        collides_with_objects = self.skin:get("collides_with_objects"),
    })
    self.object:set_animation(self.skin:get("roll_animation"), 60*self.skin:get("animation_speed"), 0.1, true)
    if self.mode == "landed" then
        self.object:set_animation({x=1, y=1}, 0, 0, true)
    elseif not self.sound_handle then
        self.sound_handle = dice.play_sound(self.object, self.skin, "fly", true, true)
    end
end

function die.get_staticdata(self)
    return core.serialize({
        owner = self.owner,
        itemstack = self.itemstack,
        mode = self.mode,
        timers = self.timers,
        sound_handle = self.sound_handle
    })
end

function die.collision_handler(self, moveresult)
    local physics = self.skin:get("physics_properties")
    local land_immediate = self.skin:get("land_immediate")
    for _, col in ipairs(moveresult.collisions) do

        -- Play rolling sound effect
        if self.hit_count == 0 then
            dice.play_sound(self.object, self.skin, "first_impact", false)
        end

        -- Play hit sound, (if there is no first_impact then the hit sound will be played instead)
        if self.hit_count > 0 or self.skin:get("sounds") and not self.skin:get("sounds").first_impact then
            if not (land_immediate and col.axis == "y") then
                dice.play_sound(self.object, self.skin, "hit", false)
            end
        end

        -- Custom behavior for ground/ceiling bounces
        if col.axis == "y" then
            self.drag = physics.drag.ground -- Increase drag while in contact with a surface
            if land_immediate and col.type == "node" and col.node_pos.y < self.object:get_pos().y then
                self.drag = 0
                goto next
            end
                -- Only bounce if the velocity is high enough to prevent infinitely smaller bouncing
            if math.abs(col.old_velocity.y) > 2 then
                self.vel.y = col.old_velocity.y*-physics.bounce_loss.ground

                -- Add the lost velocity of the bounce to the other two axis
                local newVel = vector.normalize(col.new_velocity)
                self.vel = vector.add(self.vel, vector.multiply(newVel, col.old_velocity.y*-(1-physics.bounce_loss.ground * physics.bounce_loss.ground_leftover)))
            end
            
            goto next
        else
            self.drag = physics.drag.other -- Increase drag while in contact with a surface
            -- Wall bounces
            self.vel[col.axis] = col.old_velocity[col.axis]*-physics.bounce_loss.wall
            
            -- Add the lost velocity of the bounce to the other two axis
            local newVel = vector.normalize(col.new_velocity)
            self.vel = vector.add(self.vel, vector.multiply(newVel, col.old_velocity[col.axis]*-(1-physics.bounce_loss.wall * physics.bounce_loss.wall_leftover)))
        end

        ::next::
        self.hit_count = self.hit_count + 1
        if self.skin.on_hit and self.skin.on_hit(self, core.get_player_by_name(self.owner), col, self.hit_count) then return true end
    end
    return false
end

local function random2(min,max) -- Was having some wierd bugs with math.random being weird
    return math.floor((math.random(0, 10000)) * (max - min) / (10000) + min)
end

function die.landing_handler(self, moveresult)
    local pos = self.object:get_pos()
    if vector.length(self.vel) < self.skin:get("stopping_velocity") and moveresult.touching_ground then
        self.mode = "landed"
        self.object:set_rotation({x=0, y=math.random(-math.pi, math.pi), z=0})
        self.vel = {x=0, y=0, z=0}
        local roll = random2(1, self.skin:get("face_count") + 1)
        self.object:set_animation_frame_speed(0)
        self.object:set_animation({x=roll, y=roll}, 0, 0, true)
        if self.sound_handle ~= nil then
            core.sound_fade(self.sound_handle, 2, 0)
            self.sound_handle = nil
        end
        dice.play_sound(self.object, self.skin, "land", false)
        if not self.skin:get("disable_popup") then
            self.popup = core.add_entity(pos, "dice_api:popup", core.serialize({skin=ItemStack(self.itemstack):get_name(), roll=roll})):get_luaentity()
            self.popup.parent_die = self
        end
        
        local result = roll
        self.result = result
        if self.skin:get("face_names") then
            result = self.skin:get("face_names")[roll]
        end

        if self.skin.on_land and self.skin.on_land(self, core.get_player_by_name(self.owner), self.result) then return true end

        if not self.skin:get("disable_message") then
            local itemname = ItemStack(self.itemstack):get_description():match("^[^\n]*")
            core.chat_send_player(self.owner, "Your " .. itemname .. " landed on: "..result.."")
        end
    end
    return false
end

function die.animate_textures(self, dtime)
    -- Handle texture animations
    local textures = tableCopy(self.object:get_properties().textures)
    for name, tex in ipairs(self.animations) do
        tex.timer = tex.timer + dtime
        local frame_length = tex.definition.duration/tex.definition.frame_count
        if tex.timer > frame_length then
            --Skip the number of frames that should have passed based on dtime
            local frames_passed = math.floor(tex.timer / frame_length + 1)
            tex.timer = 0
            tex.frame = (tex.frame + frames_passed) % tex.definition.frame_count
            textures[name] = tex.definition.texture.."^[verticalframe:"..tex.definition.frame_count..":"..tex.frame
        end
    end
    if textures ~= self.object:get_properties().textures then
        self.object:set_properties({textures = textures})
    end
end

function die.animate(self, dtime)
    local speed = vector.length(self.object:get_velocity())
    if self.skin.animate then
        self.skin.animate(self, speed)
    end
    if self.skin:get("face_dir") then
        -- Set based on the movement direction
        local dir = self.object:get_velocity()
        if self.skin:get("lock_face_dir_pitch") then
            dir.y = 0
        end
        dir = vector.normalize(dir)
        self.object:set_rotation(vector.dir_to_rotation(dir))
    end

    -- Fade fly sound based on speed
    if self.sound_handle and speed > 0 and speed < 12 and self.mode ~= "landed" then -- Fade fly volume based on speed
        core.sound_fade(self.sound_handle, 2, math.max(speed/12, 0.01))
    end
end

function die.return_to_owner(self, dtime)
    local player = core.get_player_by_name(self.owner)
    local target = get_eye_pos(player)
    local pos = self.object:get_pos()

    local offset = vector.normalize(vector.subtract(target, pos))
    offset = vector.multiply(offset, 32)
    self.object:set_velocity(offset)
    self.animate(self, dtime)

    -- Closer distance between the eyes and the feet
    local distance = math.min(vector.distance(pos, player:get_pos(), vector.distance(pos, get_eye_pos(player))))
    if distance < 2 then
        dice.play_sound(player, self.skin, "collect", false)
        self.remove(self, player)
        return
    end
end

function die.on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
    if self.skin.on_punch then
        return self.skin.on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
    else
        if self.mode == "landed" and self.owner and self.owner == puncher:get_player_name() then
            self.remove(self, puncher)
            return
        end
    end
end

function die.on_step(self, dtime, moveresult)
    if not self or not self.object then
        return
    end
    -- If owner leaves or if owner information is somehow lost, drop the dice in item form
    if not self.owner or self.owner and not core.get_player_by_name(self.owner) then
        self.remove(self)
        return
    end

    for name, time in pairs(self.timers) do
        self.timers[name] = time + dtime
    end

    -- Don't animate textures if the server is running slower than 40 steps per second
    if dtime < 1/40 then 
        self.animate_textures(self, dtime)
    end

    if self.skin.on_step then
        self.skin.on_step(self, core.get_player_by_name(self.owner), dtime, moveresult)
    end

    if self.mode == "returning" then
        self.return_to_owner(self, dtime)
        return
    elseif self.mode == "landed" and moveresult.touching_ground then
        if not self.timers.rest then
            self.timers.rest = 0
        end
        if self.timers.rest > self.skin:get("rest_time") then
            self.mode = "returning"
            self.object:set_properties({
                collides_with_objects = false,
                physical = false,
                makes_footstep_sound = false
            })
            self.object:set_animation(self.skin:get("roll_animation"), 60*self.skin:get("animation_speed"), 0.1, true)
            self.sound_handle = dice.play_sound(self.object, self.skin, "returning", true, true)
            if self.skin.on_return then
                self.skin.on_return(self, core.get_player_by_name(self.owner))
            end
        end
        return
    end
    if self.object:get_properties().physical == false then
        self.object:set_properties({
            physical = true,
            collides_with_objects = self.skin:get("collides_with_objects")
        })
    end

    
    local physics = self.skin:get("physics_properties")
    self.drag = physics.drag.air

    --Gravity
    if not moveresult.touching_ground and not self.disable_gravity then
        self.object:set_acceleration({x=0, y=physics.gravity, z=0})
    else
        self.object:set_acceleration({x=0, y=0, z=0})
        self.drag = physics.drag.ground
    end

    
    self.vel = self.object:get_velocity()
    if self.mode == "flying" then
        local dead = false
        dead = dead or self.collision_handler(self, moveresult)
        if dead then return end
        dead = dead or self.landing_handler(self, moveresult)
        if dead then return end
        self.animate(self, dtime)
        -- Apply drag to velocity
        local oldy = self.vel.y
        self.vel = vector.multiply(self.vel, self.drag)
        self.vel.y = oldy
        self.object:set_velocity(self.vel)
    end
end

function die.set_textures(self, textures)
    if textures then
        self.animations = {}
        local new_textures = tableCopy(textures)
        for i, tex in ipairs(textures) do
            if type(tex) == "table" then
                self.animations[i] = {
                    definition = tex,
                    timer = 0,
                    frame = 0
                }
                new_textures[i] = tex.texture.."^[verticalframe:"..tex.frame_count..":0"
            end
        end
        self.object:set_properties({
            textures = new_textures
        })
    end
end

core.register_entity("dice_api:die", die)
core.register_entity("dice_api:popup", {
    initial_properties = {
        visual = "sprite",
        visual_size = {x=1, y=1},
        collisionbox = {0, 0, 0, 0, 0, 0},
        physical = false,
        collides_with_objects = false,
        makes_footstep_sound = false,
        glow = 15
    },
    on_activate = function(self, staticdata)
        local data = core.deserialize(staticdata)
        if data then
            if not data.skin then self.object:remove() return end
            local skin = dice.registered_skins[data.skin]
            local popup_texture, popup_scale
            if not skin:get("face_popup_textures") then
                popup_scale, popup_texture = dice.generate_number_texture(data.roll, skin:get("font"), skin:get("face_count"), skin:get("popup_tint"))
            else
                popup_texture = skin:get("face_popup_textures")[data.roll]
                popup_scale = 1
                if skin:get("popup_tint") then
                    local color = "#ffffff"
                    if #skin:get("popup_tint") == 1 then
                        color = skin:get("popup_tint")[1]
                    elseif #skin:get("popup_tint") > 1 then
                        local num_tint = math.floor(((data.roll - 1) / skin:get("face_count")) * #skin:get("popup_tint")) + 1
                        local num_color = skin:get("popup_tint")[num_tint] or "#ffffff"
                        color = num_color
                    end
                    popup_texture = popup_texture.."^[multiply:"..color
                end
            end
            local popup_size = skin:get("popup_size")
            self.size = popup_size*popup_scale
            self.object:set_properties({
                textures = {popup_texture},
                visual_size = {x=self.size, y=self.size}
            })
            self.popup_height = skin:get("popup_height")
        else
            self.object:remove()
            return
        end
        self.alive = true
        self.animation_timer = 0
    end,
    on_step = function(self, dtime)
        if self.alive then
            self.animation_timer = self.animation_timer + dtime
            if self.parent_die and self.parent_die.object and self.parent_die.object:get_pos() then
                local pos = self.object:get_pos()
                local parent_pos = self.parent_die.object:get_pos()
                if not parent_pos then return end
                local x = self.animation_timer/2
                local i = x == 1 and 1 or 1 - 2^-10 * x -- Exponent Out Curve
                pos.y = parent_pos.y + (self.popup_height * i)
                self.object:move_to(pos, true)
            end
            if self.animation_timer > 2 then

                if not self.parent_die then
                    self.animation_timer = 0 -- Reset for use in shrink animation
                    self.alive = false--Start shrink animation
                    return
                end

                if self.parent_die and not self.object:get_attach() then
                    self.object:set_attach(self.parent_die.object, "", {x=0,y=self.popup_height*10,z=0}, {x=0,y=0,z=0})
                end

            end
        else
            self.animation_timer = self.animation_timer + dtime
            self.object:set_properties({visual_size = {x=self.size*(1-self.animation_timer), y=self.size*(1-self.animation_timer)}})
            if self.animation_timer > 1 then
                self.object:remove()
            end
        end
    end
})