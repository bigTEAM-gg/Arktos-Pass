@tool
extends MeshInstance3D


signal frame_changed(animation, frame)


@export var sprite_frames: SpriteFrames = null :
	set(value):
		sprite_frames = value
		_ready()
@export var animation: String = ""
@export var speed_scale: float = 1.0


const PX: float = 0.01


var frame: int = 0
var f: float = 0.0


const FOGGY_ANIMATED_SPRITE = preload("res://scenes/FoggyAnimatedSprite/FoggyAnimatedSprite.tres")


# Called when the node enters the scene tree for the first time.
func _ready():
	if sprite_frames == null:
		mesh = null
		return
	animation = sprite_frames.get_animation_names()[0]
	
	var frame_tex: Texture2D = sprite_frames.get_frame_texture(animation, frame)
	
	var uv_width = frame_tex.get_width() / 2.0 * PX
	var uv_height = frame_tex.get_height() / 2.0 * PX
	var surface_tool = SurfaceTool.new();
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES);
	
	# Top left.
	surface_tool.set_uv(Vector2(0, 0))
	surface_tool.add_vertex(Vector3(-uv_width, uv_height, 0));
	
	# Bottom left
	surface_tool.set_uv(Vector2(0, 1))
	surface_tool.add_vertex(Vector3(-uv_width, -uv_height, 0));
	
	# Bottom right.
	surface_tool.set_uv(Vector2(1, 1))
	surface_tool.add_vertex(Vector3(uv_width, -uv_height, 0));
	
	# Top right.
	surface_tool.set_uv(Vector2(1, 0))
	surface_tool.add_vertex(Vector3(uv_width, uv_height, 0));

	# Add the indices to the surface tool.
	# Because a face is made of up two triangles, we'll need to add six indices.
	# First triangle
	surface_tool.add_index(0);
	surface_tool.add_index(1);
	surface_tool.add_index(2);
	# Second triangle
	surface_tool.add_index(0);
	surface_tool.add_index(2);
	surface_tool.add_index(3);

	# Get the resulting mesh from the surface tool, and apply it to the MeshInstance.
	mesh = surface_tool.commit();
	mesh.surface_set_material(0, FOGGY_ANIMATED_SPRITE.duplicate())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if mesh == null:
		return
	var effective_speed = (1.0 / sprite_frames.get_animation_speed(animation)) * speed_scale
	f += delta
	if f >= effective_speed:
		frame = (frame + 1) % sprite_frames.get_frame_count(animation)
		f = fmod(f, effective_speed)
		frame_changed.emit(animation, frame)
	
	var frame_tex: Texture2D = sprite_frames.get_frame_texture(animation, frame)
	mesh.surface_get_material(0).set_shader_parameter("albedo", frame_tex)
	mesh.surface_get_material(0).set_shader_parameter("scale", scale.x)


func play(animation: String):
	self.animation = animation
	# frame = 0
	f = 0.0
