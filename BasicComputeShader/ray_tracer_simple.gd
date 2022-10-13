extends Node

var image_size : Vector2i
var global_time : float = 0.0
var rd = RenderingServer.create_local_rendering_device()
var uniform_set
var pipeline
var image_buffer_out
var bindings : Array
var shader
var output_tex : RID

@onready var directional_light : DirectionalLight3D = $DirectionalLight3d
@onready var texture_rect = $Camera3d/RayTracerSimple/ComputeOutput
@onready var camera : Camera3D = $Camera3d

func _ready():
	image_size.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	image_size.y = ProjectSettings.get_setting("display/window/size/viewport_height")
	
	texture_rect.image_size = image_size
	texture_rect.texture_init()
	
	setup_compute()
	render()

func _process(delta):
	update_compute()
	render(delta)

func matrix_to_bytes(t : Transform3D):
	# Helper function
	# Encodes the values of a "global_transform" into bytes
	
	var basis : Basis = t.basis
	var origin : Vector3 = t.origin
	var bytes : PackedByteArray = PackedFloat32Array([
		basis.x.x, basis.x.y, basis.x.z, 1.0,
		basis.y.x, basis.y.y, basis.y.z, 1.0,
		basis.z.x, basis.z.y, basis.z.z, 1.0,
		origin.x, origin.y, origin.z, 1.0
	]).to_byte_array()
	return bytes

func setup_compute():
	# Create shader and pipeline
	var shader_file = load("res://BasicComputeShader/RayTracer.glsl")
	var shader_spirv = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	
	# Data for compute shaders has to come as an array of bytes
	# The rest of this function is just creating storage buffers and texture uniforms
	
	# Camera Matrices Buffer
	var cam_to_world : Transform3D = camera.global_transform
	var camera_matrices_bytes := PackedByteArray()
	camera_matrices_bytes.append_array(matrix_to_bytes(cam_to_world))
	camera_matrices_bytes.append_array(PackedFloat32Array([70.0, 4000.0, 0.05]).to_byte_array())
	var camera_matrices_buffer = rd.storage_buffer_create(camera_matrices_bytes.size(), camera_matrices_bytes)
	var camera_matrices_uniform := RDUniform.new()
	camera_matrices_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	camera_matrices_uniform.binding = 0
	camera_matrices_uniform.add_id(camera_matrices_buffer)
	
	# Directional Light Buffer
	var light_direction : Vector3 = -directional_light.global_transform.basis.z
	light_direction = light_direction.normalized()
	var light_data_bytes := PackedFloat32Array([
		light_direction.x, light_direction.y, light_direction.z,
		directional_light.light_energy
	]).to_byte_array()
	var light_data_buffer = rd.storage_buffer_create(light_data_bytes.size(), light_data_bytes)
	var light_data_uniform := RDUniform.new()
	light_data_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	light_data_uniform.binding = 1
	light_data_uniform.add_id(light_data_buffer)
	
	# Output Texture Buffer
	var fmt := RDTextureFormat.new()
	fmt.width = image_size.x
	fmt.height = image_size.y
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	var view := RDTextureView.new()
	var output_image := Image.new()
	output_image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBAF)
	output_tex = rd.texture_create(fmt, view, [output_image.get_data()])
	var output_tex_uniform := RDUniform.new()
	output_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_tex_uniform.binding = 2
	output_tex_uniform.add_id(output_tex)
	
	# Global Parameters
	var params : PackedByteArray = PackedFloat32Array([
		global_time
	]).to_byte_array()
	var params_buffer = rd.storage_buffer_create(params.size(), params)
	var params_uniform := RDUniform.new()
	params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	params_uniform.binding = 3
	params_uniform.add_id(params_buffer)
	
	# Create uniform set using the storage buffers
	# The order of the uniforms in the array doesn't matter
	# This is because the RDUniform.binding property already defines its index in the uniform set
	bindings = [
		camera_matrices_uniform,
		light_data_uniform,
		output_tex_uniform,
		params_uniform,
	]
	uniform_set = rd.uniform_set_create(bindings, shader, 0)

func update_compute():
	# This function updates the uniforms with whatever data is changed per-frame
	
	var params : PackedByteArray = PackedFloat32Array([
		global_time
	]).to_byte_array()
	var params_buffer = rd.storage_buffer_create(params.size(), params)
	var params_uniform := RDUniform.new()
	params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	params_uniform.binding = 3
	params_uniform.add_id(params_buffer)
	
	# Camera Matrices Buffer
	var cam_to_world : Transform3D = camera.global_transform
	var camera_matrices_bytes := PackedByteArray()
	camera_matrices_bytes.append_array(matrix_to_bytes(cam_to_world))
	camera_matrices_bytes.append_array(PackedFloat32Array([70.0, 4000.0, 0.05]).to_byte_array())
	var camera_matrices_buffer = rd.storage_buffer_create(camera_matrices_bytes.size(), camera_matrices_bytes)
	var camera_matrices_uniform := RDUniform.new()
	camera_matrices_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	camera_matrices_uniform.binding = 0
	camera_matrices_uniform.add_id(camera_matrices_buffer)
	
	bindings[3] = params_uniform
	bindings[0] = camera_matrices_uniform
	uniform_set = rd.uniform_set_create(bindings, shader, 0)

func render(delta : float = 0.0):
	global_time += delta
	
	# Start compute list to start recording our compute commands
	var compute_list = rd.compute_list_begin()
	# Bind the pipeline, this tells the GPU what shader to use
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	# Binds the uniform set with the data we want to give our shader
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	# Dispatch (X,Y,Z) work groups
	@warning_ignore(integer_division)
	rd.compute_list_dispatch(compute_list, image_size.x / 8, image_size.y / 8, 1)
	
	# Tell the GPU we are done with this compute task
	rd.compute_list_end()
	# Force the GPU to start our commands
	rd.submit()
	# Force the CPU to wait for the GPU to finish with the recorded commands
	rd.sync()
	
	# Now we can grab our data from the output texture
	var byte_data : PackedByteArray = rd.texture_get_data(output_tex, 0)
	texture_rect.set_data(byte_data)
