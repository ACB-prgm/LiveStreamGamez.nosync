shader_type canvas_item;


uniform sampler2D texture_mask;
uniform vec2 scale = vec2(1.0);
uniform vec2 movement_dir = vec2(1.0);
uniform float speed = 0.0;
uniform float snap_distance = 0.0;


void fragment() {
	vec2 uv = SCREEN_UV;

	// Flip the Y coordinate to avoid flipping the texture
	uv.y = 1.0 - uv.y;
	vec2 color_uv = uv;

	// Translate the uv coordinates to the center of the screen
	color_uv -= vec2(0.5, 0.5);
	// Scale the uv coordinates
	color_uv *= 1.0 / scale;
	// Translate the uv coordinates back to the original position
	color_uv += vec2(0.5, 0.5);
	
	// Calculate the displacement of the current pixel based on time and speed
	vec2 displacement = TIME * speed * movement_dir;
	
	// Round the displacement vector to the nearest multiple of the snap distance
    if (snap_distance > 0.0) {
        displacement = round(displacement / snap_distance) * snap_distance;
    }
	
    // Wrap the position of the current pixel within the range of [0, 1]
    color_uv = vec2(fract(color_uv.x + displacement.x), fract(color_uv.y + displacement.y));

	// Get the color value from the base texture
	vec4 color = texture(TEXTURE, color_uv);

	// Get the mask value from the mask texture
	vec4 mask = texture(texture_mask, uv);

	// Multiply the color by the mask value to create the masked effect
	color *= mask;

	COLOR = color;
	}
