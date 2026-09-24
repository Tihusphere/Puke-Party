class_name PlayerController
extends CharacterBody3D

## Signals ##

signal can_stand

## States ##

enum PlayerState {
	WALKING,
	CRAWLING,
}

var player_state: PlayerState = PlayerState.WALKING

## Physics Variables ##

const WALK_SPEED := 5.0
const CRAWL_SPEED := 3.0
const JUMP_VELOCITY := 3.0

var speed: float = WALK_SPEED

## Player Nodes ##

@onready var walking_collision: CollisionShape3D = $StandingCollision
@onready var crawling_collision: CollisionShape3D = $CrawlingCollision
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ray_cast: RayCast3D = $RayCast3D

func detect_overhead_collision():
	if not ray_cast.is_colliding():
		can_stand.emit()

func change_player_state(state: PlayerState):
	match state:
		PlayerState.WALKING:
			if (player_state == PlayerState.CRAWLING):
				animation_player.play("CrawlingToStanding")
			walking_collision.set_disabled(false)
			crawling_collision.set_disabled(true)
			speed = WALK_SPEED
		PlayerState.CRAWLING:
			if (player_state == PlayerState.WALKING):
				animation_player.play("StandingToCrawling")
			walking_collision.set_disabled(true)
			crawling_collision.set_disabled(false)
			speed = CRAWL_SPEED
	player_state = state

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_pressed("crawl"):
		change_player_state(PlayerState.CRAWLING)
	if Input.is_action_just_released("crawl"):
		if ray_cast.is_colliding():
			await can_stand
		if not Input.is_action_pressed("crawl"):
			change_player_state(PlayerState.WALKING)

func move_in_direction():
	var input_direction := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_direction.x, 0.0, input_direction.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if player_state == PlayerState.CRAWLING:
		detect_overhead_collision()
	
	move_in_direction()
	move_and_slide()
