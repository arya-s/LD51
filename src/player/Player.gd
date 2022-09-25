extends KinematicBody2D

enum {
	LEFT = -1,
	NEUTRAL = 0,
	RIGHT = 1
}

onready var label = $Label

# timers
onready var coyote_jump_timer = $CoyoteJumpTimer
onready var variable_jump_timer = $VariableJumpTimer
onready var jump_buffer_timer = $JumpBufferTimer

# raycasts
onready var wall_horizontal_ray_casts = $WallHorizontalRayCasts
onready var collider_horizontal_ray_casts = $ColliderHorizontalRayCasts

# player
onready var sprite = $Sprite

export(float) var AIR_MULTIPLIER = 0.65
export(int) var GRAVITY = 900
export(int) var HALF_GRAVITY_THRESHOLD = 40
export(int) var RUN_ACCELERATION = 1000
export(int) var RUN_FRICTION = 400
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
export(int) var CEILING_VARIABLE_JUMP = 0.05


var WALL_SLIDE_TIME = 1.2

var facing = NEUTRAL
var motion = Vector2.ZERO
var max_fall = FALL_MAX_SPEED
var variable_jump_speed = 0
var was_in_air = false
var was_on_floor = false
var wall_slide_dir = NEUTRAL
var wall_slide_timer = WALL_SLIDE_TIME

func _process(delta):
	update_sprite(delta)

func _physics_process(delta: float):
#	label.text = str(position)
	var input_vector = get_input_vector()
	facing = get_facing(input_vector)

	apply_horizontal_force(input_vector, delta)
	apply_vertical_force(input_vector, delta)
	move(input_vector)
	
func get_facing(input_vector: Vector2) -> int:
	var direction = sign(input_vector.x)
	return direction if direction != 0 else facing
	
func get_input_vector():
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	
	return input_vector

func apply_horizontal_force(input_vector: Vector2, delta: float) -> void:
	var run_multiplier = 1.0 if is_on_floor() else AIR_MULTIPLIER
	
	if abs(motion.x) > RUN_MAX_SPEED and sign(motion.x) == input_vector.x:
		motion.x = move_toward(motion.x, input_vector.x * RUN_MAX_SPEED, RUN_FRICTION * run_multiplier * delta)
	else:
		motion.x = move_toward(motion.x, input_vector.x * RUN_MAX_SPEED, RUN_ACCELERATION * run_multiplier * delta)
	
func apply_vertical_force(input_vector: Vector2, delta: float) -> void:
	if not is_on_floor():
		max_fall = move_toward(max_fall, FALL_MAX_SPEED, FALL_MAX_ACCELERATION * delta)
		
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
	
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_jump_timer.time_left > 0:
			jump(input_vector)
		else:
			jump_buffer_timer.start()
			
			if can_wall_jump(RIGHT):
				wall_jump(LEFT)
			elif can_wall_jump(LEFT):
				wall_jump(RIGHT)

func jump(input_vector: Vector2) -> void:
	coyote_jump_timer.stop()
	variable_jump_timer.start()
	wall_slide_timer = WALL_SLIDE_TIME
	
	motion.x += input_vector.x * JUMP_HORIZONTAL_BOOST
	motion.y = JUMP_FORCE
	variable_jump_speed = motion.y
	
	sprite.scale = Vector2(0.6, 1.4)

func wall_jump(direction: int) -> void:
	coyote_jump_timer.stop()
	variable_jump_timer.start()
	wall_slide_timer = WALL_SLIDE_TIME
	
	motion.x = direction * WALL_JUMP_HORIZONTAL_BOOST
	motion.y = JUMP_FORCE
	variable_jump_speed = motion.y
	
	sprite.scale = Vector2(0.6, 1.4)
	
func move(input_vector: Vector2) -> void:
	was_on_floor = is_on_floor()
	
	motion = move_and_slide(motion, Vector2.UP)

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

func update_sprite(delta: float) -> void:
	# Tween sprite scale back to 1
	sprite.scale.x = move_toward(sprite.scale.x, 1.0, 1.75 * delta)
	sprite.scale.y = move_toward(sprite.scale.y, 1.0, 1.75 * delta)

func can_wall_jump(direction: int) -> bool:
	return test_move(get_transform(), Vector2(WALL_CHECK_DISTANCE * direction, 0))
	
func collide_check(x: int, y: int = 0) -> bool:
	return test_move(get_transform(), Vector2(x, y))

func corner_check(x: int) -> bool:
	return test_move(get_transform().translated(Vector2(x, 0)), Vector2.UP)
