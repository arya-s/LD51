extends KinematicBody2D

enum {
	LEFT = -1,
	NEUTRAL = 0,
	RIGHT = 1
}

onready var camera = $Camera
onready var label = $Label

# timers
onready var coyote_jump_timer = $CoyoteJumpTimer
onready var variable_jump_timer = $VariableJumpTimer
onready var jump_buffer_timer = $JumpBufferTimer
onready var force_move_x_timer = $ForceMoveXTimer
onready var jetpack_timer = $JetpackTimer
onready var bounce_var_jump_timer = $BounceVarJumpTimer

onready var particles_spawn = $ParticlesSpawn
onready var particles_wall_spawn = $ParticlesWallSpawn
#var Particles = preload("res://src/player/Particles.tscn")
var Particles = preload("res://src/player/ParticlesDust.tscn")
var ParticlesWall = preload("res://src/player/ParticlesDustWall.tscn")

# player
onready var sprite = $Sprite
onready var jump_audio = $JumpAudio
onready var bird_audio = $BirdAudio

export(float) var AIR_MULTIPLIER = 0.65
export(int) var GRAVITY = 900
export(int) var HALF_GRAVITY_THRESHOLD = 40
export(int) var RUN_ACCELERATION = 1000
export(int) var RUN_FRICTION = 900
export(int) var RUN_MAX_SPEED = 90
export(int) var JUMP_FORCE = -105
export(int) var JUMP_HORIZONTAL_BOOST = 40
export(int) var WALL_JUMP_HORIZONTAL_BOOST = RUN_MAX_SPEED + JUMP_HORIZONTAL_BOOST
export(int) var WALL_SLIDE_START_MAX = 20
export(int) var WALL_CHECK_DISTANCE = 3
export(int) var FALL_MAX_SPEED = 160
export(int) var FALL_MAX_ACCELERATION = 300
export(float) var AUTO_JUMP_TIMER = 0.1
export(int) var UPWARD_CORNER_CORRECTION = 4
export(float) var CEILING_VARIABLE_JUMP = 0.05
export(int) var FAST_FALL_MAX_SPEED = 240
export(int) var FAST_FALL_MAX_ACCELERATION = 300
export(int) var JETPACK_SPEED = 20
export(int) var BOUNCE_SPEED = - 140

var WALL_SLIDE_TIME = 1.2

var facing = RIGHT
var force_move_x_direction = NEUTRAL
var motion = Vector2.ZERO
var max_fall = FALL_MAX_SPEED
var variable_jump_speed = 0
var was_on_floor = false
var wall_slide_dir = NEUTRAL
var wall_slide_timer = WALL_SLIDE_TIME
var last_speed_y = 0

func _physics_process(delta: float):
	last_speed_y = motion.y
	
	var input_vector = get_input_vector()
	
	# if we did a walljump this timer is set
	# if the timer is still running we take away control
	# from the player and force them into that direction
	if force_move_x_timer.time_left > 0:
		input_vector.x = force_move_x_direction

	update_facing(input_vector)
	apply_horizontal_force(input_vector, delta)
	apply_vertical_force(input_vector, delta)
	move(input_vector)
	update_sprite(input_vector, delta)
	
func update_facing(input_vector: Vector2) -> void:
	var direction = sign(input_vector.x)
	facing = direction if direction != 0 else facing
	sprite.flip_h = true if facing == LEFT else false
	particles_spawn.position.x = 4 if facing == LEFT else -4
	
func get_input_vector():
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	return input_vector

func apply_horizontal_force(input_vector: Vector2, delta: float) -> void:
	var run_multiplier = 1.0 if is_on_floor() else AIR_MULTIPLIER
	
	if abs(motion.x) > RUN_MAX_SPEED and sign(motion.x) == input_vector.x:
		motion.x = move_toward(motion.x, input_vector.x * RUN_MAX_SPEED, RUN_FRICTION * run_multiplier * delta)
	else:
		motion.x = move_toward(motion.x, input_vector.x * RUN_MAX_SPEED, RUN_ACCELERATION * run_multiplier * delta)
	
func apply_vertical_force(input_vector: Vector2, delta: float) -> void:
	var fm = FALL_MAX_SPEED
	var ffm = FAST_FALL_MAX_SPEED
	
	# if we're pressing down, fall faster
	if input_vector.y == 1 and motion.y >= fm:
		max_fall = move_toward(max_fall, ffm, FAST_FALL_MAX_ACCELERATION * delta)
		var half = fm + (ffm - fm) * 0.5
		
		if motion.y >= half:
			var sprite_lerp = min(1, (motion.y - half) / (ffm - half))
			sprite.scale.x = lerp(1, 0.5, sprite_lerp)
			sprite.scale.y = lerp(1, 1.5, sprite_lerp)
	else:
		max_fall = move_toward(max_fall, fm, FAST_FALL_MAX_ACCELERATION * delta)
	
	if not is_on_floor():
		var maximum = max_fall
		
		if sign(motion.x) == facing and sign(input_vector.y) != 1:
			if motion.y >= 0 and wall_slide_timer > 0 and collide_check(facing):
				wall_slide_dir = facing
		
		# if we are wall sliding we want to fall a bit slower
		if wall_slide_dir != NEUTRAL:
			maximum = lerp(max_fall, WALL_SLIDE_START_MAX, wall_slide_timer / WALL_SLIDE_TIME)
	
	
		var fall_multiplier = 0.5 if abs(motion.y) < HALF_GRAVITY_THRESHOLD and Input.is_action_pressed("jump") else 1.0
		motion.y = move_toward(motion.y, maximum, GRAVITY * fall_multiplier * delta)
	
	if wall_slide_dir != NEUTRAL:
		wall_slide_timer = max(wall_slide_timer - delta, 0)
		wall_slide_dir = NEUTRAL
	
	if variable_jump_timer.time_left > 0:
		if Input.is_action_pressed("jump"):
			motion.y = min(motion.y, variable_jump_speed)
		else:
			variable_jump_timer.stop()
	
	if bounce_var_jump_timer.time_left > 0:
		motion.y = min(motion.y, variable_jump_speed)
	
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_jump_timer.time_left > 0:
			jump(input_vector)
		else:
			jump_buffer_timer.start()
			
			if can_wall_jump(RIGHT):
				wall_jump(LEFT)
			elif can_wall_jump(LEFT):
				wall_jump(RIGHT)
	
	if Input.is_action_pressed("jetpack"):
		motion.y -= JETPACK_SPEED

func jump(input_vector: Vector2, record_jump: bool = true) -> void:
	coyote_jump_timer.stop()
	variable_jump_timer.start()
	wall_slide_timer = WALL_SLIDE_TIME
	
	motion.x += input_vector.x * JUMP_HORIZONTAL_BOOST
	motion.y = JUMP_FORCE
	variable_jump_speed = motion.y
	
	sprite.scale = Vector2(0.6, 1.4)
	
	if record_jump:
		stats.jumped()
		jump_audio.play()
		create_dust()

func bounce(from_y):
	position.y = from_y
	coyote_jump_timer.stop()
	variable_jump_timer.start()
	bounce_var_jump_timer.start()
	jump_buffer_timer.start()
	wall_slide_timer = WALL_SLIDE_TIME
	
	motion.y = BOUNCE_SPEED
	variable_jump_speed = motion.y
	sprite.scale = Vector2(0.6, 1.4)
	
	stats.jumped()
	jump_audio.play()
	create_dust()

func wall_jump(direction: int) -> void:
	coyote_jump_timer.stop()
	variable_jump_timer.start()
	wall_slide_timer = WALL_SLIDE_TIME
	
	if sign(motion.x) != 0:
		force_move_x_direction = direction
#		force_move_x_timer.start()

	motion.x = direction * WALL_JUMP_HORIZONTAL_BOOST
	motion.y = JUMP_FORCE
	variable_jump_speed = motion.y
	
	sprite.scale = Vector2(0.6, 1.4)
	
	stats.jumped()
	jump_audio.play()
	
#	create_wall_dust(-direction)
	create_dust()
	
func move(input_vector: Vector2) -> void:
	var was_in_air = not is_on_floor()
	was_on_floor = is_on_floor()
	
	motion = move_and_slide(motion, Vector2.UP)
	
	if not was_on_floor and is_on_floor():
		var squish_amount = min(last_speed_y / FAST_FALL_MAX_SPEED, 1)
		sprite.scale.x = lerp(1, 1.6, squish_amount)
		sprite.scale.y = lerp(1, 0.4, squish_amount)

	
	if is_on_floor():
		wall_slide_timer = WALL_SLIDE_TIME
		coyote_jump_timer.start()
		
		if jump_buffer_timer.time_left > 0:
			jump_buffer_timer.stop()
			jump(input_vector)
			
	if is_on_ceiling():
		if motion.x <= 0:
			for i in range(1, UPWARD_CORNER_CORRECTION + 1):
				var candidate_position = Vector2(-i, -1)
				if not corner_check(candidate_position.x):
					position += candidate_position
					return
		if motion.x >= 0:
			for i in range(1, UPWARD_CORNER_CORRECTION + 1):
				var candidate_position = Vector2(i, -1)
				if not corner_check(candidate_position.x):
					position += candidate_position
					return

		if variable_jump_timer.time_left < variable_jump_timer.wait_time - CEILING_VARIABLE_JUMP:
			variable_jump_timer.stop()

func update_sprite(_input_vector: Vector2, delta: float) -> void:
	# Tween sprite scale back to 1
	sprite.scale.x = move_toward(sprite.scale.x, 1.0, 1.75 * delta)
	sprite.scale.y = move_toward(sprite.scale.y, 1.0, 1.75 * delta)

func can_wall_jump(direction: int) -> bool:
	return test_move(get_transform(), Vector2(WALL_CHECK_DISTANCE * direction, 0))
	
func collide_check(x: int = 0, y: int = 0) -> bool:
	return test_move(get_transform(), Vector2(x, y))

func corner_check(x: int) -> bool:
	return test_move(get_transform().translated(Vector2(x, 0)), Vector2.UP)

func update_camera(room):
	var collider = room.get_node("Collider")
	var size = collider.shape.extents * 2
	
	camera.limit_left = collider.global_position.x - size.x / 2
	camera.limit_top = collider.global_position.y - size.y / 2
	camera.limit_right = camera.limit_left + size.x
	camera.limit_bottom = camera.limit_top + size.y

func _on_RoomDetector_area_entered(room: Area2D):
	update_camera(room)

func _on_BirdDetector_area_entered(bird):
	if bird.is_in_group("bird"):
		bounce(bird.global_position.y)
		stats.bird()
		bird_audio.play()
		bird.queue_free()

func create_dust():
	var particles = global.instance_scene_on_main(Particles, particles_spawn.global_position)
	particles.scale.x = -1 if facing == LEFT else 1
	particles.emitting = true

func create_wall_dust(dir):
	var particles = global.instance_scene_on_main(ParticlesWall, Vector2(global_position.x + (2 * dir), global_position.y + 4))
	particles.scale.x = -1 if dir == LEFT else 1
	particles.emitting = true
	
