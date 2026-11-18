class_name WardrobeRules
extends Resource
## The Wardrobe next to the fort door where you pick your hero (spec 08 §2, §5): its texts,
## sounds and size. Tune it in data/town/wardrobe_rules.tres, not in code. Where it stands is
## `TownLayout.wardrobe_rect`.

const PATH: String = "res://data/town/wardrobe_rules.tres"

## Saved in TownSave.revealed once the Wardrobe appeared, and "hero:<id>" once a hero's
## "wants to play!" banner was shown (no new save fields needed).
const REVEALED_ID: String = "wardrobe"
const HERO_PREFIX: String = "hero:"

static var _current: WardrobeRules

## Banner when a hero is unlocked: "Pip wants to play!" (subtitle: HeroStats.try_on_text the
## first time the Wardrobe appears, else `later_subtitle`).
@export var unlock_title: String = "%s wants to play!"
## The same for several heroes at once: "Pip and Böbö want to play!".
@export var unlock_title_many: String = "%s want to play!"
@export var later_subtitle: String = "Pick them at the Wardrobe."
## The sign under the Wardrobe and the prompt next to it.
@export var sign_text: String = "Wardrobe"
@export var prompt: String = "E   Open the Wardrobe"
## The hero picker.
@export var picker_title: String = "Who plays?"
@export var picker_hint: String = "Your hero for the next run and siege.   Esc: close"
@export var locked_text: String = "Rescue me in the Bedroom"
## "Player 1 plays Pip" on a hero another player has (co-op, spec 08 §8).
@export var taken_text: String = "Player %d plays %s"
@export var now_text: String = "Now"
## The swap: a puff of stuffing and a pop.
@export var swap_sound: StringName = &"pop"
@export var swap_pitch: float = 1.2
@export var reveal_sound: StringName = &"new_building"
## The look's size (1 = the art kit's design units).
@export var art_scale: float = 1.0


## The game's rules, loaded at first use (hero files load in a circle with some scripts).
static func current() -> WardrobeRules:
	if _current == null:
		_current = load(PATH) as WardrobeRules
	return _current
