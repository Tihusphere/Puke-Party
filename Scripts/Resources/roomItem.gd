class_name PaintableObject
extends StaticBody3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D # Adjust path to your mesh

var canvas_size: Vector2i = Vector2i(512, 512)
var image: Image
var texture: ImageTexture
var material: StandardMaterial3D

var is_painting: bool = false

func _ready() -> void:
	# 1. Initialize a blank image canvas
	image = Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	
	# 2. Setup the dynamic texture and apply to mesh
	texture = ImageTexture.create_from_image(image)
	material = StandardMaterial3D.new()
	material.albedo_texture = texture
	mesh_instance.material_override = material

func _on_input_event(camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	# Check for click press / release
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_painting = event.pressed
		if is_painting:
			find_uv_and_paint(camera, event.position)

	# Check for drag motion
	elif event is InputEventMouseMotion and is_painting:
		find_uv_and_paint(camera, event.position)

func find_uv_and_paint(camera: Camera3D, mouse_pos: Vector2) -> void:
	var space_state = get_world_3d().direct_space_state
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider == self:
		var uv_value = result.get("uv")
		var uv: Vector2 = Vector2.ZERO
		
		if uv_value != null:
			uv = uv_value
		else:
			# CORRECT LOCAL POSITION
			var local_pos: Vector3 = mesh_instance.to_local(result.position)
			
			# CORRECT LOCAL NORMAL TRANSFORMATION FOR GODOT 4
			# We multiply the global normal by the inverse of the mesh's basis to correctly rotate it back to local space
			var local_normal: Vector3 = mesh_instance.global_transform.basis.inverse() * result.normal
			local_normal = local_normal.normalized()
			
			# Account for the size/scale of a default 1x1x1 primitive BoxMesh
			# A standard BoxMesh extends from -0.5 to 0.5 in local coordinates
			if abs(local_normal.x) > 0.9: # Hitting Left (-X) or Right (+X) face
				uv = Vector2(local_pos.z + 0.5, 1.0 - (local_pos.y + 0.5))
			elif abs(local_normal.y) > 0.9: # Hitting Top (+Y) or Bottom (-Y) face
				uv = Vector2(local_pos.x + 0.5, local_pos.z + 0.5)
			elif abs(local_normal.z) > 0.9: # Hitting Front (+Z) or Back (-Z) face
				uv = Vector2(local_pos.x + 0.5, 1.0 - (local_pos.y + 0.5))
				
			uv.x = clamp(uv.x, 0.0, 1.0)
			uv.y = clamp(uv.y, 0.0, 1.0)
			print("DEBUG: Fixed Fallback UV: ", uv)
			
		paint_at_uv(uv)



func paint_at_uv(uv: Vector2) -> void:
	# Map the 0.0 - 1.0 UV range to our pixel canvas dimensions
	var pixel_x: int = int(uv.x * (canvas_size.x - 1))
	var pixel_y: int = int(uv.y * (canvas_size.y - 1))
	
	# 5. Draw a round brush tip
	var brush_radius: int = 6
	var brush_color: Color = Color.DARK_BLUE
	
	for dx in range(-brush_radius, brush_radius):
		for dy in range(-brush_radius, brush_radius):
			if dx*dx + dy*dy <= brush_radius*brush_radius:
				var px = pixel_x + dx
				var py = pixel_y + dy
				# Prevent drawing outside texture bounds
				if px >= 0 and px < canvas_size.x and py >= 0 and py < canvas_size.y:
					image.set_pixel(px, py, brush_color)
	
	# Update the GPU texture representation
	texture.update(image)
