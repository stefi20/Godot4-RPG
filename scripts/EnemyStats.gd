extends Node
class_name EnemyStats

@export_category('Stats Settings')
@export_group('Health Settings')
@export var max_health: int
@export var healt_reg_rate: float
@export var damage: int

@export_category('Movement Settings')
@export_group('Base Movement')
@export var MAX_SPEED:int# = 50
@export var ACCELERATION:int# = 300
@export var FRICTION:int# = 200

@export_group('Wander Movement')
@export var WANDER_SPEED: int
@export var WANDER_TARGET_RANGE: int# = 4

@export var MIN_RANGE: int
@export var MAX_RANGE: int

@export_category('Player Rewards')
@export var reward_exp: int


@onready var health: int = 0

func _ready():
	set_health(max_health)

func set_health(new_health):
	health = new_health
	print("[!] Enemy - %s - : Set health to %s" % [get_parent().name, health])

