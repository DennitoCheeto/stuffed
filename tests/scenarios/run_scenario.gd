extends GutTest
## Shared setup for scenarios that play a run: boots the real game from the title screen.
## Scenario files extend this script by path.

const MAIN_SCENE: PackedScene = preload("res://src/main/main.tscn")
## Physics frames per second (project default).
const FPS: float = 60.0
const TEST_LOG: String = "user://test_run_log.jsonl"

var main: Main
var sender: GutInputSender


func before_each() -> void:
	# Never touch the player's real run log.
	RunLog.path = TEST_LOG
	DirAccess.remove_absolute(TEST_LOG)
	main = MAIN_SCENE.instantiate()
	main.quit_enabled = false
	add_child_autofree(main)
	sender = GutInputSender.new(Input)
	await wait_physics_frames(1)


func after_each() -> void:
	sender.release_all()
	sender.clear()


## Starts a run the way the player does (Start run on the title screen) and returns it.
func start_run() -> Run:
	var title: TitleScreen = main.current_screen as TitleScreen
	title.start_button.pressed.emit()
	await wait_physics_frames(2)
	return main.current_screen as Run


func first_player() -> Player:
	return Players.all(get_tree())[0]


## Takes all weapons away (for scenarios that need zombies to stay alive).
func disarm(player: Player) -> void:
	for weapon: Weapon in player.weapons():
		weapon.get_parent().remove_child(weapon)
		weapon.free()


## Holds an action for `frames` physics frames, then releases it.
func hold_action(action: String, frames: int) -> void:
	sender.action_down(action)
	await wait_physics_frames(frames)
	sender.action_up(action)


## A short tap of an action (like pressing Space once).
func tap_action(action: String) -> void:
	await hold_action(action, 2)


## Reaches the goal as a real run does since spec 02: at the goal time the Sock Puppet King
## comes, and here he is beaten at once. The goal (pops, celebration) starts right away.
func beat_the_boss(current: Run) -> void:
	current.elapsed = maxf(current.elapsed, current.rules.goal_seconds)
	var king: Zombie = current.spawner.spawn_boss(current.spawner.schedule.boss)
	current.enemies.damage(king, king.max_health * 10.0)


## Waits until the goal screen takes keys (skipping the boss's gift box moment on the way).
func wait_for_goal_screen(current: Run) -> void:
	for i: int in roundi(10.0 * FPS):
		if current.goal_screen.is_open():
			break
		if current.gift_screen.is_open():
			current.gift_screen.close()
		await wait_physics_frames(1)
	await wait_seconds(GoalScreen.INPUT_DELAY + 0.1)
