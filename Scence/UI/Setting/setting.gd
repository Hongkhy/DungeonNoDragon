extends Control

@export var scroll_speed := 40.0
@export var end_position := -450.0
@export var menu_scene := "res://Scence/UI/Menu/main_menu.tscn"

@onready var credits = $Credits

func _ready():
	$VideoStreamPlayer.play()
	# Start the credits below the screen
	credits.position.y = get_viewport_rect().size.y

func _process(delta):
	credits.position.y -= scroll_speed * delta

	if credits.position.y <= end_position:
		_return_to_menu()

func _input(event):
	if event.is_action_pressed("ui_accept") \
	or event.is_action_pressed("ui_cancel"):
		_return_to_menu()

func _return_to_menu():
	get_tree().change_scene_to_file(menu_scene)
