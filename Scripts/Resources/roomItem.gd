extends StaticBody3D

@export var mesh_instance: MeshInstance3D
@export var brush_texture: Texture2D 

# 1. NEW SIZE VARIABLE: Set the pixel dimensions of your brush/stamp here
@export var brush_size: Vector2i = Vector2i(64, 64)

var canvas_size: Vector2i = Vector2i(1024, 1024)
var image: Image
var texture: ImageTexture
var material: StandardMaterial3D

var is_painting: bool = false
var current_camera: Camera3D
var mesh_data_tool: MeshDataTool

# Internal variables to store the processed brush data
var active_brush_image: Image
var brush_w: int = 0
var brush_h: int = 0

func _ready() -> void:
	if not mesh_instance:
		for child in get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break
				
	if not mesh_instance or not mesh_instance.mesh:
		push_error("CANNOT PAINT: Missing valid MeshInstance3D with a mesh resource!")
		return

	# 2. Initialize and cache the scaled brush texture
	update_brush_size()

	# Convert to ArrayMesh for Blender nodes
	var base_mesh = mesh_instance.mesh
	var array_mesh: ArrayMesh
	
	if base_mesh is ArrayMesh:
		array_mesh = base_mesh
	else:
		array_mesh = ArrayMesh.new()
		for i in range(base_mesh.get_surface_count()):
			array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, base_mesh.surface_get_arrays(i))
			
	mesh_data_tool = MeshDataTool.new()
	mesh_data_tool.create_from_surface(array_mesh, 0)

	# Create drawing texture canvas
	image = Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	
	texture = ImageTexture.create_from_image(image)
	material = StandardMaterial3D.new()
	material.albedo_texture = texture
	mesh_instance.material_override = material
	
	input_ray_pickable = true

# 3. HELPER FUNCTION TO RESIZE THE BRUSH ON DEMAND
func update_brush_size() -> void:
	if brush_texture:
		# Always pull a clean copy of the original source image
		active_brush_image = brush_texture.get_image()
		active_brush_image.convert(Image.FORMAT_RGBA8)
		
		# Resize the image dynamically using high-quality bilinear interpolation
		active_brush_image.resize(brush_size.x, brush_size.y, Image.INTERPOLATE_BILINEAR)
		
		# Update dimension caches
		brush_w = active_brush_image.get_width()
		brush_h = active_brush_image.get_height()
	else:
		push_warning("No brush texture assigned!")

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
		var face_idx: int = result.get("face_index", -1)
		if face_idx == -1: return
			
		var v0_idx = mesh_data_tool.get_face_vertex(face_idx, 0)
		var v1_idx = mesh_data_tool.get_face_vertex(face_idx, 1)
		var v2_idx = mesh_data_tool.get_face_vertex(face_idx, 2)
		
		var p0 = mesh_data_tool.get_vertex(v0_idx)
		var p1 = mesh_data_tool.get_vertex(v1_idx)
		var p2 = mesh_data_tool.get_vertex(v2_idx)
		
		var local_hit: Vector3 = mesh_instance.to_local(result.position)
		var barycentric = Geometry3D.get_triangle_barycentric_coords(local_hit, p0, p1, p2)
		
		var uv0 = mesh_data_tool.get_vertex_uv(v0_idx)
		var uv1 = mesh_data_tool.get_vertex_uv(v1_idx)
		var uv2 = mesh_data_tool.get_vertex_uv(v2_idx)
		
		var exact_uv: Vector2 = (uv0 * barycentric.x) + (uv1 * barycentric.y) + (uv2 * barycentric.z)
		
		exact_uv.x = clamp(exact_uv.x, 0.0, 1.0)
		exact_uv.y = clamp(exact_uv.y, 0.0, 1.0)
		
		var pixel_x: int = int(exact_uv.x * (canvas_size.x - 1))
		var pixel_y: int = int(exact_uv.y * (canvas_size.y - 1))
		
		if active_brush_image:
			var start_x: int = pixel_x - (brush_w / 2)
			var start_y: int = pixel_y - (brush_h / 2)
			
			for bx in range(brush_w):
				for by in range(brush_h):
					var target_x = start_x + bx
					var target_y = start_y + by
					
					if target_x >= 0 and target_x < canvas_size.x and target_y >= 0 and target_y < canvas_size.y:
						var stamp_pixel: Color = active_brush_image.get_pixel(bx, by)
						
						if stamp_pixel.a > 0.0:
							var bg_pixel: Color = image.get_pixel(target_x, target_y)
							var blended_color = bg_pixel.blend(stamp_pixel)
							image.set_pixel(target_x, target_y, blended_color)
		else:
			image.set_pixel(pixel_x, pixel_y, Color.BLUE)
						
		texture.update(image)
