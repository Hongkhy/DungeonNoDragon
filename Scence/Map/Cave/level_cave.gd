extends Node2D

# ======================================================
# SCENES
# ======================================================

@export var mob1_scene: PackedScene
@export var vampire_scene: PackedScene
@export var spider_scene: PackedScene

@export var coin_scene: PackedScene
@export var hp_potion_scene: PackedScene
@export var buff_potion_scene: PackedScene

# ======================================================
# MAP SETTINGS
# ======================================================

@export var map_width := 50
@export var map_height := 80

@export var room_count := 15
@export var room_min_size := 8
@export var room_max_size := 16

@export var mob_count := 15

@export var min_items := 5
@export var max_items := 10
# ======================================================
# NODES

@onready var boss_ui = $HUD/HPBar
# ======================================================

@onready var floor_layer = $FloorLayer
@onready var wall_layer = $WallLayer
@onready var player = $player

# HUD
@onready var hp_label = $HUD/Control/HPLabel
@onready var enemy_label = $HUD/Control/EnemyLabel
@onready var floor_label = $HUD/Control/FloorLabel


# ======================================================
# VARIABLES
# ======================================================

const TILE_SIZE := 16

var current_floor := 1
var enemies_alive := 0


var floor_cells: Array[Vector2i] = []
var wall_cells: Array[Vector2i] = []
var rooms = []


# ======================================================
# ROOM CLASS
# ======================================================

class Room:

	var x:int
	var y:int
	var w:int
	var h:int

	func _init(px, py, pw, ph):

		x = px
		y = py
		w = pw
		h = ph

	func center() -> Vector2i:

		return Vector2i(
			x + w / 2,
			y + h / 2
		)

	func intersects(other)->bool:

		return (
			x < other.x + other.w
			and x + w > other.x
			and y < other.y + other.h
			and y + h > other.y
		)


# ======================================================
# READY
# ======================================================

func _ready():
	randomize()

	player.health_changed.connect(update_hp_label)

	update_hp_label(player.health, player.max_health)
	update_floor_label()

	generate_dungeon()


# ======================================================
# NEXT FLOOR
# ======================================================

func next_floor():

	current_floor += 1

	update_floor_label()

	print("===================")
	print("Entering Floor ", current_floor)
	print("===================")

	generate_dungeon()


# ======================================================
# GENERATE DUNGEON
# ======================================================

func generate_dungeon():

	# Remove old enemies

	for child in get_children():

		if child.is_in_group("Enemy") or child.is_in_group("Item"):
			child.queue_free()


	floor_layer.clear()
	wall_layer.clear()

	floor_cells.clear()
	wall_cells.clear()
	rooms.clear()


	create_rooms()

	connect_rooms()

	generate_walls()

	draw_map()

	spawn_player()


	if current_floor < 5:
		spawn_mobs()
	else:
		spawn_boss()
		
	spawn_items()
# ======================================================
# CREATE ROOMS
# ======================================================

func create_rooms():

	for i in range(room_count):

		var w = randi_range(room_min_size, room_max_size)
		var h = randi_range(room_min_size, room_max_size)

		var x = randi_range(
			2,
			map_width - w - 2
		)

		var y = randi_range(
			2,
			map_height - h - 2
		)

		var new_room = Room.new(
			x,
			y,
			w,
			h
		)

		var overlaps = false

		for room in rooms:

			if new_room.intersects(room):
				overlaps = true
				break

		if overlaps:
			continue

		rooms.append(new_room)

		for rx in range(
			new_room.x,
			new_room.x + new_room.w
		):

			for ry in range(
				new_room.y,
				new_room.y + new_room.h
			):

				floor_cells.append(
					Vector2i(rx, ry)
				)


# ======================================================
# CONNECT ROOMS
# ======================================================

func connect_rooms():

	for i in range(rooms.size() - 1):

		var room_a = rooms[i]
		var room_b = rooms[i + 1]

		var start = room_a.center()
		var end = room_b.center()

		# Horizontal Corridor

		for x in range(
			min(start.x, end.x),
			max(start.x, end.x) + 1
		):

			for offset in range(-1, 2):

				floor_cells.append(
					Vector2i(x, start.y + offset)
				)

		# Vertical Corridor

		for y in range(
			min(start.y, end.y),
			max(start.y, end.y) + 1
		):

			for offset in range(-1, 2):

				floor_cells.append(
					Vector2i(end.x + offset, y)
				)


# ======================================================
# GENERATE WALLS
# ======================================================

func generate_walls():

	var dirs = [

		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN,

		Vector2i(-1,-1),
		Vector2i(1,-1),
		Vector2i(-1,1),
		Vector2i(1,1)
	]

	for floor in floor_cells:

		for dir in dirs:

			var pos = floor + dir

			if !floor_cells.has(pos):

				if !wall_cells.has(pos):

					wall_cells.append(pos)


# ======================================================
# DRAW MAP
# ======================================================

func draw_map():

	floor_layer.set_cells_terrain_connect(

		floor_cells,
		0,
		0
	)

	for wall in wall_cells:

		wall_layer.set_cell(

			wall,
			0,
			Vector2i(1,4)
		)


# ======================================================
# PLAYER SPAWN
# ======================================================

func spawn_player():

	if rooms.is_empty():
		return

	var room = rooms.pick_random()

	var pos = room.center()

	player.global_position = Vector2(

		pos.x * TILE_SIZE + TILE_SIZE / 2,
		pos.y * TILE_SIZE + TILE_SIZE / 2
	)


# ======================================================
# SPAWN ENEMIES
# ======================================================

func spawn_mobs():

	enemies_alive = 0

	var mob_scenes = []

	match current_floor:

		1:
			mob_count = 10
			mob_scenes = [
				mob1_scene
			]

		2:
			mob_count = 15
			mob_scenes = [
				mob1_scene,
				vampire_scene
			]

		3:
			mob_count = 20
			mob_scenes = [
				vampire_scene
			]

		4:
			mob_count = 25
			mob_scenes = [
				vampire_scene
			]

	update_enemy_label()

	for i in range(mob_count):

		var room = rooms.pick_random()

		if room == null:
			continue

		var x = randi_range(
			room.x + 1,
			room.x + room.w - 2
		)

		var y = randi_range(
			room.y + 1,
			room.y + room.h - 2
		)

		var mob_scene = mob_scenes.pick_random()

		if mob_scene == null:
			continue

		var mob = mob_scene.instantiate()

		mob.global_position = Vector2(
			x * TILE_SIZE + TILE_SIZE / 2,
			y * TILE_SIZE + TILE_SIZE / 2
		)

		mob.add_to_group("Enemy")

		# Listen for enemy death
		mob.died.connect(enemy_defeated)

		add_child(mob)

		enemies_alive += 1

	update_enemy_label()

	print("Enemies Alive:", enemies_alive)


# ======================================================
# SPAWN BOSS
# ======================================================

#func spawn_boss():
#
	#enemies_alive = 1
#
	#update_enemy_label()
#
	#if rooms.is_empty():
		#return
#
	#var room = rooms.pick_random()
#
	#var boss = spider_scene.instantiate()
#
	#var pos = room.center()
#
	#boss.global_position = Vector2(
		#pos.x * TILE_SIZE + TILE_SIZE / 2,
		#pos.y * TILE_SIZE + TILE_SIZE / 2
	#)
#
	#boss.add_to_group("Enemy")
#
	#boss.died.connect(enemy_defeated)
#
	#add_child(boss)
#
	#print("Boss Spawned")

func spawn_boss():
	enemies_alive = 1
	update_enemy_label()

	if rooms.is_empty():
		return

	var room = rooms.pick_random()
	var boss = spider_scene.instantiate()

	var pos = room.center()
	boss.global_position = Vector2(
		pos.x * TILE_SIZE + TILE_SIZE / 2,
		pos.y * TILE_SIZE + TILE_SIZE / 2
	)

	boss.add_to_group("Enemy")
	boss.died.connect(enemy_defeated)

	add_child(boss)
	if boss.has_method("set_boss_ui"):
		boss.set_boss_ui(boss_ui)
	# Give the boss a reference to the UI
	if boss.has_method("set_boss_ui"):
		boss.set_boss_ui(boss_ui)

	print("Boss Spawned")
	
# ======================================================
# ENEMY DIED
# ======================================================

func enemy_defeated():

	enemies_alive -= 1

	update_enemy_label()

	print("Enemies Left:", enemies_alive)

	if enemies_alive > 0:
		return

	# Boss Floor Finished
	if current_floor >= 5:

		print("Dungeon Cleared!")

		$HUD.show_victory()

		return
		# Next Floor

	await get_tree().create_timer(1.0).timeout

	next_floor()
	
	# ======================================================
# HUD UPDATE
# ======================================================

func update_enemy_label():

	enemy_label.text = "Enemies Left : " + str(enemies_alive)


func update_hp_label(current_hp, max_hp):

	hp_label.text = "HP : " + str(current_hp) + " / " + str(max_hp)


func update_floor_label():

	floor_label.text = "Floor : " + str(current_floor)
	
	
func spawn_items():

	if rooms.is_empty():
		return

	var item_scenes = [
		coin_scene,
		coin_scene,
		coin_scene,
		coin_scene, # More common
		hp_potion_scene,
		buff_potion_scene
	]

	var item_count = randi_range(min_items, max_items)

	for i in range(item_count):

		var room = rooms.pick_random()

		if room == null:
			continue

		var x = randi_range(room.x + 1, room.x + room.w - 2)
		var y = randi_range(room.y + 1, room.y + room.h - 2)

		var item_scene = item_scenes.pick_random()

		if item_scene == null:
			continue

		var item = item_scene.instantiate()

		item.global_position = Vector2(
			x * TILE_SIZE + TILE_SIZE / 2,
			y * TILE_SIZE + TILE_SIZE / 2
		)

		item.add_to_group("Item")

		add_child(item)
