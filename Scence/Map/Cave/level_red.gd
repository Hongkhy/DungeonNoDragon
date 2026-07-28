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
# MAP SETTINGS (Made Much Bigger!)
# ======================================================
@export var map_width := 120
@export var map_height := 120

@export var room_count := 30
@export var room_min_size := 8
@export var room_max_size := 18

@export var min_items := 8
@export var max_items := 15

# ======================================================
# NODES
# ======================================================
@onready var boss_ui = $HUD/HPBar
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
var mob_count := 15

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
		return Vector2i(x + w / 2, y + h / 2)

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
	# Remove old enemies and items
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
	spawn_items()

	# Spawn a Boss every 5th floor, otherwise spawn normal mobs
	if current_floor % 5 == 0:
		spawn_boss()
	else:
		spawn_mobs()
		
# ======================================================
# CREATE ROOMS
# ======================================================
func create_rooms():
	for i in range(room_count):
		var w = randi_range(room_min_size, room_max_size)
		var h = randi_range(room_min_size, room_max_size)

		var x = randi_range(2, map_width - w - 2)
		var y = randi_range(2, map_height - h - 2)

		var new_room = Room.new(x, y, w, h)
		var overlaps = false

		for room in rooms:
			if new_room.intersects(room):
				overlaps = true
				break

		if overlaps:
			continue

		rooms.append(new_room)

		for rx in range(new_room.x, new_room.x + new_room.w):
			for ry in range(new_room.y, new_room.y + new_room.h):
				floor_cells.append(Vector2i(rx, ry))

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
		for x in range(min(start.x, end.x), max(start.x, end.x) + 1):
			for offset in range(-1, 2):
				floor_cells.append(Vector2i(x, start.y + offset))

		# Vertical Corridor
		for y in range(min(start.y, end.y), max(start.y, end.y) + 1):
			for offset in range(-1, 2):
				floor_cells.append(Vector2i(end.x + offset, y))

# ======================================================
# GENERATE WALLS
# ======================================================
func generate_walls():
	var dirs = [
		Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
		Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(1,1)
	]

	# Optimized by turning floor_cells into a Dictionary lookup for speed
	var floor_dict = {}
	for cell in floor_cells:
		floor_dict[cell] = true

	var wall_dict = {}

	for floor_cell in floor_cells:
		for dir in dirs:
			var pos = floor_cell + dir
			
			if not floor_dict.has(pos) and not wall_dict.has(pos):
				wall_dict[pos] = true
				wall_cells.append(pos)

# ======================================================
# DRAW MAP
# ======================================================
func draw_map():
	# Draw all floors at once
	floor_layer.set_cells_terrain_connect(floor_cells, 0, 0)

	# Draw all walls
	for wall in wall_cells:
		wall_layer.set_cell(wall, 0, Vector2i(1,4))

# ======================================================
# PLAYER SPAWN
# ======================================================
func spawn_player():
	if rooms.is_empty():
		return

	var room = rooms[0] # Always spawn in the very first generated room
	var pos = room.center()

	player.global_position = Vector2(
		pos.x * TILE_SIZE + TILE_SIZE / 2,
		pos.y * TILE_SIZE + TILE_SIZE / 2
	)

# ======================================================
# SPAWN ENEMIES (Endless Scaling)
# ======================================================
func spawn_mobs():
	enemies_alive = 0

	var mob_scenes = [mob1_scene]
	
	# Add tougher enemies to the pool as you get deeper
	if current_floor >= 2:
		mob_scenes.append(vampire_scene)
	if current_floor >= 4:
		mob_scenes.append(spider_scene)

	# Scale up the number of enemies infinitely based on the floor
	mob_count = 10 + (current_floor * 3)

	for i in range(mob_count):
		if rooms.is_empty():
			continue
			
		var room = rooms.pick_random()
		var x = randi_range(room.x + 1, room.x + room.w - 2)
		var y = randi_range(room.y + 1, room.y + room.h - 2)

		var mob_scene = mob_scenes.pick_random()
		if mob_scene == null:
			continue

		var mob = mob_scene.instantiate()
		mob.global_position = Vector2(
			x * TILE_SIZE + TILE_SIZE / 2,
			y * TILE_SIZE + TILE_SIZE / 2
		)

		mob.add_to_group("Enemy")
		mob.died.connect(enemy_defeated)
		
		# Optional: Scale mob health infinitely here
		if "max_health" in mob:
			mob.max_health = int(mob.max_health * (1.0 + (current_floor * 0.1)))
			mob.health = mob.max_health

		add_child(mob)
		enemies_alive += 1

	update_enemy_label()
	print("Enemies Alive:", enemies_alive)

# ======================================================
# SPAWN BOSS (Every 5 Floors)
# ======================================================
func spawn_boss():
	enemies_alive = 1
	update_enemy_label()

	if rooms.is_empty():
		return

	# Boss gets its own room (usually the furthest one)
	var room = rooms[rooms.size() - 1] 
	var boss = spider_scene.instantiate()

	var pos = room.center()
	boss.global_position = Vector2(
		pos.x * TILE_SIZE + TILE_SIZE / 2,
		pos.y * TILE_SIZE + TILE_SIZE / 2
	)

	boss.add_to_group("Enemy")
	boss.died.connect(enemy_defeated)
	
	# Optional: Scale boss health infinitely
	if "max_health" in boss:
		boss.max_health = int(boss.max_health * (1.0 + (current_floor * 0.2)))
		boss.health = boss.max_health

	if boss.has_method("set_boss_ui"):
		boss.set_boss_ui(boss_ui)

	add_child(boss)
	print("Boss Spawned on Floor", current_floor)
	
# ======================================================
# ENEMY DIED (Infinite Loop)
# ======================================================
func enemy_defeated():
	enemies_alive -= 1
	update_enemy_label()

	print("Enemies Left:", enemies_alive)

	if enemies_alive > 0:
		return

	# Proceed to the next floor automatically when everything is dead
	print("Floor Cleared!")
	await get_tree().create_timer(1.0).timeout
	next_floor()

# ======================================================
# HUD UPDATE
# ======================================================
func update_enemy_label():
	if enemy_label:
		enemy_label.text = "Enemies Left : " + str(enemies_alive)

func update_hp_label(current_hp, max_hp):
	if hp_label:
		hp_label.text = "HP : " + str(current_hp) + " / " + str(max_hp)

func update_floor_label():
	if floor_label:
		floor_label.text = "Floor : " + str(current_floor)
	
# ======================================================
# SPAWN ITEMS
# ======================================================
func spawn_items():
	if rooms.is_empty():
		return

	var item_scenes = [
		coin_scene,
		coin_scene,
		coin_scene,
		coin_scene,
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
