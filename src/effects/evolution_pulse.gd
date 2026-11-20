class_name EvolutionPulse
extends Node2D
## The ring that pulses out from a hero right after their weapon evolved (spec 10 §3): a thin
## gold ring that grows and fades. Drawn with the hero's own shots, so zombies stay the loudest
## thing on screen (rule 9).

const START_ALPHA: float = 0.8
const FILL_ALPHA: float = 0.1

var rules: EvolutionMomentRules
var time: float = 0.0


func _init(moment_rules: EvolutionMomentRules) -> void:
	rules = moment_rules
	z_as_relative = false
	z_index = WorldLayers.OWN_SHOTS


func _process(delta: float) -> void:
	time += delta
	if time >= rules.pulse_seconds:
		queue_free()
		return
	queue_redraw()


## 0 when it starts, 1 when the ring has reached its radius.
func progress() -> float:
	return clampf(time / maxf(rules.pulse_seconds, 0.001), 0.0, 1.0)


func ring_color() -> Color:
	return Color(rules.pulse_color, START_ALPHA * (1.0 - progress()))


func _draw() -> void:
	var grown: float = rules.pulse_radius * (1.0 - pow(1.0 - progress(), 3.0))
	var ring: Color = ring_color()
	draw_circle(Vector2.ZERO, grown, Color(rules.pulse_color, FILL_ALPHA * ring.a / START_ALPHA))
	draw_arc(Vector2.ZERO, grown, 0.0, TAU, 48, ring, rules.pulse_width, true)
