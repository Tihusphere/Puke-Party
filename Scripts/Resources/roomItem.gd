class_name PaintableObject
extends StaticBody3D

@export var mesh_instance: MeshInstance3D
@export var mask_size := Vector2i(1024, 1024)

var mask_image: Image
var mask_texture: ImageTexture
var shader_material: ShaderMaterial

var mesh_vertices: PackedVector3Array
var mesh_uvs: PackedVector2Array
var mesh_indices: PackedInt32Array


func _ready() -> void:
	_setup_mesh_data()
	_setup_mask()
	_setup_material()


func _setup_mesh_data() -> void:
	var mesh := mesh_instance.mesh

	if mesh == null:
		return

	var arrays := mesh.surface_get_arrays(0)

	mesh_vertices = arrays[Mesh.ARRAY_VERTEX]
	mesh_uvs = arrays[Mesh.ARRAY_TEX_UV]

	if arrays[Mesh.ARRAY_INDEX] != null:
		mesh_indices = arrays[Mesh.ARRAY_INDEX]


func _setup_mask() -> void:
	mask_image = Image.create(
		mask_size.x,
		mask_size.y,
		false,
		Image.FORMAT_RGBA8
	)

	mask_image.fill(Color.BLACK)

	# Put one white pixel in the center as a test
	mask_image.set_pixel(
		mask_size.x / 2,
		mask_size.y / 2,
		Color.WHITE
	)

	mask_texture = ImageTexture.create_from_image(mask_image)

	print("MASK CREATED: ", mask_texture)


func _setup_material() -> void:
	shader_material = mesh_instance.get_active_material(0) as ShaderMaterial

	if shader_material == null:
		print("NO SHADER MATERIAL FOUND")
		return

	print("SHADER MATERIAL FOUND")

	shader_material.set_shader_parameter(
		"mask_texture",
		mask_texture
	)

	print("MASK TEXTURE ASSIGNED")


# Called by the mouse script
func paint_at_hit(
	world_position: Vector3,
	face_index: int,
	brush_size: float
) -> void:

	var uv := get_uv_at_hit(world_position, face_index)

	print("UV: ", uv)

	if uv.x < 0.0:
		print("INVALID UV")
		return

	print("PAINTING AT UV: ", uv)

	paint_at_uv(uv, brush_size)


func get_uv_at_hit(
	world_position: Vector3,
	face_index: int
) -> Vector2:

	if face_index < 0:
		return Vector2(-1, -1)

	var i0: int
	var i1: int
	var i2: int

	if mesh_indices.is_empty():

		var base := face_index * 3

		i0 = base
		i1 = base + 1
		i2 = base + 2

	else:

		var base := face_index * 3

		i0 = mesh_indices[base]
		i1 = mesh_indices[base + 1]
		i2 = mesh_indices[base + 2]


	var local_position := (
		mesh_instance.global_transform.affine_inverse()
		* world_position
	)

	var a := mesh_vertices[i0]
	var b := mesh_vertices[i1]
	var c := mesh_vertices[i2]

	var bary := _get_barycentric(
		local_position,
		a,
		b,
		c
	)

	var uv_a := mesh_uvs[i0]
	var uv_b := mesh_uvs[i1]
	var uv_c := mesh_uvs[i2]

	return (
		uv_a * bary.x +
		uv_b * bary.y +
		uv_c * bary.z
	)


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

	var denominator := d00 * d11 - d01 * d01

	if abs(denominator) < 0.000001:
		return Vector3(1, 0, 0)

	var v := (
		d11 * d20 -
		d01 * d21
	) / denominator

	var w := (
		d00 * d21 -
		d01 * d20
	) / denominator

	var u := 1.0 - v - w

	return Vector3(u, v, w)


func paint_at_uv(
	uv: Vector2,
	brush_size: float
) -> void:

	# Convert UV to mask pixel coordinates.
	var center := Vector2(
		uv.x * mask_size.x,
		(1.0 - uv.y) * mask_size.y
	)

	var radius := brush_size / 2.0

	var min_x = max(0, int(center.x - radius))
	var max_x = min(mask_size.x - 1, int(center.x + radius))

	var min_y = max(0, int(center.y - radius))
	var max_y = min(mask_size.y - 1, int(center.y + radius))


	for y in range(min_y, max_y + 1):

		for x in range(min_x, max_x + 1):

			var distance := center.distance_to(
				Vector2(x + 0.5, y + 0.5)
			)

			if distance > radius:
				continue

			# Small amount of falloff around the edge.
			var normalized := distance / radius

			var strength := 1.0

			if normalized > 0.8:
				strength = 1.0 - (
					(normalized - 0.8) / 0.2
				)

			var current := mask_image.get_pixel(x, y).r

			var new_value = max(
				current,
				strength
			)

			mask_image.set_pixel(
				x,
				y,
				Color(new_value, 0, 0, 1)
			)


	# Send the changed mask to the GPU.
	mask_texture.update(mask_image)
