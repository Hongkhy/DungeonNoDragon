extends CanvasLayer

@onready var coin_label = $Panel/VBoxContainer/CoinLabel

# HP
@onready var hp_level_label = $Panel/VBoxContainer/HPRow/HPLevelLabel
@onready var hp_cost_label = $Panel/VBoxContainer/HPRow/HPCostLabel
@onready var hp_button = $Panel/VBoxContainer/HPRow/HPButton

# Damage
@onready var damage_level_label = $Panel/VBoxContainer/DamageRow/DamageLevelLabel
@onready var damage_cost_label = $Panel/VBoxContainer/DamageRow/DamageCostLabel
@onready var damage_button = $Panel/VBoxContainer/DamageRow/DamageButton

# Speed
@onready var speed_level_label = $Panel/VBoxContainer/SpeedRow/SpeedLevelLabel
@onready var speed_cost_label = $Panel/VBoxContainer/SpeedRow/SpeedCostLabel
@onready var speed_button = $Panel/VBoxContainer/SpeedRow/SpeedButton


func _ready():
	visible = false
	Inventory.inventory_changed.connect(update_ui)
	update_ui()


func open():
	visible = true
	get_tree().paused = true
	update_ui()


func close():
	visible = false
	get_tree().paused = false


func update_ui():
	coin_label.text = "Coins: %d" % Inventory.coins

	# ---------- HP ----------
	var hp_cost = (Inventory.hp_level + 1) * 100

	hp_level_label.text = "Lv.%d" % Inventory.hp_level
	hp_cost_label.text = "Cost: %d" % hp_cost
	hp_button.disabled = Inventory.coins < hp_cost

	# ---------- Damage ----------
	var damage_cost = (Inventory.damage_level + 1) * 100

	damage_level_label.text = "Lv.%d" % Inventory.damage_level
	damage_cost_label.text = "Cost: %d" % damage_cost
	damage_button.disabled = Inventory.coins < damage_cost

	# ---------- Speed ----------
	var speed_cost = (Inventory.speed_level + 1) * 100

	speed_level_label.text = "Lv.%d" % Inventory.speed_level
	speed_cost_label.text = "Cost: %d" % speed_cost
	speed_button.disabled = Inventory.coins < speed_cost


func _on_hp_button_pressed():
	var hp_cost = (Inventory.hp_level + 1) * 100

	if Inventory.spend_coins(hp_cost):
		Inventory.hp_level += 1

		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.apply_upgrades()

		Inventory.inventory_changed.emit()


func _on_damage_button_pressed():
	var damage_cost = (Inventory.damage_level + 1) * 100

	if Inventory.spend_coins(damage_cost):
		Inventory.damage_level += 1

		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.apply_upgrades()

		Inventory.inventory_changed.emit()


func _on_speed_button_pressed():
	var speed_cost = (Inventory.speed_level + 1) * 100

	if Inventory.spend_coins(speed_cost):
		Inventory.speed_level += 1

		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.apply_upgrades()

		Inventory.inventory_changed.emit()


func _on_close_button_pressed():
	close()
