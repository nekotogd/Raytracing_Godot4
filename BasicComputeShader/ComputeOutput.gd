extends TextureRect

var image_size : Vector2i = Vector2i(768, 768)

func texture_init():
	var image = Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBAF)
	var image_texture = ImageTexture.create_from_image(image)
	texture = image_texture

func set_data(data : PackedByteArray):
	var image := Image.create_from_data(image_size.x, image_size.y, false, Image.FORMAT_RGBAF, data)
	texture.update(image)
