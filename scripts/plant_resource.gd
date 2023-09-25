extends Resource
class_name  Plant

signal has_grown
signal generated_currency

@export var name: String
@export var amount_of_currency_produced: int 
@export var currency_production_time: int  = 1
@export var cost: int 
@export var growth_time: int 
@export var max_radius: int
@export var sprite_frames: SpriteFrames
@export var is_prime: bool
@export var can_be_killed: bool
@export var starting_pos: Vector2
