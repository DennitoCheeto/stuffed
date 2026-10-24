class_name UiStyle
extends Resource
## The numbers behind the menu juice (spec 04 §3), in data/ui/ui_style.tres (hard rule 8).
## Every single motion stays short (spec: at most 0.4 s per element, closing at most 0.2 s).

@export_group("Buttons")
## Hover / focus: how far a button lifts (px) and grows.
@export var hover_lift: float = 8.0
@export var hover_grow: float = 1.05
## Press: how much it squishes.
@export var press_squish: float = 0.92
## Length of the spring to a new button pose.
@export var spring_seconds: float = 0.22
## Disabled buttons: how see-through they get.
@export var disabled_fade: float = 0.55
## The "nope" wiggle of a pressed disabled button: degrees and length.
@export var nope_spin: float = 5.0
@export var nope_seconds: float = 0.3
## Slider knobs and switches: how much the knob grows on hover / focus, and how long a switch
## knob takes to slide across.
@export var knob_grow: float = 1.2
@export var switch_seconds: float = 0.16

@export_group("Screens")
## Opening: panels drop in from this high (px), with this extra tilt (degrees), one after the
## other with this gap.
@export var open_drop: float = 48.0
@export var open_spin: float = 3.0
@export var open_stagger: float = 0.08
@export var open_seconds: float = 0.35
## Closing: panels slide down this far (px) and fade out.
@export var close_drop: float = 30.0
@export var close_seconds: float = 0.18

@export_group("Stickers")
## A sticker slaps on: starts this much bigger and this much more tilted.
@export var slap_grow: float = 1.6
@export var slap_spin: float = 8.0
@export var slap_seconds: float = 0.3


## The longest single motion (for the "never slow" rule in tests).
func longest_element_seconds() -> float:
	return maxf(maxf(spring_seconds, nope_seconds), maxf(open_seconds, slap_seconds))
