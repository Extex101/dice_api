Functions
=========

* `dice.register_die(name, die parameters)`

* `dice.throw_die(player, itemstack)`: returns itemstack
    * Throws Die based on the given itemstack.
    * `player`: is an ObjectRef

* `dice.play_sound(object, skin, name, loop, fade)`: returns a handle or nil
    * Play the chosen sound from the current skin.
    * `object`: is an ObjectRef for the sound to attach to.
    * `skin`: is a skin metatable. `dice.registered_skins["example:skin_name"]`
    * `name`: is a string. The name of the sound to play. `"shake"`|`"throw"`|`"fly"`|`"first_impact"`|`"hit"`|`"land"`
    * `loop`: if true, sound will loop and function returns a sound handle
    * `fade`: if true, sound will fade in.

* `dice.generate_number_texture(number, font, max, tint)`
    * Generates a texture from the given number.
    * `number`: is an integer, the number to generate the texture for
    * `font`: (optional) table as defined in die parameters
    * `max`: (optional) is an integer, the max number that the die can roll to. Used to determine the font tint.
    * `tint`: (optional) table as defined in die parameters

* `dice.generate_description(tooltip, tooltip_colors, background_color)`
    * Colorizes a tooltip based on the tooltip table
    * `tooltip`: is a table containing the tooltip text. Each item in the table is a line.
    *    * `"\\COLOR NAME\\ Text to be colored \\COLOR NAME 2\\ Text to be colored"`
    * `tooltip_colors`: is a table containing color definitions.
    *    * name = `"#RRGGBB"` -- Single color
    *    * name = {`"#RRGGBB"`, `"#RRGGBB"`} -- Gradient
    * `background_color`: is a string in the format "#RRGGBBAA"
    * Returns a description string


Definition tables
=================

Die Definition
--------------

Used by `dice.register_die`.

```lua
{
    tooltip_colors = {
        cream = "#ddbc9c",
        gradient = {"#ffffff", "#000000"} -- Gradient
    },
    -- Colors for the tooltip
    -- Key will be scanned for in the tooltip to set the color of the following text
    -- Gradients are a table of two colors.
    -- There is a set of default colors, but more can be defined here.
    -- RED, ORANGE, YELLOW, GREEN, CYAN, BLUE, PURPLE, PINK, WHITE, SILVER, GREY, BLACK, and you can't forget SLUDGE

    tooltip = {
        "\\gradient\\Everything's going dark, I'm not long for this world.\\WHITE\\ He dead. \\RED\\RIP",
        "Make it \\BLUE\\Blue! \\WHITE\\Make it \\PINK\\Pink! But what if...\\cream\\ Cream?",
    },
    -- Tooltip/Description of the die.
    -- (If a string is given, it will be used as the description)
    -- Suggested formatting:
    --     Name
    --
    --     X-Sided
    --        -    Pack Name
    --        -    Type/Additional Info
    --        -    Lore Text
    -- Though any formatting can be used
    -- First item will be changed with "/rename_die <name>" unless disable_rename is true.
    -- Colors can be applied with "\\COLOR NAME\\ Text to be colored"
    -- Gradients are applied the same, ending either at the end of the string or until the next color tag

    tooltip_background_color = "#000000aa",
    -- Background color for the entire tooltip.
    
    disable_rename = false,
    -- If true, "/rename_die" will not work on this die
    -- You're a monster.

    preset = "coin" / "d6" / "d12" / "d20",
    -- Any properties defined in the die definition will override the preset values
    -- "coin" has two possible outcomes, "heads" or "tails"
    -- "d6" is the classic 6-sided die found in most board games.
    -- "d12" is a 12-sided die found in some TTRPGs.
    -- "d20" is a 20-sided die found in the majority of TTRPGs
    -- If not defined, no preset will be used.
    
    face_count = 1,
    -- Number of faces on the die.
    -- If left blank it will default to the preset value.
    -- 2 on coin, 6 on d6, 12 on d12, 20 on d20

    textures = {texture definition 1, def2, def3, def4, def5, def6},
    -- Requires one texture for each mesh buffer/material (in order)
    -- See [Texture definition]
    
    mesh = "",
    -- File name of mesh

    roll_animation = {x = 0, y = 0},
    -- Animation to play when rolling
    -- `x`: = start frame
    -- `y`: = end frame

    animation_speed = 1,
    -- Animation speed multiplier. Default: 1

    die_size = 0,
    -- Size of the die. 
    -- Equivalent to visual_size = {x = die_size, y = die_size} in entity definition

    inventory_scale = 1,
    -- Scale of the die in the inventory. Default: 1
    -- Equivalent to visual_scale in node definition
    -- Adjust scale so die is clearly visible in the inventory
    -- Doesn't work prior to 5.13 due to node scaling bug with b3d models

    sounds = {
        shake = "",
        throw = "",
        fly = "",
        first_impact = "",
        hit = "",
        land = "",
        returning = "",
        collect = ""
    },
    -- Sounds to be used on the specified events.
    -- `fly` and `returning` are treated the same, with the volume fading based on the velocity.
    -- If sound is not defined, no sound will be played for that event.
    -- `shake` when shaking, 
    -- `throw` when thrown, 
    -- `fly` when moving through the air, 
    -- `first_impact` when the die makes first contact, 
    -- `hit` when making a collision, 
    -- `land` when stopped and showing the result, 
    -- `returning` when moving through the air during the return stage, 
    -- `collect` when the die is collected

    fade_fly_sounds = false,
    -- If true, will fade the fly and returning sounds volume based on the velocity.
    
    collisionbox = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
    -- { xmin, ymin, zmin, xmax, ymax, zmax } in nodes from object position.

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
    -- Physics properties for the die
    -- Default values are shown above
    -- `gravity`: vertical acceleration
    -- `drag`: drag coefficient
    --      `air`: drag when in the air
    --      `ground`: drag when on the ground
    --      `other`: drag when colliding with walls, ceilings, or objects
    -- `bounce_loss`: loss of velocity per bounce
    -- If a value is 0.4, it will bounce back with 40% of the initial velocity
    -- It will save the other 60% of the remaining velocity, 
    -- and redirect a percentage of the remaining velocity (defined in the `_leftover` field) to the other two axis
    --      `wall`: loss of velocity when hitting a wall
    --      `wall_leftover`: percentage of the remaining velocity to be redirected
    --      `ground`: loss of velocity when hitting the ground
    --      `ground_leftover`: percentage of the remaining velocity to be redirected

    min_shake_time = 0,
    -- Minimum shake duration before dice can be thrown.
    -- Set to 0 for immediate throwing.
    
    throw_kick = 0,
    -- Additional vertical velocity when throwing.

    face_dir = false,
    -- If true, will rotate to face the movement direction

    lock_face_dir_pitch = false,
    -- If true, die will not pitch down when face_dir is true

    land_immediate = false,
    -- If true, die will stop immediately after the first ground impact.

    stopping_velocity = 0,
    -- If the die is on the ground and moving slower than this, it will stop. Default: 1

    rest_time = 0,
    -- Time in seconds to rest between landing and returning

    font = {
        texture = "font.png",
        size = 10,
    },
    -- Font to be used in the popup
    -- `texture`: is a vertical spritesheet, 0 on top down to 9 (tiles must be square)
    -- `size`: the resolution of each tile. e.g. Each tile is 10x10, set `size` to 10

    popup_tint = {
        "#000000",
        "#ffffff",
    },
    -- List of hex codes to tint the popup
    -- Maps the roll result to the tint by percentage

    face_names = {},
    -- List of names to print instead of the numbers 1 through `face_count`

    disable_popup = false,
    -- If true, the popup to display the roll result will not be shown.

    disable_message = false,
    -- If true, no "Your <die name> rolled a : <result>!" will be printed to the player's chat.

    face_popup_textures = {},
    -- List of textures to display instead of the numbers 1 through `face_count`

    popup_size = 0,
    -- visual_size of the popup entity.

    popup_height = 0,
    -- Height that the popup rises to on landing. Defualt: 1.5

    -- self.skin:get(property) can be used to retrieve any of the properties above

    on_shake = function(player, shake_duration),
    -- Called while skaing the die.
    -- `player`: is an ObjectRef, for the player holding the die
    -- `shake_duration`: is a float, the time in seconds that the die has been shaken for

    on_throw = function(self, player, shake_time),
    -- Called once when dice is thrown.
    -- `self`: luaentity of the die
    -- `player`: same as `core.get_player_by_name(self.owner)`
    -- `shake_time`: is a float, the time in seconds that the die was shaken prior to the throw

    animate = function(self, speed),
    -- Called during airtime, flying and returning.
    -- `speed`: is a number equal to the length of current velocity

    on_step = function(self, player, dtime, moveresult),
    -- Called while the die is flying.
    -- `self`: luaentity of the die
    -- `player`: same as `core.get_player_by_name(self.owner)`
    -- `dtime`: elapsed time since last call
    -- `moveresult`: see lua_api.md. Does not work when self.mode is "returning
    
    on_hit = function(self, player, collision, hit_count),
    -- Called when dice makes a collision.
    -- `self`: luaentity of the die
    -- `player`: same as `core.get_player_by_name(self.owner)`
    -- `collision`: the moveresult.collisions[i] for this hit
    -- `hit_count`: is a number, how many times the die has made a collision

    on_land = function(self, player, result),
    -- Called once the die stops moving and the roll is decided.
    -- `self`: luaentity of the die
    -- `player`: same as `core.get_player_by_name(self.owner)`
    -- `result`: The result of the roll. Will return the face_name string if avaliable, otherwise it returns the number.

    on_return = function(self, player),
    -- Called while the dice is returning to the player.
    -- `self`: luaentity of the die
    -- `player`: same as `core.get_player_by_name(self.owner)`

    on_death = function(owner, pos, itemstack, reason),
    -- Called when the die dies.
    -- `player`: the owner of the die
    -- `pos`: last position of the die
    -- `itemstack`: the itemstack of the die
    -- `reason`: the cause of death. "collect" / "drop" / "removed"

}
```

Texture Definition
------------------


```lua
{
   "texure.png",-- Static texture
   {
        -- Animated texture
        -- Only works on vertical spritesheets
        texture = "texture_animated.png", -- Animated texture
        frame_count = 0,-- Number of frames in the animation
        duration = 0.0,-- Total duration of the animation in seconds, frame lengths will be duration / frame_count.
    }
}
```