extends CharacterBody2D

signal health_changed(current_health, max_health)

@export var speed := 120.0
@export var max_health := 100
@export var damage := 100

var health := max_health



enum State {
	ALIVE,
	DEAD
}

var current_state = State.ALIVE

@onready var sprite = $AnimatedSprite2D

var is_attacking = false
var facing_direction = Vector2.DOWN
var facing_name = "down"


func _ready():
	apply_upgrades()

func apply_upgrades():
	var old_max = max_health

	max_health = 100 + (Inventory.hp_level * 20)
	damage = 100 + (Inventory.damage_level * 10)
	speed = 120 + (Inventory.speed_level * 5)

	health += max_health - old_max
	health_changed.emit(health, max_health)


	
func _on_use_hp_potion():
	heal(50)
func _physics_process(_delta):

	if current_state == State.DEAD:
		return

	if is_attacking:
		move_and_slide()
		return

	var input_dir = Vector2.ZERO

	input_dir.x = Input.get_axis("ui_left", "ui_right")
	input_dir.y = Input.get_axis("ui_up", "ui_down")

	input_dir = input_dir.normalized()

	if input_dir != Vector2.ZERO:
		facing_direction = input_dir

	velocity = input_dir * speed

	if Input.is_action_just_pressed("attack"):
		attack()
	else:
		update_animation(input_dir)

	move_and_slide()


func update_animation(direction):

	if direction == Vector2.ZERO:

		if abs(facing_direction.x) > abs(facing_direction.y):

			if facing_direction.x > 0:
				facing_name = "right"
				sprite.flip_h = false
				sprite.play("idle_right")
			else:
				facing_name = "left"
				sprite.flip_h = true
				sprite.play("idle_right")

		else:

			sprite.flip_h = false

			if facing_direction.y > 0:
				facing_name = "down"
				sprite.play("idle_down")
			else:
				facing_name = "up"
				sprite.play("idle_up")

		return

	# WALKING
	if abs(direction.x) > abs(direction.y):

		if direction.x > 0:
			facing_name = "right"
			sprite.flip_h = false
			sprite.play("walk_right")
		else:
			facing_name = "left"
			sprite.flip_h = true
			sprite.play("walk_right")

	else:

		sprite.flip_h = false

		if direction.y > 0:
			facing_name = "down"
			sprite.play("walk_down")
		else:
			facing_name = "up"
			sprite.play("walk_up")


func update_attack_area():

	match facing_name:

		"right":
			$AttackArea.position = Vector2(10, 0)

		"left":
			$AttackArea.position = Vector2(-10, 0)

		"up":
			$AttackArea.position = Vector2(0, -10)

		"down":
			$AttackArea.position = Vector2(0, 10)


func attack():

	if is_attacking:
		return

	update_attack_area()

	is_attacking = true
	velocity = Vector2.ZERO

	if abs(facing_direction.x) > abs(facing_direction.y):
		if facing_direction.x > 0:
			sprite.flip_h = false
			sprite.play("attack_right")
		else:
			sprite.flip_h = true
			sprite.play("attack_right")
	else:
		sprite.flip_h = false
		if facing_direction.y > 0:
			sprite.play("attack_down")
		else:
			sprite.play("attack_up")

	# Hitbox becomes active slightly after the animation starts
	await get_tree().create_timer(0.08).timeout
	$AttackArea.monitoring = true

	# Hitbox only stays active briefly
	await get_tree().create_timer(0.10).timeout
	$AttackArea.monitoring = false

	# Player regains control before the animation fully ends
	await get_tree().create_timer(0.10).timeout
	is_attacking = false


func _on_attack_area_body_entered(body):

	print("----------------")
	print("Hit:", body.name)
	print("Groups:", body.get_groups())
	print("Is attacking:", is_attacking)

	if not is_attacking:
		return

	if body.is_in_group("enemy"):
		print("Enemy damaged!")
		body.take_damage(damage)


func _on_animated_sprite_2d_animation_finished():
	pass


func take_damage(amount):

	if current_state == State.DEAD:
		return

	health -= amount

	emit_signal("health_changed", health, max_health)

	print("Player HP:", health)

	if health <= 0:
		die()
		
func heal(amount:int):

	if current_state == State.DEAD:
		return

	health = min(health + amount, max_health)

	emit_signal("health_changed", health, max_health)

	print("Player healed:", health)

func apply_random_buff():
	var buff = randi_range(0, 2)

	match buff:
		0:
			speed += 50
			print("Buff: Speed +50!")

		1:
			damage += 20
			print("Buff: Damage +20!")

		2:
			heal(50)
			print("Buff: Heal 50 HP!")

func die():

	if current_state == State.DEAD:
		return

	current_state = State.DEAD

	print("PLAYER DIED")

	var hud = get_parent().get_node("HUD")
	hud.show_game_over()

	hide()

	set_physics_process(false)

	$CollisionShape2D.set_deferred("disabled", true)

func _input(event):
	if event.is_action_pressed("bag"):
		if Bag.visible:
			Bag.close_bag()
		else:
			Bag.open_bag()
