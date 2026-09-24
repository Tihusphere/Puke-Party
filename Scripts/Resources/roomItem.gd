class_name PaintableObject
extends StaticBody3D


# ============================================================
# CONFIGURATION
# ============================================================

@export_category("Mesh")

@export var mesh_instance: MeshInstance3D


@export_category("Paint Mask")

@export var mask_size := Vector2i(1024, 1024)


@export_category("Textures")

@export var texture_a: Texture2D
@export var texture_b: Texture2D


@export_category("Brush")

@export var default_brush_size: float = 40.0

@export_range(0.0, 1.0)
var brush_hardness: float = 0.7


# ============================================================
# INTERNAL DATA
# ============================================================

var mask_image: Image
var mask_texture: ImageTexture

var shader_material: ShaderMaterial

var mesh_vertices: PackedVector3Array
var mesh_uvs: PackedVector2Array
var mesh_indices: PackedInt32Array


# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	_setup_mesh_data()
	_setup_mask()
	_setup_material()


# ============================================================
# MESH DATA
# ============================================================

func _setup_mesh_data() -> void:

	if mesh_instance == null:
		push_error(
			"PaintableObject: mesh_instance is not assigned."
		)
		return


	var mesh := mesh_instance.mesh

	if mesh == null:
		push_error(
			"PaintableObject: MeshInstance3D has no mesh."
		)
		return


	if mesh.get_surface_count() == 0:
		push_error(
			"PaintableObject: Mesh has no surfaces."
		)
		return


	# --------------------------------------------------------
	# Currently using surface 0.
	# --------------------------------------------------------

	var arrays := mesh.surface_get_arrays(0)

	mesh_vertices = arrays[Mesh.ARRAY_VERTEX]
	mesh_uvs = arrays[Mesh.ARRAY_TEX_UV]


	if arrays[Mesh.ARRAY_INDEX] != null:
		mesh_indices = arrays[Mesh.ARRAY_INDEX]
	else:
		mesh_indices = PackedInt32Array()


	if mesh_vertices.is_empty():
		push_error(
			"PaintableObject: Mesh contains no vertices."
		)


	if mesh_uvs.is_empty():
		push_error(
			"PaintableObject: Mesh contains no UV coordinates."
		)


	if mesh_uvs.size() != mesh_vertices.size():
		push_error(
			"PaintableObject: Vertex count and UV count don't match."
		)


# ============================================================
# MASK
# ============================================================

func _setup_mask() -> void:

	mask_image = Image.create(
		mask_size.x,
		mask_size.y,
		false,
		Image.FORMAT_RGBA8
	)

	mask_image.fill(Color.BLACK)


	# --------------------------------------------------------
	# Initial test pixel.
	# Remove this once everything is working.
	# --------------------------------------------------------

	mask_image.set_pixel(
		mask_size.x / 2,
		mask_size.y / 2,
		Color.WHITE
	)


	mask_texture = ImageTexture.create_from_image(
		mask_image
	)


	print("MASK CREATED: ", mask_texture)


# ============================================================
# MATERIAL
# ============================================================

func _setup_material() -> void:

	var original_material := (
		mesh_instance.get_active_material(0)
	)


	if original_material == null:
		push_error(
			"PaintableObject: No material found on surface 0."
		)
		return


	if not original_material is ShaderMaterial:
		push_error(
			"PaintableObject: Surface 0 material must be a ShaderMaterial."
		)
		return


	# --------------------------------------------------------
	# Duplicate the material.
	#
	# This is important because every paintable object needs
	# its own mask.
	# --------------------------------------------------------

	shader_material = (
		original_material.duplicate()
		as ShaderMaterial
	)


	mesh_instance.set_surface_override_material(
		0,
		shader_material
	)


	print("SHADER MATERIAL CREATED")


	# --------------------------------------------------------
	# Assign mask.
	# --------------------------------------------------------

	shader_material.set_shader_parameter(
		"mask_texture",
		mask_texture
	)


	# --------------------------------------------------------
	# Assign first texture.
	# --------------------------------------------------------

	if texture_a != null:

		shader_material.set_shader_parameter(
			"texture_a",
			texture_a
		)


	# --------------------------------------------------------
	# Assign second texture.
	# --------------------------------------------------------

	if texture_b != null:

		shader_material.set_shader_parameter(
			"texture_b",
			texture_b
		)


	print("TEXTURES AND MASK ASSIGNED")


# ============================================================
# WORLD POSITION → UV
# ============================================================

func paint_at_hit(
	world_position: Vector3,
	face_index: int,
	brush_size: float = default_brush_size
) -> void:

	var uv := get_uv_at_hit(
		world_position,
		face_index
	)


	if uv.x < 0.0:
		return


	paint_at_uv(
		uv,
		brush_size
	)


# ============================================================
# GET UV AT HIT
# ============================================================

func get_uv_at_hit(
	world_position: Vector3,
	face_index: int
) -> Vector2:

	if face_index < 0:
		return Vector2(-1.0, -1.0)


	if mesh_vertices.is_empty():
		return Vector2(-1.0, -1.0)


	if mesh_uvs.is_empty():
		return Vector2(-1.0, -1.0)


	# --------------------------------------------------------
	# Number of triangles
	# --------------------------------------------------------

	var triangle_count: int


	if mesh_indices.is_empty():

		triangle_count = (
			mesh_vertices.size() / 3
		)

	else:

		triangle_count = (
			mesh_indices.size() / 3
		)


	if face_index >= triangle_count:
		return Vector2(-1.0, -1.0)


	# --------------------------------------------------------
	# Get triangle vertex indices
	# --------------------------------------------------------

	var base := face_index * 3

	var i0: int
	var i1: int
	var i2: int


	if mesh_indices.is_empty():

		i0 = base
		i1 = base + 1
		i2 = base + 2

	else:

		i0 = mesh_indices[base]
		i1 = mesh_indices[base + 1]
		i2 = mesh_indices[base + 2]


	# --------------------------------------------------------
	# Convert world position into mesh-local space.
	# --------------------------------------------------------

	var local_position := (
		mesh_instance.global_transform.affine_inverse()
		* world_position
	)


	# --------------------------------------------------------
	# Triangle positions
	# --------------------------------------------------------

	var a := mesh_vertices[i0]
	var b := mesh_vertices[i1]
	var c := mesh_vertices[i2]


	# --------------------------------------------------------
	# Calculate barycentric coordinates.
	# --------------------------------------------------------

	var bary := _get_barycentric(
		local_position,
		a,
		b,
		c
	)


	if bary.x < 0.0:
		return Vector2(-1.0, -1.0)


	# --------------------------------------------------------
	# Triangle UVs
	# --------------------------------------------------------

	var uv_a := mesh_uvs[i0]
	var uv_b := mesh_uvs[i1]
	var uv_c := mesh_uvs[i2]


	# --------------------------------------------------------
	# Interpolate UV.
	# --------------------------------------------------------

	var uv := (
		uv_a * bary.x +
		uv_b * bary.y +
		uv_c * bary.z
	)


	return uv


# ============================================================
# BARYCENTRIC COORDINATES
# ============================================================

func _get_barycentric(
	point: Vector3,
	a: Vector3,
	b: Vector3,
	c: Vector3
) -> Vector3:

	var v0 := b - a
	var v1 := c - a
	var v2 := point - a


	var d00 := v0.dot(v0)
	var d01 := v0.dot(v1)
	var d11 := v1.dot(v1)
	var d20 := v2.dot(v0)
	var d21 := v2.dot(v1)


	var denominator := (
		d00 * d11 -
		d01 * d01
	)


	if abs(denominator) < 0.0000001:
		return Vector3(-1.0, -1.0, -1.0)


	var v := (
		d11 * d20 -
		d01 * d21
	) / denominator


	var w := (
		d00 * d21 -
		d01 * d20
	) / denominator


	var u := 1.0 - v - w


	# --------------------------------------------------------
	# Allow a tiny amount of floating-point error.
	# --------------------------------------------------------

	var tolerance := 0.0001


	if (
		u < -tolerance or
		v < -tolerance or
		w < -tolerance
	):
		return Vector3(-1.0, -1.0, -1.0)


	return Vector3(
		u,
		v,
		w
	)


# ============================================================
# PAINT AT UV
# ============================================================

func paint_at_uv(
	uv: Vector2,
	brush_size: float
) -> void:

	if mask_image == null:
		return


	if mask_texture == null:
		return


	if brush_size <= 0.0:
		return


	# --------------------------------------------------------
	# Clamp UV.
	# --------------------------------------------------------

	uv.x = clamp(
		uv.x,
		0.0,
		1.0
	)

	uv.y = clamp(
		uv.y,
		0.0,
		1.0
	)


	# --------------------------------------------------------
	# Convert UV → mask pixel.
	#
	# UV Y is normally bottom → top.
	# Image coordinates are top → bottom.
	# --------------------------------------------------------

	var center := Vector2(
		uv.x * float(mask_size.x - 1),
		(1.0 - uv.y) *
		float(mask_size.y - 1)
	)


	var radius := brush_size * 0.5


	# --------------------------------------------------------
	# Limit the painting region to the brush bounding box.
	# --------------------------------------------------------

	var min_x = max(
		0,
		int(floor(center.x - radius))
	)

	var max_x = min(
		mask_size.x - 1,
		int(ceil(center.x + radius))
	)


	var min_y = max(
		0,
		int(floor(center.y - radius))
	)

	var max_y = min(
		mask_size.y - 1,
		int(ceil(center.y + radius))
	)


	# --------------------------------------------------------
	# Paint.
	# --------------------------------------------------------

	for y in range(
		min_y,
		max_y + 1
	):

		for x in range(
			min_x,
			max_x + 1
		):

			var pixel_position := Vector2(
				x + 0.5,
				y + 0.5
			)


			var distance := (
				center.distance_to(
					pixel_position
				)
			)


			if distance > radius:
				continue


			var normalized := (
				distance / radius
			)


			# ------------------------------------------------
			# Soft brush falloff.
			# ------------------------------------------------

			var strength := (
				1.0 -
				smoothstep(
					brush_hardness,
					1.0,
					normalized
				)
			)


			# ------------------------------------------------
			# Existing mask value.
			# ------------------------------------------------

			var current := (
				mask_image
				.get_pixel(x, y)
				.r
			)


			# ------------------------------------------------
			# Painting only increases the mask.
			# ------------------------------------------------

			var new_value = max(
				current,
				strength
			)


			new_value = clamp(
				new_value,
				0.0,
				1.0
			)


			mask_image.set_pixel(
				x,
				y,
				Color(
					new_value,
					0.0,
					0.0,
					1.0
				)
			)


	# --------------------------------------------------------
	# Send modified image to GPU.
	# --------------------------------------------------------

	mask_texture.update(
		mask_image
	)
