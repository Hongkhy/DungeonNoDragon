extends Area2D

var player_inside := false

@onready var label = $Label

func _ready():
	label.visible = false

func _process(delta):

	if player_inside and Input.is_action_just_pressed("interact"):
		get_tree().change_scene_to_file("res://Scence/Map/Cave/level_red.tscn")


func _on_body_entered(body):

	if body.is_in_group("player"):
		player_inside = true
		label.visible = true


func _on_body_exited(body):

	if body.is_in_group("player"):
		player_inside = false
		label.visible = false
