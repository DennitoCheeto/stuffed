class_name BakedMeshNode
extends Node2D
## Draws one baked mesh (a piece of furniture, the sunbeams) on its own node, with its parent's
## material. Godot skips drawing a node that is off the screen, so a big room only pays for what
## the camera sees.

var mesh: ArrayMesh


func _init(baked: ArrayMesh) -> void:
	mesh = baked
	use_parent_material = true


func _draw() -> void:
	draw_mesh(mesh, null)
