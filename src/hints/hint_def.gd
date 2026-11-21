class_name HintDef
extends Resource
## One first-time hint (spec 10 §6): a taped paper note that explains one thing the first time
## it comes up. Keys are never written out: `{dash}` in the text becomes a fabric tag with the
## bound key (KeyBindings ids; tokens next to each other share one tag, "{move_up}{move_left}..."
## shows "WASD").

## Where the note sits on the screen; it moves to the other edge if a hero stands there.
enum Place { TOP, BOTTOM }

## Remembered in the save (`TownSave.hints_seen`).
@export var id: String = ""
## What the note says, with `{key_id}` tokens for keys.
@export_multiline var text: String = ""
@export var place: Place = Place.BOTTOM
## Distance from its screen edge in px (-1 = HintRules.edge_margin).
@export var margin: float = -1.0
