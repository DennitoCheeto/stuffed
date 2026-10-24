class_name RunJars
extends HBoxContainer
## The run's haul on the HUD (spec 03 §3): three small jars under the loadout, quieter than the
## health bar. Normal kills just tick the counters; elites, bosses and gift boxes send a burst
## of pieces flying into the jars, which bump when a piece lands.

const FONT_SIZE: int = 20
const ICON_SIDE: float = 26.0
## A little see-through, so the jars never compete with health or enemy danger.
const JAR_ALPHA: float = 0.85
## How much a jar grows when a piece lands, and how fast it settles back.
const BUMP_SCALE: float = 0.25
const BUMP_DECAY: float = 4.0
## Each jar tinks at its own pitch when a burst piece lands in it (quieter than XP, spec 03 §11).
const JAR_PITCH: Dictionary[String, float] = {"coins": 1.0, "stuffing": 0.8, "thread": 1.2}

## Material id -> its counter.
var counters: Dictionary[String, JarCounter] = {}
## Bursts still flying (freed when landed).
var bursts: Array[MaterialBurst] = []
var _bumps: Dictionary[String, float] = {}


func _init() -> void:
	name = "RunJars"
	modulate.a = JAR_ALPHA
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override(&"separation", 18)
	for material: String in JarIcon.MATERIALS:
		var counter: JarCounter = JarCounter.new(material, FONT_SIZE, ICON_SIDE)
		counters[material] = counter
		_bumps[material] = 0.0
		add_child(counter)


## Shows the run's haul so far.
func show_haul(haul: RunHaul) -> void:
	for material: String in counters:
		counters[material].show_amount(haul.amount(material))


func shown(material: String) -> int:
	return counters[material].shown


## Screen position of `material`'s jar icon (where burst pieces fly to).
func jar_position(material: String) -> Vector2:
	var icon: JarIcon = counters[material].icon
	return icon.get_global_rect().get_center()


## Sends pieces for `amounts` flying from screen position `from` into the jars.
func burst(amounts: Dictionary[String, int], from: Vector2) -> MaterialBurst:
	var targets: Dictionary[String, Vector2] = {}
	for material: String in counters:
		targets[material] = jar_position(material)
	var flying: MaterialBurst = MaterialBurst.new()
	flying.setup(amounts, from, targets)
	flying.piece_landed.connect(_bump)
	flying.tree_exited.connect(bursts.erase.bind(flying))
	bursts.append(flying)
	get_parent().add_child(flying)
	return flying


func _bump(material: String) -> void:
	_bumps[material] = 1.0
	Sfx.play(&"coin", JAR_PITCH.get(material, 1.0))


func _process(delta: float) -> void:
	for material: String in counters:
		var bump: float = maxf(_bumps[material] - delta * BUMP_DECAY, 0.0)
		_bumps[material] = bump
		var icon: JarIcon = counters[material].icon
		icon.pivot_offset = icon.size / 2.0
		icon.scale = Vector2.ONE * (1.0 + BUMP_SCALE * bump)
