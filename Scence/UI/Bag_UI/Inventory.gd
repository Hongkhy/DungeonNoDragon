extends Node

signal inventory_changed

var coins := 1000
var hp_potions := 2
var buff_potions := 2

var hp_level := 0
var damage_level := 0
var speed_level := 0


func add_coins(amount:int):
	coins += amount
	inventory_changed.emit()

func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false

	coins -= amount
	inventory_changed.emit()
	return true


func add_hp_potion(amount:int = 1):
	hp_potions += amount
	inventory_changed.emit()


func add_buff_potion(amount:int = 1):
	buff_potions += amount
	inventory_changed.emit()


func use_hp_potion() -> bool:
	if hp_potions <= 0:
		return false

	hp_potions -= 1
	inventory_changed.emit()
	return true


func use_buff_potion() -> bool:
	if buff_potions <= 0:
		return false

	buff_potions -= 1
	inventory_changed.emit()
	return true
