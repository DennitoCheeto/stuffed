class_name ZombieBowling
extends Resource
## Bowling Buttons' zombie bowling (spec 11 §4.2): a zombie knocked back by a button tumbles for a
## moment and knocks over the zombies it bumps into (one step only: bumped zombies don't tumble).
## Bosses never tumble. Tune it in data/weapons/bowling_buttons.tres.

## How long a hit zombie tumbles, in seconds; elites tumble `elite_share` of that.
@export var tumble_seconds: float = 0.4
@export var elite_share: float = 0.5
## What a tumbling zombie does to each zombie it bumps into (once per tumble).
@export var bump_damage: float = 10.0
@export var bump_push: float = 260.0
## A zombie this many pixels beyond the tumbler's body counts as bumped.
@export var bump_reach: float = 6.0
## Knocking over this many in one tumble plays the strike sound.
@export var strike_count: int = 3
## Strike sound (a name in SfxBank).
@export var strike_sound: StringName = &"strike"
## The calm motion streak behind a tumbling zombie (it keeps its normal zombie look).
@export var streak_length: float = 40.0
@export var streak_width: float = 7.0
@export var streak_color: Color = Color(0.97, 0.95, 0.9, 0.45)
