@tool
extends MeshInstance3D


@export var sprite: Texture2D = null
@export var animation: String = ""
@export var speed_scale: float = 1.0


const PX: float = 0.01


var frame: int = 0
var f: float = 0.0


const FOGGY_SPRITE = preload("res://scenes/FoggySprite/FoggySprite.tres")


# Called when the node enters the scene tree for the first time.
func _ready():
	var uv_width = sprite.get_width() / 2.0 * PX
	var uv_height = sprite.get_height() / 2.0 * PX
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
	mesh.surface_set_material(0, FOGGY_SPRITE.duplicate())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	mesh.surface_get_material(0).set_shader_parameter("albedo", sprite)
	mesh.surface_get_material(0).set_shader_parameter("scale", scale.x)
	mesh.surface_get_material(0).set_shader_parameter("is_editor", Engine.is_editor_hint())
