extends StaticBody3D

@export var mesh_instance: MeshInstance3D

var canvas_size: Vector2i = Vector2i(512, 512)
var image: Image
var texture: ImageTexture
var material: StandardMaterial3D

var is_painting: bool = false
var current_camera: Camera3D

func _ready() -> void:
	# 1. Fallback if the export variable isn't assigned in the inspector
	if not mesh_instance:
		mesh_instance = get_node_or_null("MeshInstance3D")
		if not mesh_instance:
			# Look through children dynamically
			for child in get_children():
				if child is MeshInstance3D:
					mesh_instance = child
					break
	
	if not mesh_instance:
		push_error("Error: Could not find a MeshInstance3D child node!")
		return

	# 2. Setup a clear drawing texture
	image = Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	
	texture = ImageTexture.create_from_image(image)
	material = StandardMaterial3D.new()
	material.albedo_texture = texture
	mesh_instance.material_override = material
	
	# Enable ray picking explicitly
	input_ray_pickable = true

# This signal acts as a trigger to tell us IF the mouse is interacting with this box
func _on_input_event(camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if camera is Camera3D:
		current_camera = camera # Save which camera we are interacting through

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_painting = event.pressed
		if not is_painting:
			current_camera = null

func _physics_process(_delta: float) -> void:
	# Only execute raycasts if the mouse button is actively held down over the box
	if not is_painting or not current_camera:
		return
		
	# Get the accurate viewport viewport-screen mouse coordinate
	var mouse_pos = get_viewport().get_mouse_position()
	
	var space_state = get_world_3d().direct_space_state
	var ray_origin = current_camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + current_camera.project_ray_normal(mouse_pos) * 1000.0
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	# Verify the raycast successfully intersected this specific node
	if result and result.collider == self:
		var uv_value = result.get("uv")
		var uv: Vector2 = Vector2.ZERO
		
		if uv_value != null:
			# Trimesh Collision uses the exact UV layout
			uv = uv_value
		else:
			# Fallback calculation engine for BoxShape3Ds
			var local_pos: Vector3 = mesh_instance.to_local(result.position)
			var local_normal: Vector3 = mesh_instance.global_transform.basis.inverse() * result.normal
			local_normal = local_normal.normalized()
			
			var box_size: Vector3 = Vector3.ONE
			if mesh_instance.mesh is BoxMesh:
				box_size = mesh_instance.mesh.size
			
			box_size = box_size * mesh_instance.scale
			var half_size: Vector3 = box_size * 0.5
			
			if local_normal.x > 0.9: # Right Face (+X)
				uv = Vector2(1.0 - ((local_pos.z + half_size.z) / box_size.z), 1.0 - ((local_pos.y + half_size.y) / box_size.y))
			elif local_normal.x < -0.9: # Left Face (-X)
				uv = Vector2((local_pos.z + half_size.z) / box_size.z, 1.0 - ((local_pos.y + half_size.y) / box_size.y))
			elif local_normal.y > 0.9: # Top Face (+Y)
				uv = Vector2((local_pos.x + half_size.x) / box_size.x, (local_pos.z + half_size.z) / box_size.z)
			elif local_normal.y < -0.9: # Bottom Face (-Y)
				uv = Vector2((local_pos.x + half_size.x) / box_size.x, 1.0 - ((local_pos.z + half_size.z) / box_size.z))
			elif local_normal.z > 0.9: # Front Face (+Z)
				uv = Vector2((local_pos.x + half_size.x) / box_size.x, 1.0 - ((local_pos.y + half_size.y) / box_size.y))
			elif local_normal.z < -0.9: # Back Face (-Z)
				uv = Vector2(1.0 - ((local_pos.x + half_size.x) / box_size.x), 1.0 - ((local_pos.y + half_size.y) / box_size.y))
		
		# Map the finalized 0-1 values directly to the canvas pixels
		uv.x = clamp(uv.x, 0.0, 1.0)
		uv.y = clamp(uv.y, 0.0, 1.0)
		
		var pixel_x: int = int(uv.x * (canvas_size.x - 1))
		var pixel_y: int = int(uv.y * (canvas_size.y - 1))
		
		# Paint a circular brush tip
		var brush_radius: int = 8
		var brush_color: Color = Color.BLUE
		
		for dx in range(-brush_radius, brush_radius):
			for dy in range(-brush_radius, brush_radius):
				if dx*dx + dy*dy <= brush_radius*brush_radius:
					var px = pixel_x + dx
					var py = pixel_y + dy
					if px >= 0 and px < canvas_size.x and py >= 0 and py < canvas_size.y:
						image.set_pixel(px, py, brush_color)
						
		texture.update(image)
