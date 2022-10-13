extends TextureRect

var image_size : Vector2i = Vector2i(768, 768)

func texture_init():
	var image = Image.new()
	image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBAF)
	var image_texture = ImageTexture.new()
	image_texture = image_texture.create_from_image(image)
	texture = image_texture

func set_data(data : PackedByteArray):
	var image := Image.new()
	image.create_from_data(image_size.x, image_size.y, false, Image.FORMAT_RGBAF, data)
	texture.update(image)
