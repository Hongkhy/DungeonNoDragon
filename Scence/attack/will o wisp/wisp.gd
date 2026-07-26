extends Area2D

@export var speed := 50.0
@export var damage := 2
@export var lifetime := 5.0

var direction := Vector2.ZERO
var hit := false
var shooter: Node = null
func _ready() -> void:
	monitoring = true
	monitorable = true

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	await get_tree().create_timer(lifetime).timeout
	if is_inside_tree():
		queue_free()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	_try_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)

func _try_hit(target: Node) -> void:
	if hit:
		return

	# Ignore the vampire that fired this projectile
	if target == shooter:
		return

	if target.is_in_group("player"):
		if target.has_method("take_damage"):
			target.take_damage(damage)

		hit = true
		queue_free()
