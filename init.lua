dice = {
    players = {},
    registered_skins = {},
    path = core.get_modpath("dice_api"),
    sounds = {
        die = {
            shake = "dice_shake",
            throw = "dice_throw",
            fly = "dice_fly",
            first_impact  = "dice_roll",
            hit   = "dice_hit",
            land  = "dice_land",
            returning = "dice_fly",
        },
        coin = {
            throw = "dice_coin_throw",
            fly = "dice_coin_fly",
            hit   = "dice_coin_hit",
            land  = "dice_coin_land",
            returning = "dice_coin_fly",
            collect = "dice_coin_collect",
        }
    }
}
dofile(dice.path.."/skin.lua")
dofile(dice.path.."/api.lua")
dofile(dice.path.."/dice.lua")