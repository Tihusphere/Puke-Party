class_name PaintableObject
extends StaticBody3D

@export var mesh_instance: MeshInstance3D
var paint_manager: GAMEMANAGER

## The primary texture assigned to this object
@export var base_texture: Texture2D

## Optional shader file reference (if not set, loads res://shaders/texture_blend_mask.gdshader)
@export var mask_shader: Shader

@export var canvas_size: Vector2i = Vector2i(1024, 1024)

var mask_image: Image
var mask_texture: ImageTexture
var shader_material: ShaderMaterial

var is_painting: bool = false
var current_camera: Camera3D
var mesh_data_tool: MeshDataTool

func _ready() -> void:
	paint_manager = GAMEMANAGER
	
	if not mesh_instance:
		for child in get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break
				
	if not mesh_instance or not mesh_instance.mesh:
		push_error("CANNOT PAINT: Missing valid MeshInstance3D with a mesh resource!")
		return

	# Convert mesh surface into ArrayMesh to build MeshDataTool
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

	# Initialize black mask image (0.0 red channel = base_texture only)
	mask_image = Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	mask_image.fill(Color.BLACK)
	mask_texture = ImageTexture.create_from_image(mask_image)

	# Setup Shader Material
	shader_material = ShaderMaterial.new()
	if mask_shader:
		shader_material.shader = mask_shader
	else:
		shader_material.shader = load("res://shaders/texture_blend_mask.gdshader")

	# Pass base texture, manager's overlay texture, and mask texture to shader
	shader_material.set_shader_parameter("base_texture", base_texture)
	if paint_manager and paint_manager.overlay_texture:
		shader_material.set_shader_parameter("overlay_texture", paint_manager.overlay_texture)
	shader_material.set_shader_parameter("mask_texture", mask_texture)

	mesh_instance.material_override = shader_material
	input_ray_pickable = true

func _input_event(camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
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
		if face_idx == -1: 
			return
			
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
		
		# Apply mask stamp based on active brush
		if paint_manager and paint_manager.active_brush_image:
			var brush_img = paint_manager.active_brush_image
			var bw = paint_manager.brush_w
			var bh = paint_manager.brush_h
			
			var start_x: int = pixel_x - (bw / 2)
			var start_y: int = pixel_y - (bh / 2)
			
			for bx in range(bw):
				for by in range(bh):
					var target_x = start_x + bx
					var target_y = start_y + by
					
					if target_x >= 0 and target_x < canvas_size.x and target_y >= 0 and target_y < canvas_size.y:
						var stamp_pixel: Color = brush_img.get_pixel(bx, by)
						
						if stamp_pixel.a > 0.0:
							# Convert brush opacity into white mask intensity
							var mask_stamp = Color(1.0, 1.0, 1.0, stamp_pixel.a)
							var current_mask_pixel: Color = mask_image.get_pixel(target_x, target_y)
							var blended_mask = current_mask_pixel.blend(mask_stamp)
							
							mask_image.set_pixel(target_x, target_y, blended_mask)
		else:
			mask_image.set_pixel(pixel_x, pixel_y, Color.WHITE)
						
		mask_texture.update(mask_image)

# Helper function 1: Toggle rainbow cycling on/off
func toggle_rainbow(enabled: bool, speed: float = 1.0) -> void:
	shader_material.set_shader_parameter("enable_rainbow_cycle", enabled)
	shader_material.set_shader_parameter("cycle_speed", speed)
	if enabled:
		# Turn off static hue if we are cycling
		shader_material.set_shader_parameter("enable_static_hue_shift", false)

# Helper function 2: Change hue to a fixed value and keep it there
func set_static_hue(hue_value: float) -> void:
	# hue_value should be between 0.0 and 1.0
	shader_material.set_shader_parameter("enable_static_hue_shift", true)
	shader_material.set_shader_parameter("static_hue_value", hue_value)
	# Turn off rainbow cycling so the static hue stays locked
	shader_material.set_shader_parameter("enable_rainbow_cycle", false)

# Optional helper: Reset back to completely normal overlay color
func reset_overlay_color() -> void:
	shader_material.set_shader_parameter("enable_rainbow_cycle", false)
	shader_material.set_shader_parameter("enable_static_hue_shift", false)
