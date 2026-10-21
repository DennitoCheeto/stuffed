class_name RecipeRow
extends HBoxContainer
## One line of the Recipes page: "[weapon] Peel Boomerang + [item] Quick Feet → [evolved] Banana
## Split", or "→ ?" while that evolution hasn't been seen.

const ICON_SIZE: Vector2 = Vector2(48, 48)

var result_label: Label
var result_icon: UpgradeIcon


func show_recipe(evolution: EvolutionDef, pool: UpgradePool, seen: bool) -> void:
	add_theme_constant_override("separation", 10)
	alignment = BoxContainer.ALIGNMENT_CENTER
	var weapon: UpgradeDef = pool.find(evolution.weapon)
	var item: UpgradeDef = pool.find(evolution.partner)
	_icon(weapon.icon)
	_text(weapon.display_name, RecipesPage.TEXT_COLOR)
	_text("+", RecipesPage.DIM_COLOR)
	_icon(item.icon)
	_text(item.display_name, RecipesPage.TEXT_COLOR)
	_text("→", RecipesPage.DIM_COLOR)
	result_icon = _icon(evolution.icon if seen else &"")
	var result: String = evolution.display_name() if seen else RecipesPage.UNSEEN
	result_label = _text(result, RecipesPage.HIGHLIGHT_COLOR)


func _icon(icon_name: StringName) -> UpgradeIcon:
	var icon: UpgradeIcon = UpgradeIcon.new()
	icon.custom_minimum_size = ICON_SIZE
	icon.icon = icon_name
	add_child(icon)
	return icon


func _text(text: String, color: Color) -> Label:
	var label: Label = RecipesPage.make_label(text, 22, color)
	add_child(label)
	return label
