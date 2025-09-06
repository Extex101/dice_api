dice = {
    players = {},
    registered_skins = {},
    path = core.get_modpath("dice_api"),
    sounds = {
        die = {
            shake = "dice_api_shake",
            throw = "dice_api_throw",
            fly = "dice_api_fly",
            first_impact  = "dice_api_roll",
            hit   = "dice_api_hit",
            land  = "dice_api_land",
            returning = "dice_api_fly",
        },
        coin = {
            throw = "dice_api_coin_throw",
            fly = "dice_api_coin_fly",
            hit   = "dice_api_coin_hit",
            land  = "dice_api_coin_land",
            returning = "dice_api_coin_fly",
            collect = "dice_api_coin_collect",
        }
    }
}
dofile(dice.path.."/skin.lua")
dofile(dice.path.."/api.lua")
dofile(dice.path.."/dice.lua")