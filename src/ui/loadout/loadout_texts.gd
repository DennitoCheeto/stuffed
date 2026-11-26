class_name LoadoutTexts
extends Resource
## Every word of the loadout pages (spec 04b): tune them in data/ui/loadout_view.tres, not in code.

## The pause menu's button.
@export var button: String = "Loadout"
@export var title: String = "Your loadout"
## Column heading: player number, hero name.
@export var heading: String = "Player %d · %s"
@export var weapons_heading: String = "Weapons"
@export var items_heading: String = "Items"
@export var gear_heading: String = "Gear"
## Level of a weapon that isn't maxed yet: level, top level.
@export var level: String = "Lv %d / %d"
@export var maxed: String = "MAX"
@export var evolved: String = "Evolved"
## Evolution hint under a weapon: what it becomes, the partner item.
@export var evolve_hint: String = "→ %s with %s"
## Shown instead of the evolved name while that evolution hasn't been seen.
@export var unseen: String = "?"
## The weapon is maxed and its partner owned: the next gift box evolves it.
@export var ready: String = "Ready! Find a gift box"
## A worn gear piece: name, stitch level.
@export var gear_line: String = "%s Lv %d"
@export var no_gear: String = "Nothing worn"

@export_group("Town page")
## The town Esc menu's button.
@export var town_button: String = "My loadout"
@export var town_title: String = "My loadout"
## The prompt at the corkboard by the door.
@export var board_prompt: String = "{interact}   Loadout"
## The word on the corkboard's sign.
@export var board_sign: String = "Loadout"
@export var start_heading: String = "Starting weapon"
## Starting weapon level (Head Start raises it).
@export var start_level: String = "Lv %d"
@export var own_weapon: String = "Hero's own weapon"
@export var armory_weapon: String = "Picked at the Armory"
## A worn piece in town: stitch level.
@export var gear_level: String = "Lv %d"
## An empty gear slot once the Sewing Workshop is revealed.
@export var empty_gear: String = "Nothing yet: sew one at the Sewing Workshop"
@export var bonuses_heading: String = "Town bonuses"
@export var no_tricks: String = "No tricks yet: press {tricks} at a built building"
@export var bedroom_only: String = "Bedroom only"
@export var no_bonuses: String = "No building bonuses yet: rebuild the town"
## Building bonuses in plain words (the totals the run uses).
@export var card_uses_bonus: String = "+%d Reroll, Skip and Banish"
@export var health_bonus: String = "+%d max health"
@export var pickup_range: String = "+%d%% pickup range"
@export var pickup_sooner: String = "Toys come %d%% sooner"
@export var first_pickup: String = "First toy at %s"
