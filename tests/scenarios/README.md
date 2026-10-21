# Scenario tests

Scenario tests check **acceptance criteria from the specs** the way a player experiences them:
they load the **real scenes**, simulate keyboard/mouse input and let game time pass, then look at
what happened on screen and in the game state.

They are the automated part of the milestone acceptance: the product owner only has to judge
what tests can't, which is whether it's fun.

## Writing a scenario

```gdscript
extends GutTest
## Scenario: <what the player does>

const MAIN_SCENE: PackedScene = preload("res://src/main/main.tscn")

func test_<expected_outcome>() -> void:
	var main: Node = add_child_autofree(MAIN_SCENE.instantiate())
	var sender := GutInputSender.new(Input)
	sender.action_down("move_right").hold_for(0.5)
	await wait_for_signal(sender.idle, 2)
	# assert on nodes / state
```

- One file per spec: `test_NN_<feature>.gd`; test names quote the acceptance criterion.
- Use `wait_physics_frames()` / `wait_seconds()` to let the game run; keep scenarios fast (seconds, not minutes).
- Randomness must be seedable so scenarios are deterministic.
- Run only scenarios: `tools/test.sh -gdir=res://tests/scenarios`.

## Limits

Scenarios run headless: they can't judge look, feel, readability or frame rate on a real PC.
Those remain part of the product owner's playtest.
