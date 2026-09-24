extends StaticBody3D

@export var mesh_instance: MeshInstance3D

var canvas_size: Vector2i = Vector2i(1024, 1024)
var image: Image
var texture: ImageTexture
var material: StandardMaterial3D

var is_painting: bool = false
var current_camera: Camera3D
var mesh_data_tool: MeshDataTool

func _ready() -> void:
	# 1. Fallback to locate the MeshInstance3D child node automatically
	if not mesh_instance:
		for child in get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break
				
	if not mesh_instance or not mesh_instance.mesh:
		push_error("CANNOT PAINT: Missing valid MeshInstance3D with a mesh resource!")
		return

	# 2. CONVERT TO ARRAYMESH: Essential for imported Blender nodes
	var base_mesh = mesh_instance.mesh
	var array_mesh: ArrayMesh
	
	if base_mesh is ArrayMesh:
		array_mesh = base_mesh
	else:
		# If it's an ImporterMesh/Primitive, convert it dynamically to an ArrayMesh
		array_mesh = ArrayMesh.new()
		for i in range(base_mesh.get_surface_count()):
			array_mesh.add_surface_from_arrays(
				Mesh.PRIMITIVE_TRIANGLES, 
				base_mesh.surface_get_arrays(i)
			)
			
	# 3. Cache the native Blender geometry topology maps
	mesh_data_tool = MeshDataTool.new()
	mesh_data_tool.create_from_surface(array_mesh, 0)

	# 4. Create and bind the visual texture canvas
	image = Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	
	texture = ImageTexture.create_from_image(image)
	material = StandardMaterial3D.new()
	material.albedo_texture = texture
	mesh_instance.material_override = material
	
	input_ray_pickable = true

func _on_input_event(camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if camera is Camera3D:
		current_camera = camera
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_painting = event.pressed
		if not is_painting:
			current_camera = null

func _physics_process(_delta: float) -> void:
	if not is_painting or not current_camera:
		return
		
	var mouse_pos = get_viewport().get_mouse_position()
	var space_state = get_world_3d().direct_space_state
	var ray_origin = current_camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + current_camera.project_ray_normal(mouse_pos) * 1000.0
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider == self:
		# Get the exact physics primitive face ID hit by our pointer ray
		var face_idx: int = result.get("face_index", -1)
		
		# Fallback if using standard editor nodes that skip face indices
		if face_idx == -1:
			return
			
		# 5. BARYCENTRIC INTERPOLATION ENGINE
		# Retrieve the three specific vertex references forming the hit triangle face
		var v0_idx = mesh_data_tool.get_face_vertex(face_idx, 0)
		var v1_idx = mesh_data_tool.get_face_vertex(face_idx, 1)
		var v2_idx = mesh_data_tool.get_face_vertex(face_idx, 2)
		
		var p0 = mesh_data_tool.get_vertex(v0_idx)
		var p1 = mesh_data_tool.get_vertex(v1_idx)
		var p2 = mesh_data_tool.get_vertex(v2_idx)
		
		var local_hit: Vector3 = mesh_instance.to_local(result.position)
		
		# Find the positional ratio relative to each vertex edge bounding space
		var barycentric = Geometry3D.get_triangle_barycentric_coords(local_hit, p0, p1, p2)
		
		# Retrieve the true unwrapped UV maps assigned inside Blender
		var uv0 = mesh_data_tool.get_vertex_uv(v0_idx)
		var uv1 = mesh_data_tool.get_vertex_uv(v1_idx)
		var uv2 = mesh_data_tool.get_vertex_uv(v2_idx)
		
		# Perform a smooth cross-fade blend to extract the exact coordinate point
		var exact_uv: Vector2 = (uv0 * barycentric.x) + (uv1 * barycentric.y) + (uv2 * barycentric.z)
		
		# Clamp values safely inside bounds
		exact_uv.x = clamp(exact_uv.x, 0.0, 1.0)
		exact_uv.y = clamp(exact_uv.y, 0.0, 1.0)
		
		var pixel_x: int = int(exact_uv.x * (canvas_size.x - 1))
		var pixel_y: int = int(exact_uv.y * (canvas_size.y - 1))
		
		# Draw a round brush stroke tip
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
