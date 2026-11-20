extends RefCounted
## Readability sweeps (AC-73, AC-83): every colour a node and its children carry: tints, Color
## variables, theme colour overrides, their style boxes, plushie looks, felt sketches
## (`BuildingSketch.colors()`), gear pieces and the Color constants of their scripts. Tests check
## them against UiColors.is_danger.


static func colors_of(root: Object) -> Array[Color]:
	var found: Array[Color] = []
	var objects: Array[Object] = [root]
	if root is Node:
		objects.append_array((root as Node).find_children("*", "", true, false))
	for object: Object in objects:
		_add_properties(object, found)
		var script: Script = object.get_script() as Script
		if script != null:
			for value: Variant in script.get_script_constant_map().values():
				_add_value(value, found)
	return found


static func _add_properties(object: Object, found: Array[Color]) -> void:
	for property: Dictionary in object.get_property_list():
		var value: Variant = object.get(String(property["name"]))
		if value is BuildingSketch:
			found.append_array((value as BuildingSketch).colors())
		elif value is StyleBox or value is PlushieDef or value is GearDef:
			_add_properties(value as Object, found)
		else:
			_add_value(value, found)


static func _add_value(value: Variant, found: Array[Color]) -> void:
	if value is Color:
		found.append(value as Color)
	elif value is PackedColorArray:
		for color: Color in value as PackedColorArray:
			found.append(color)
	elif value is Array:
		for item: Variant in value as Array:
			if item is Color:
				found.append(item as Color)
