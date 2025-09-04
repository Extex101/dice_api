# DICE_API

![DICE_API Promotional GIF](https://github.com/Extex101/link-images/blob/main/dice_api_hey_bub_ya_wanna_die_ya_got_the_cash.gif?raw=true)

Have you ever wanted to flip a coin, make a board game, or run a TTRPG in Luanti? Well now you can!
This mod makes all of that possible with fun and easy-to-use API.


![DICE_API Title banner](https://github.com/Extex101/link-images/blob/main/dice_api_title_banner.png?raw=true)
```lua
dice.register_die("my_dice_pack:d6", {
    preset = "d6",
    tooltip = {
        "\\CYAN\\My D6!",
        "",
        "\\GREEN\\Six-Sided",
        "\\GREEN\\    -    My Dice Pack",
        "\\GREEN\\    -    Made with Dice API",
        "\\PINK\\Forged in the fires of mount Gloom."
    },
    textures = {"my_dice_pack_d6.png"},
    -- Pre-packaged sound pack
    sounds = dice.sounds.die,
    groups = {
        my_dice_pack = 6,
    }
})

```

![DICE_API Example Die](https://github.com/Extex101/link-images/blob/main/dice_api_example_die_tooltip.png?raw=true)


### Die Types
Currently supports: Coins, D6, D12, D20

![DICE_API Presets](https://github.com/Extex101/link-images/blob/main/dice_api_die_types.png?raw=true)

### Personalize your die with:
`/rename_die <name>`

#### Command Example:
![DICE_API Renaming Die](https://github.com/Extex101/link-images/blob/main/dice_api_rename_die_example.png?raw=true)

#### Updated tooltip:
![DICE_API Renamed Die Tooltip](https://github.com/Extex101/link-images/blob/main/dice_api_renamed_die_example.png?raw=true)

#### Roll-result chat message:
![DICE_API Renamed chat message](https://github.com/Extex101/link-images/blob/main/dice_api_rolled_die_result_renamed.png?raw=true)

### Disclaimer:
> > This mod is not intended to be used in the gambling of real-world currency, crate-keys or any other pay-to-obtain in-game currency.
