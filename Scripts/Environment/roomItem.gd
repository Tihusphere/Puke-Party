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

func paint_at_hit(camera: Camera3D, result: Dictionary) -> void:
	if not is_instance_valid(camera):
		return

	if not mesh_instance or not mesh_data_tool:
		return

	if not paint_manager or GAMEMANAGER.isPlayerDisabled():
		return

	if result.get("collider") != self:
		return

	var face_idx: int = result.get("face_index", -1)

	# Face indices are needed to calculate the correct mesh UV.
	if face_idx < 0 or face_idx >= mesh_data_tool.get_face_count():
		return

	var v0_idx: int = mesh_data_tool.get_face_vertex(face_idx, 0)
	var v1_idx: int = mesh_data_tool.get_face_vertex(face_idx, 1)
	var v2_idx: int = mesh_data_tool.get_face_vertex(face_idx, 2)

	var p0: Vector3 = mesh_data_tool.get_vertex(v0_idx)
	var p1: Vector3 = mesh_data_tool.get_vertex(v1_idx)
	var p2: Vector3 = mesh_data_tool.get_vertex(v2_idx)

	var local_hit: Vector3 = mesh_instance.to_local(result["position"])

	var barycentric: Vector3 = Geometry3D.get_triangle_barycentric_coords(
		local_hit, p0, p1, p2
	)

	var uv0: Vector2 = mesh_data_tool.get_vertex_uv(v0_idx)
	var uv1: Vector2 = mesh_data_tool.get_vertex_uv(v1_idx)
	var uv2: Vector2 = mesh_data_tool.get_vertex_uv(v2_idx)

	var exact_uv: Vector2 = (
		uv0 * barycentric.x
		+ uv1 * barycentric.y
		+ uv2 * barycentric.z
	)

	exact_uv.x = clampf(exact_uv.x, 0.0, 1.0)
	exact_uv.y = clampf(exact_uv.y, 0.0, 1.0)

	var pixel_x: int = int(exact_uv.x * (canvas_size.x - 1))
	var pixel_y: int = int(exact_uv.y * (canvas_size.y - 1))

	# Stamp the active brush when there is enough hunger.
	if (
		GAMEMANAGER.current_hunger > 0
		and paint_manager.active_brush_image
	):
		var brush_img: Image = paint_manager.active_brush_image
		var bw: int = paint_manager.brush_w
		var bh: int = paint_manager.brush_h

		var start_x: int = pixel_x - int(bw / 2)
		var start_y: int = pixel_y - int(bh / 2)

		for bx in range(bw):
			for by in range(bh):
				var target_x: int = start_x + bx
				var target_y: int = start_y + by

				if (
					target_x < 0 or target_x >= canvas_size.x
					or target_y < 0 or target_y >= canvas_size.y
				):
					continue

				var stamp_pixel: Color = brush_img.get_pixel(bx, by)

				if stamp_pixel.a <= 0.0:
					continue

				var mask_stamp := Color(
					1.0, 1.0, 1.0, stamp_pixel.a
				)

				var current_pixel: Color = mask_image.get_pixel(
					target_x, target_y
				)

				mask_image.set_pixel(
					target_x,
					target_y,
					current_pixel.blend(mask_stamp)
				)

			GAMEMANAGER.score += 1

	else:
		mask_image.set_pixel(pixel_x, pixel_y, Color.WHITE)

	mask_texture.update(mask_image)

	var rainbow: bool = GAMEMANAGER.getRainbow()
	toggle_rainbow(rainbow)

	if not rainbow:
		GAMEMANAGER.current_hunger = clampi(
			GAMEMANAGER.current_hunger - 1,
			0,
			GAMEMANAGER.MAX_HUNGER
		)
		
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
