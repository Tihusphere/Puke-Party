class_name CameraController
extends Node3D

@export var camera: Camera3D
@export var ray_range: float = 100.0

var player_controller: PlayerController
var input_rotation: Vector3
var mouse_input: Vector2
var mouse_sensitivity: float = 0.005

var use_interpolation: bool = false
var circle_strafe: bool = true

# True only while the left mouse button is held.
var is_painting: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player_controller = get_parent()

	if not camera:
		push_error("CameraController: Camera3D is not assigned.")
		set_physics_process(false)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_input.x += -event.screen_relative.x * mouse_sensitivity
		mouse_input.y += -event.screen_relative.y * mouse_sensitivity

	# Track only actual left mouse button presses/releases.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_painting = event.pressed


func _physics_process(_delta: float) -> void:
	if not is_painting or not camera:
		return

	# Use the center of the viewport as the aiming point.
	var screen_center: Vector2 = get_viewport().get_visible_rect().size / 2.0

	var ray_origin: Vector3 = camera.project_ray_origin(screen_center)
	var ray_end: Vector3 = ray_origin + camera.project_ray_normal(screen_center) * ray_range

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		return

	var hit_object = result.get("collider")

	# Only paint objects that explicitly support painting.
	if hit_object is PaintableObject:
		if not GAMEMANAGER.isPlayerDisabled():
			hit_object.paint_at_hit(camera, result)


func _process(_delta: float) -> void:
	input_rotation.x = clampf(
		input_rotation.x + mouse_input.y,
		deg_to_rad(-90.0),
		deg_to_rad(85.0)
	)

	input_rotation.y += mouse_input.x

	# Rotate camera controller up/down.
	transform.basis = Basis.from_euler(
		Vector3(input_rotation.x, 0.0, 0.0)
	)

	# Rotate player left/right.
	if player_controller:
		player_controller.global_transform.basis = Basis.from_euler(
			Vector3(0.0, input_rotation.y, 0.0)
		)

	mouse_input = Vector2.ZERO
