extends GutTest
## Shared setup for scenarios that play a run: boots the real game from the title screen.
## Scenario files extend this script by path.

const MAIN_SCENE: PackedScene = preload("res://src/main/main.tscn")
## Physics frames per second (project default).
const FPS: float = 60.0
const TEST_LOG: String = "user://test_run_log.jsonl"
const TEST_SAVE: String = "user://test_save.json"
const TEST_SETTINGS: String = "user://test_settings.json"

var main: Main
var sender: GutInputSender
## Input actions a test added for another player (removed after each test).
var _added_actions: Array[StringName] = []


func before_each() -> void:
	# Never touch the player's real run log or save.
	RunLog.path = TEST_LOG
	DirAccess.remove_absolute(TEST_LOG)
	SaveStore.path = TEST_SAVE
	SaveStore.delete_all()
	GameSettings.path = TEST_SETTINGS
	DirAccess.remove_absolute(TEST_SETTINGS)
	main = MAIN_SCENE.instantiate()
	main.quit_enabled = false
	add_child_autofree(main)
	sender = GutInputSender.new(Input)
	await wait_physics_frames(1)


func after_each() -> void:
	sender.release_all()
	sender.clear()
	for action: StringName in _added_actions:
		InputMap.erase_action(action)
	_added_actions.clear()


## Goes to the town the way the player does (New game / Continue on the title screen, or Back to
## the fort on the end screen) and returns it.
func go_to_town() -> Town:
	var title: TitleScreen = main.current_screen as TitleScreen
	var end: EndScreen = main.current_screen as EndScreen
	if title != null:
		title.start_button.pressed.emit()
	elif end != null:
		end.fort_button.pressed.emit()
	await wait_physics_frames(2)
	return main.current_screen as Town


## Starts a run the way the player does (title -> town -> E at the Bedroom door) and returns it.
func start_run() -> Run:
	var town: Town = main.current_screen as Town
	if town == null:
		town = await go_to_town()
	town.enter_bedroom()
	await wait_physics_frames(2)
	return main.current_screen as Run


## Every weapon on the level-up cards (Toy Box Armory at level 2), for scenarios about a weapon
## the Armory unlocks. Call it before start_run().
func unlock_all_weapons() -> void:
	main.town.building_levels["toy_box_armory"] = 2


## Gives player `index` (1 = player 2) controls for this test: "p2_move_left", "p2_interact", ...
## There are no keys for them yet (co-op joining comes later), tests press them directly.
func add_controls(index: int) -> void:
	for control: String in [
		"move_left", "move_right", "move_up", "move_down", "dash", "interact", "tricks"
	]:
		var action: StringName = StringName("p%d_%s" % [index + 1, control])
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
			_added_actions.append(action)


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
