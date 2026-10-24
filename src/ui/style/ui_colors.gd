class_name UiColors
extends RefCounted
## The Stitched Scrapbook colours (spec 04 §2.1): one colour per thing, everywhere.
## Danger red/orange is never used here: it belongs to enemies only (vision §6).

## Panel felt and its stitches.
const FELT: Color = Color("#f6ecd9")
const STITCH: Color = Color("#c9b48e")
## A lighter felt for boxes inside a panel.
const FELT_LIGHT: Color = Color("#fff7e6")
## The dusty purple cloth behind menus.
const CLOTH: Color = Color("#6a5a8e")
## The one "go on" button per screen.
const GOLD: Color = Color("#f2b52e")
const GOLD_EDGE: Color = Color("#a87a14")
const GOLD_STITCH: Color = Color("#fff4d6")
const GOLD_INK: Color = Color("#4a3210")
## Secondary buttons: cream felt.
const CREAM_EDGE: Color = Color("#9d8a68")
## Text on felt (both reach 4.5:1 on FELT).
const INK: Color = Color("#3b2f4a")
const INK_SOFT: Color = Color("#6a5a4a")
## Hand-written headings.
const PURPLE: Color = Color("#5b3590")
const TEAL: Color = Color("#2f7d82")
## Photos and their shadow.
const PHOTO: Color = Color("#ffffff")
const SHADOW: Color = Color(0.24, 0.16, 0.08, 0.25)
## Washi tape (see-through).
const TAPE_GOLD: Color = Color(0.95, 0.71, 0.18, 0.7)
const TAPE_TEAL: Color = Color(0.56, 0.78, 0.79, 0.75)
const TAPE_PINK: Color = Color(0.91, 0.63, 0.71, 0.7)
## Stickers.
const STICKER_PINK: Color = Color("#e7a0b4")
const STICKER_PINK_INK: Color = Color("#3b1f2a")
const STICKER_TEAL: Color = Color("#8fc6c9")
const STICKER_TEAL_INK: Color = Color("#173f42")
## Materials (the jar colours) and XP.
const COINS: Color = Color("#e3bd55")
const STUFFING: Color = Color("#f1eee8")
const THREAD: Color = Color("#6fb3b8")
const XP: Color = Color("#7cc96b")
## Fabric tags.
const TAG: Color = Color("#eadfca")
const TAG_STITCH: Color = Color("#b8a27a")
## HUD (spec 04 §2.3): quiet dark felt backings with a soft stitch, light text.
const HUD_FELT: Color = Color(0.17, 0.14, 0.24, 0.82)
const HUD_STITCH: Color = Color(0.66, 0.6, 0.8, 0.55)
const HUD_TEXT: Color = Color("#f6ecd9")
const HUD_OUTLINE: Color = Color("#1c1826")
## The hero's health: a soft rose (never the red of danger; green is XP).
const HEALTH: Color = Color("#e891aa")

## Danger colours (vision §6): saturated red to orange. Enemies own them; menus and the HUD's own
## parts never use them.
const DANGER_HUE_LOW: float = 35.0 / 360.0
const DANGER_HUE_HIGH: float = 335.0 / 360.0
const DANGER_SATURATION: float = 0.45
const DANGER_VALUE: float = 0.35


## True for a colour that reads as enemy danger (red / orange, saturated and bright enough).
static func is_danger(color: Color) -> bool:
	if color.a <= 0.0 or color.s < DANGER_SATURATION or color.v < DANGER_VALUE:
		return false
	return color.h < DANGER_HUE_LOW or color.h > DANGER_HUE_HIGH
