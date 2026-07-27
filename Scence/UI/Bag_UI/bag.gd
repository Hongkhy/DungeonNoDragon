extends CanvasLayer
@onready var coin_amount = $Control/Coinslot/Amount

@onready var hp_slot = $Control/GridContainer/HP_Potion
@onready var buff_slot = $Control/GridContainer/Buff_Potion

@onready var hp_amount = $Control/GridContainer/HP_Potion/AmountLabel
@onready var buff_amount = $Control/GridContainer/Buff_Potion/AmountLabel

@onready var item_name = $Control/DescriptionPanel/VBoxContainer/Itemname
@onready var item_description = $Control/DescriptionPanel/VBoxContainer/ItemDescription

@onready var close_button = $Control/Close
@onready var use_button = $Control/DescriptionPanel/VBoxContainer/Use

var selected_item := ""

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	hide()
	update_ui()

	hp_slot.pressed.connect(_on_hp_pressed)
	buff_slot.pressed.connect(_on_buff_pressed)
	close_button.pressed.connect(close_bag)
	use_button.pressed.connect(_on_use_pressed)
	use_button.hide()

func update_ui():
	coin_amount.text = str(Inventory.coins)
	hp_amount.text = "x%d" % Inventory.hp_potions
	buff_amount.text = "x%d" % Inventory.buff_potions

func open_bag():
	update_ui()
	visible = true
	get_tree().paused = true

func close_bag():
	print("close_bag called")
	get_tree().paused = false
	visible = false


func _on_hp_pressed():
	selected_item = "hp"
	item_name.text = "Health Potion"
	item_description.text = "Restore 50 HP.\n\nQuantity: %d" % Inventory.hp_potions
	use_button.show()

func _on_buff_pressed():
	selected_item = "buff"
	item_name.text = "Boost Potion"
	item_description.text = "Gain a random attribute boost for 30 seconds.\n\nQuantity: %d" % Inventory.buff_potions
	use_button.show()

func _on_use_pressed():

	var player = get_tree().get_first_node_in_group("player")

	if player == null:
		print("No player found!")
		return

	match selected_item:

		"hp":
			if Inventory.use_hp_potion():
				player.heal(50)

		"buff":
			if Inventory.use_buff_potion():
				player.apply_random_buff()

	update_ui()

	if selected_item == "hp" and Inventory.hp_potions <= 0:
		use_button.hide()
	elif selected_item == "buff" and Inventory.buff_potions <= 0:
		use_button.hide()

func _on_use_buff_potion() -> void:
	pass # Replace with function body.


func _on_use_hp_potion() -> void:
	pass # Replace with function body.
