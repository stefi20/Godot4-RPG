extends CharacterBody2D
class_name Enemy


@export var hit_effect_scene: PackedScene
@export var death_effect_scene: PackedScene
@onready var hitbox: Area2D = $HitBox
@onready var attack_timer: Timer = $Timer
@onready var hurt_box: Area2D = $WeaponAngle/HurtBox
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_tree:AnimationTree = $AnimationTree
@onready var anim_stats = anim_tree.get("parameters/playback")
@onready var stats: EnemyStats = $EnemyStats
@onready var player_detector: PlayerDetector = $PlayerDetector
@onready var wander_controller: WanderController = $WanderController
@onready var softCollision: = $SoftCollision
@onready var animSprite: AnimatedSprite2D =$Sprite2D
@onready var raycasts: Node2D = $RayCasts

enum {
	WANDER,
	IDLE,
	CHASE,
	ATTACK
}

var state = CHASE
var knockback = Vector2.ZERO
var can_attack: bool = true
var is_infight:bool = false
var old_position = Vector2.ZERO

func _ready():
	hitbox.connect("area_entered", on_Hitbox_area_entered)
	attack_timer.connect("timeout", attack_timer_timeout)
	hurt_box.connect("area_entered", on_hurtbox_area_entered)
	hurt_box.damage = stats.damage
	animSprite.play("fly")
	velocity = Vector2.ZERO
	pick_random_state([IDLE, WANDER])
	

func on_Hitbox_area_entered(area):
	if not area.is_in_group("playerSword"):
		return
	take_damage(area)


func _physics_process(delta):
	if knockback != Vector2.ZERO:
		knockback = knockback.move_toward(Vector2.ZERO, stats.FRICTION * delta)
		set_velocity(knockback)
		move_and_slide()
	if velocity != Vector2.ZERO:
		hurt_box.knockback_vector = velocity
	
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, stats.FRICTION * delta)
			seek_player()
			if wander_controller.get_time_left() == 0:
				update_wander()
			if player_detector.can_see_player():
				state = CHASE
				
		WANDER:
			seek_player()
			if wander_controller.get_time_left() == 0:
				update_wander()
			accelerate_towards_point(wander_controller.target_position, delta)
			if global_position.distance_to(wander_controller.target_position) <= stats.WANDER_TARGET_RANGE:
				update_wander()
			
		CHASE:
			var player = player_detector.player
			if player != null:
				if global_position.distance_to(player.global_position) <= stats.MIN_RANGE or global_position.distance_to(player.global_position) >= stats.MAX_RANGE:
					accelerate_towards_point(player.global_position, delta)
				else:
					if can_attack:
						state = ATTACK
					else:
						state = IDLE
			else:
				state = IDLE
		ATTACK:
			var player = player_detector.player
			if player != null:
				accelerate_towards_point(player.global_position, delta)
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 400
	move_and_slide()

func attack_timer_timeout():
	can_attack = true

func on_hurtbox_area_entered(area):
	if not area.get_parent().name == "Player":
		return
	can_attack = false
	attack_timer.start()
	state = IDLE

func seek_player():
	var player: Player = null
	if player_detector.can_see_player():
		player = player_detector.player
		if global_position.distance_to(player.global_position) <= stats.MIN_RANGE or global_position.distance_to(player.global_position) >= stats.MAX_RANGE:
			state = CHASE
		else:
			state = IDLE
	else:
		if player and player_detector.player == null:
			player = null
		return

func update_wander():
	state = pick_random_state([IDLE, WANDER])
	wander_controller.start_wander_timer(randi_range(1, 3))

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func accelerate_towards_point(point, delta):
	var speed: int = 0
	if state == WANDER or state == IDLE:
		speed = stats.MAX_SPEED
	else:
		speed = stats.WANDER_SPEED
	var direction = global_position.direction_to(point)

	velocity = velocity.move_toward(direction * speed, stats.ACCELERATION * delta)
	velocity += avoid_obstacles()
	animSprite.flip_h = velocity.x < 0

func avoid_obstacles():
	var avoid_vector
	raycasts.rotation = velocity.angle()
	for ray in raycasts.get_children():
		ray.target_position.x = velocity.length() * 1.2
		if ray.is_colliding():
			var obstacle = ray.get_collider()
			avoid_vector = (position + velocity - obstacle.position).normalized() * 12
			return avoid_vector
	return Vector2.ZERO
	
func take_damage(area):
	if stats.health >= 0:
		var effect = hit_effect_scene.instantiate() 
		var cs = get_tree().current_scene
		effect.global_position= animSprite.global_position
		effect.global_position.y += animSprite.offset.y
		cs.add_child(effect)
		stats.set_health( stats.health - area.damage)
		knockback = area.knockback_vector * 135
		anim_player.play("Hit")
		print("[!] Enemy: %s gets hitted for %s damage!" % [self.name, area.damage])
		if stats.health < 0:
			var effect2 = death_effect_scene.instantiate()
			effect2.global_position = animSprite.global_position
			#effect2.global_position.y += animSprite.offset.y
			cs.add_child(effect2)
			if QuestManager.current_quest.quest_id == 2:
				QuestManager.current_quest.add_quest_items()
			reward_player()
			self.call_deferred("queue_free")
			print("[!] Enemy: %s died!" % self.name)
		
	else:
		return

func reward_player():
	if not GameManager.player or stats.reward_exp == 0:
		return
	GameManager.player.stats.set_exp(GameManager.player.stats.experience + stats.reward_exp)
		
