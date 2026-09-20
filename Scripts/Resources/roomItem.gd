extends StaticBody3D

@export var texture_size : int = 512
@export var brush_radius : int = 8

var mask_image : Image
var mask_texture : ImageTexture
var material : ShaderMaterial

@onready var mesh_instance : MeshInstance3D = $MeshInstance3D # Adjust to your mesh node path
var mesh_data_tool : MeshDataTool

func _ready():
	# 1. Create a blank black image memory
	mask_image = Image.create(texture_size, texture_size, false, Image.FORMAT_L8)
	mask_image.fill(Color(0, 0, 0))
	
	mask_texture = ImageTexture.create_from_image(mask_image)
	material = mesh_instance.get_active_material(0) as ShaderMaterial
	material.set_shader_parameter("mask_texture", mask_texture)
	
	# --- THE FIX STARTS HERE ---
	# Fetch your raw mesh
	var raw_mesh = mesh_instance.mesh
	var target_mesh : ArrayMesh
	
	if raw_mesh is ArrayMesh:
		# If it's an imported .gltf/.obj file, it's already an ArrayMesh
		target_mesh = raw_mesh
	else:
		# If it's a Godot Primitive (Box, Sphere, etc.), convert it to an ArrayMesh
		target_mesh = ArrayMesh.new()
		var surface_arrays = raw_mesh.get_mesh_arrays()
		target_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays)
	
	# 2. Extract the converted mesh data cleanly without errors
	mesh_data_tool = MeshDataTool.new()
	mesh_data_tool.create_from_surface(target_mesh, 0)
	# --- THE FIX ENDS HERE ---

func _physics_process(_delta):
	# Paint continuously while holding down the left mouse button
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var uv = get_uv_from_mouse()
		if uv != -Vector2.ONE:
			print("painting")
			paint_at_uv(uv)

func get_uv_from_mouse() -> Vector2:
	var viewport = get_viewport()
	var camera = viewport.get_camera_3d()
	if not camera:
		return -Vector2.ONE
		
	var mouse_pos = viewport.get_mouse_position()
	
	# Project ray from screen space into 3D world space
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 0xFFFFFFFF)
	query.collide_with_areas = true
	
	var result = space_state.intersect_ray(query)
	
	# Verify we hit THIS specific object, and that we have face hit data
	if result and result.collider == self and "face_index" in result:
		var face_idx = result.face_index
		if face_idx < 0:
			return -Vector2.ONE
			
		# Fetch the 3 vertices making up the collided triangle face
		var v0 = mesh_data_tool.get_face_vertex(face_idx, 0)
		var v1 = mesh_data_tool.get_face_vertex(face_idx, 1)
		var v2 = mesh_data_tool.get_face_vertex(face_idx, 2)
		
		# Fetch the UV mappings assigned to those vertices
		var uv0 = mesh_data_tool.get_vertex_uv(v0)
		var uv1 = mesh_data_tool.get_vertex_uv(v1)
		var uv2 = mesh_data_tool.get_vertex_uv(v2)
		
		# Find where the intersection point lies relative to the triangle corners
		# (Barycentric coordinate calculation)
		var p0 = mesh_instance.global_transform * mesh_data_tool.get_vertex(v0)
		var p1 = mesh_instance.global_transform * mesh_data_tool.get_vertex(v1)
		var p2 = mesh_instance.global_transform * mesh_data_tool.get_vertex(v2)
		
		var f1 = p0 - result.position
		var f2 = p1 - result.position
		var f3 = p2 - result.position
		
		var va = (p0 - p1).cross(p0 - p2).length()
		var va0 = f2.cross(f3).length() / va
		var va1 = f3.cross(f1).length() / va
		var va2 = f1.cross(f2).length() / va
		
		# Return the blended UV coordinate interpolation
		return uv0 * va0 + uv1 * va1 + uv2 * va2
		
	return -Vector2.ONE

func paint_at_uv(uv_coords: Vector2):
	var pixel_x = int(uv_coords.x * texture_size)
	var pixel_y = int(uv_coords.y * texture_size)
	
	for x in range(pixel_x - brush_radius, pixel_x + brush_radius):
		for y in range(pixel_y - brush_radius, pixel_y + brush_radius):
			if x >= 0 and x < texture_size and y >= 0 and y < texture_size:
				if (x - pixel_x)**2 + (y - pixel_y)**2 <= brush_radius**2:
					mask_image.set_pixel(x, y, Color(1, 1, 1))
					
	mask_texture.update(mask_image)
