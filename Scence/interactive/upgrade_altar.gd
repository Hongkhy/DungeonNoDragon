extends Area2D

var player_inside := false

@onready var label = $Label

func _ready():
	label.visible = false

func _process(_delta):
	if !player_inside:
		return

	if Input.is_action_just_pressed("interact"):
		var menu = get_tree().current_scene.get_node("UpgradeMenu")
		menu.open()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true
		label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		label.visible = false
