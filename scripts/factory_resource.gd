extends Resource
class_name Factory

@export var name: String
@export var max_radius: int 
@export var expand_time: int 
@export var pollution_type: String
@export var sprite_frames: SpriteFrames
@export var smoke_particelse: PackedScene
@export var smoke_particels_modulate: Color = Color(1,1,1,1)
@export var smoke_particels_amount: int = 10
@export var smoke_size: float = 1
@export var smoke_particles_positions: Array[Vector2]
