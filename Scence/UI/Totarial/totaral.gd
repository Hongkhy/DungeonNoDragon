extends CanvasLayer

func _ready():
	if GameData.tutorial_shown:
		queue_free()
		return

	GameData.tutorial_shown = true

	$Control/Label.text = """
CONTROLS

↑ ↓ ← →   Move

SPACE      Attack

B          Open Bag

Press ENTER to continue.
"""

	get_tree().paused = true


func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		get_tree().paused = false
		queue_free()


func _exit_tree():
	get_tree().paused = false
