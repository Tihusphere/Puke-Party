class_name CameraController
extends Node3D

@export var camera : Camera3D
@export var ray_range: float = 100.0

var player_controller: PlayerController
var input_rotation: Vector3
var mouse_input: Vector2
var mouse_sensitivity: float = 0.005

var use_interpolation: bool = false
var circle_strafe: bool = true

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player_controller = get_parent()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_input.x += -event.screen_relative.x * mouse_sensitivity
		mouse_input.y += -event.screen_relative.y * mouse_sensitivity

func _unhandled_input(event: InputEvent) -> void:
	# Check if the input is a mouse event (clicks, releases, drags, etc.)
	if event is InputEventMouse:
		var space_state = get_world_3d().direct_space_state
		
		# Find the center of the screen
		var screen_center = get_viewport().get_visible_rect().size / 2.0
		
		# Generate the ray mathematical properties
		var ray_origin = camera.project_ray_origin(screen_center)
		var ray_end = ray_origin + camera.project_ray_normal(screen_center) * ray_range
		
		# Run the 3D physics raycast
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		var result = space_state.intersect_ray(query)
		
		# If we hit an object, forward the full event parameters to it
		if result and result.collider:
			var hit_object = result.collider
			
			# Check if the object has the native _input_event method overridden
			if hit_object.has_method("_input_event"):
				hit_object._input_event(
					camera, 
					event, 
					result.position, 
					result.normal, 
					result.shape
				)

func _process(_delta: float) -> void:
	input_rotation.x = clampf(input_rotation.x + mouse_input.y, deg_to_rad(-90), deg_to_rad(85))
	input_rotation.y += mouse_input.x
	
	# rotate camera controller (up/down)
	transform.basis = Basis.from_euler(Vector3(input_rotation.x, 0.0, 0.0))
	
	# rotate player (left/right)
	player_controller.global_transform.basis = Basis.from_euler(Vector3(0.0, input_rotation.y, 0.0))
	
	# reset mouse position to zero
	mouse_input = Vector2.ZERO
