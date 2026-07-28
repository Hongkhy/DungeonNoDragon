extends Area2D

@export_file("*.tscn") var shop_scene: String = "res://Scence/Map/Shop/shop.tscn"

@onready var prompt = $Label   # Remove this line if you don't have a Label

var player_in_range := false

func _ready():
	if prompt:
		prompt.hide()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		get_tree().change_scene_to_file(shop_scene)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		if prompt:
			prompt.show()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if prompt:
			prompt.hide()
