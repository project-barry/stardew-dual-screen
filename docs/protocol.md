# The mod's socket, as this app uses it

These notes describe the socket that the Stardew Valley Dual Screen Mod (by Profmags, from
[AYN Thor DualScreen Mods](https://github.com/JoeCorrell/AYN-Thor-Dualscreen-Mods)) serves. They
were worked out from the mod's published 0.3 source and its 2.0 release, so that this app can work
with it. They are not the mod authors' documentation; if they disagree with the mod, the mod wins.

## The connection

- A WebSocket at `ws://127.0.0.1:7786`, on loopback only by default. With `"AllowRemote": true`
  in the mod's `config.json`, it listens on every address. It then also announces itself on UDP
  port 7787 as `{"type": "wemu_beacon", "game": "stardew", "port": 7786, "save": FARM}`.
- One JSON object per text frame, each with a `"type"`.
- When it connects, the newest message of each kind comes first. When a screen attaches and the mod
  takes the HUD off the top screen (`hideGameHud`), the mod sends everything again, including the
  pictures. Otherwise `{"type": "refresh"}` asks for everything, but pictures already sent are not
  sent again.
- Nothing is sent from the title screen. Going back to it sends `game_info` with an empty
  `saveName`.
- Flags are sent as the strings `"1"` and `"0"`.

## From the game

| type | fields |
| --- | --- |
| `game_info` | `gameId` ("stardew"), `saveName` (the farm's name, "" at the title screen) |
| `sdv_config` | the mod's options as flags: `hideGameHud`, `allowInventoryEdits`, `allowQuestCancel`, `farmerMarker`, `sendCrops`, `sendMachines`, `sendAnimals`, `sendBundles`, `sendVillagers`, `sendMap`, `sendCrafting` |
| `sdv_day` | `season`, `day`, `year`, `weekday`, `timeOfDay` (610 = 6:10 am), `weatherToday`, `weatherTomorrow`, `gold`, `energy`, `maxEnergy`, `health`, `maxHealth`, `location`, `luck` (daily luck × 1000), `mapX`, `mapY` (thousandths of the map picture; -1 when off the map). 2.0 adds `playerName`, `farmName`, `playerLevel`, `totalEarnings` |
| `sdv_inventory` | `selected`, `capacity`, `items`: `slot`, `id` ("" when empty), `name`, `count`, `quality` (0, 1 silver, 2 gold, 4 iridium), `water`/`waterMax`/`bottomless` (watering cans), `cooldownMs`/`cooldownMax` (weapons), `category` |
| `sdv_skills` | `farming`, `mining`, `foraging`, `fishing`, `combat`, and each `…Next` (xp to the next level) |
| `sdv_quests` | `quests`: `index`, `title`, `detail`, `objective`, `daysLeft` (-1: none), `reward`, `daily`, `cancellable`, `complete` |
| `sdv_orders` | `orders`: `title`, `objective`, `daysLeft` |
| `sdv_villagers` | `villagers`: `name`, `npc` (internal name, for `npc:` pictures), `hearts`, `maxHearts`, `birthdaySeason`, `birthdayDay`, `birthdayIn` (days), `giftsThisWeek`, `talkedToday`. 2.0 adds `location`, `mapX`, `mapY` |
| `sdv_gifts` | `villagers`: `name`, `carrying`, `loves`: `id`, `name`, `carried` |
| `sdv_crops` | `crops`: `name`, `location`, `daysLeft`, `needsWater`, `ready`; 2.0 adds `id` |
| `sdv_trees` | `trees`: `id`, `location`, `count`; 2.0 adds `name` |
| `sdv_machines` | `machines`: `id`, `name`, `outputId`, `output`, `count`, `location`, `minutes`, `ready` |
| `sdv_animals` | `animals`: `name`, `type`, `hearts` (0 to 5), `petted`, `baby`, `produceId`, `produce`; 2.0 adds `spriteId` |
| `sdv_pet` | `name`, `petted`, `bowl` |
| `sdv_bundles` | `bundles` (unfinished only): `room`, `name`, `have`, `required`, `missing`: `id` ("" for gold), `name`, `count`, `quality`, `carried` |
| `sdv_collections` | `donated`, `total`, `carried` (bag items the museum would take): `id`, `name` |
| `sdv_crafting` | `recipes`. 0.3 lists only what can be crafted now, as `id`, `name`. 2.0 lists every known recipe: `id`, `name`, `key`, `description`, `ready`, `crafted`, `outputCount`, `ingredients`: `id`, `name`, `have`, `required` |
| `sdv_cooking` | `recipes` that can be cooked now: `id`, `name` |
| `sdv_calendar` | `season`, `today`, `days` (only days with something on): `day`, `festival`, `festivalWhen`, `festivalWhere`, `names` (birthdays), `npc` |
| `sdv_shipping` | `total`, `items`: `id`, `name`, `count`, `worth` |
| `sdv_mines` | `deepest` (up to 120), `skull` (Skull Cavern floors) |
| `sdv_cart` | `open` |
| `sdv_grounds` | `grounds`: `id` of backdrop tiles offered |
| `sdv_sprite` | `id`, `png` (base64), `inset` (and `insetX`, `insetY`: a nine-patch border, in picture pixels) |

### Picture ids

- An item's qualified id, such as `(O)24`.
- `npc:NAME`, a villager's portrait (64 × 64). It is sent for villagers with a birthday this
  season or within the week.
- `animal:…` (2.0), farm animals.
- `ui:` pieces of the game's menus: `panel` (nine-patch, `inset` 20), `slot`, `slot_selected`,
  `heart`, `heart_empty`, `coin`, `arrow_left`, `arrow_right`, `scroll`, `check_off`, `check_on`,
  `button`, `water_gauge`, `ground` (a season's grass), `ground:SHEET:X:Y` (backdrop choices),
  `map` (the valley, 300 × 180), and `player` (your farmer's face).
- 2.0 adds `sort`, `season`, `time` (the weather icon), `tab_backpack`, `tab_skills`,
  `tab_relationships`, `tab_map`, `tab_crafting`, `tab_journal`, `tab_settings`, `farmer`, `pet`.

## To the game

Each command is done on the game's next frame, then the mod sends what changed. Each command
can be turned off by the mod's options.

| type | fields | |
| --- | --- | --- |
| `select_slot` | `slot` (0 to 11) | hold a hotbar slot |
| `move_item` | `from`, `to` | swap two bag slots |
| `eat_slot` | `slot` | eat or drink it, if it's edible |
| `sort_bag` | | |
| `shift_toolbar` | `value` (1 forward, 0 back) | rotate the rows through the hotbar |
| `cancel_quest` | `value` (the quest's `index`) | only if the game allows cancelling it |
| `craft_recipe` | `key` (the recipe's `key`) | 2.0 only |
| `set_option` | `key` (an `sdv_config` name), `value` (1 or 0) | saved in the mod's `config.json` |
| `refresh` | | send everything again |
