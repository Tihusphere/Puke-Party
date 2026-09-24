extends Node

@export var camera: Camera3D
@export var brush_size: float = 40.0


#func _physics_process(_delta):
#	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
#		return
#
#	var mouse_position = get_viewport().get_mouse_position()
#
#	var ray_origin = camera.project_ray_origin(mouse_position)
#	var ray_direction = camera.project_ray_normal(mouse_position)
#
#	var query = PhysicsRayQueryParameters3D.create(
#		ray_origin,
#		ray_origin + ray_direction * 1000.0,
#		1
#	)
#
#	var result = camera.get_world_3d().direct_space_state.intersect_ray(query)
#
#	if result.is_empty():
#		print("Nothing hit")
#		return
#
#	print("Hit: ", result["collider"])
#	print("Face: ", result["face_index"])
#	print("Position: ", result["position"])
#
#	var object = result["collider"]
#
#	if object is PaintableObject:
#		print("PAINTABLE OBJECT FOUND")
#
#		object.paint_at_hit(
#			result["position"],
#			result["face_index"],
#		)
#	else:
#		print("NOT A PAINTABLE OBJECT")
