extends Node2D

# =========================
# Endless Red Dungeon
# =========================

const TILE_SIZE := 16
const BOSS_INTERVAL := 5

# Enemy Scaling
const HEALTH_SCALE := 0.05
const DAMAGE_SCALE := 0.10
const SPEED_SCALE := 2.0

# Dungeon Generation
@export var width := 100
@export var height := 100
@export var room_count := 15
@export var min_room_size := 6
@export var max_room_size := 12

# Enemy Scenes
@export var mob1_scene: PackedScene
@export var vampire_scene: PackedScene
@export var spider_scene: PackedScene
@export var boss_scene: PackedScene

# Items
@export var hp_potion_scene: PackedScene
@export var buff_potion_scene: PackedScene
@export var min_items := 2
@export var max_items := 4

# TileMap
@onready var ground = $FloorLayer
@onready var wall = $WallLayer

# UI
@onready var floor_label = $HUD/Control/FloorLabel
@onready var enemy_label = $HUD/Control/EnemyLabel
@onready var hp_label = $HUD/Control/HPLabel
@onready var boss_ui = $BossUI

# Dungeon Data
var dungeon := []
var rooms := []

# Endless Progression
var current_floor := 1
var enemies_alive := 0
var mob_count := 0

# Random Generator
var rng := RandomNumberGenerator.new()


func _ready():

	rng.randomize()

	update_floor_label()

	generate_dungeon()
	
	
	print(ground)
	print(wall)
# =====================================================
# Floor Management
# =====================================================

func next_floor():

	current_floor += 1

	update_floor_label()

	clear_old_floor()

	generate_dungeon()


func clear_old_floor():

	rooms.clear()
	dungeon.clear()

	ground.clear()
	wall.clear()

	for child in get_children():

		if child.is_in_group("Enemy"):
			child.queue_free()

		elif child.is_in_group("Item"):
			child.queue_free()


func generate_dungeon():

	generate_rooms()

	connect_rooms()

	draw_map()

	spawn_items()

	if current_floor % BOSS_INTERVAL == 0:
		spawn_boss()
	else:
		spawn_mobs()
		
# =====================================================
# Room Generation
# =====================================================

func generate_rooms():

	rooms.clear()

	for i in range(room_count):

		var w = rng.randi_range(min_room_size, max_room_size)
		var h = rng.randi_range(min_room_size, max_room_size)

		var x = rng.randi_range(1, width - w - 1)
		var y = rng.randi_range(1, height - h - 1)

		var new_room = Rect2i(x, y, w, h)

		var overlaps := false

		for room in rooms:
			if room.intersects(new_room):
				overlaps = true
				break

		if overlaps:
			continue

		rooms.append(new_room)
		
# =====================================================
# Corridor Generation
# =====================================================

func connect_rooms():

	if rooms.size() < 2:
		return

	rooms.sort_custom(func(a, b): return a.position.x < b.position.x)

	for i in range(rooms.size() - 1):

		var room_a = rooms[i]
		var room_b = rooms[i + 1]

		var start = room_a.get_center()
		var end = room_b.get_center()

		carve_corridor(start, end)


func carve_corridor(start: Vector2i, end: Vector2i):

	var x = start.x
	var y = start.y

	while x != end.x:
		x += sign(end.x - x)
		dungeon.append(Vector2i(x, y))

	while y != end.y:
		y += sign(end.y - y)
		dungeon.append(Vector2i(x, y))


# =====================================================
# Draw Dungeon
# =====================================================

func draw_map():

	ground.clear()
	wall.clear()

	# Fill with walls
	for x in range(width):
		for y in range(height):
			wall.set_cell(0, Vector2i(x, y), 0, Vector2i.ZERO)

	# Carve rooms
	for room in rooms:

		for x in range(room.position.x, room.position.x + room.size.x):
			for y in range(room.position.y, room.position.y + room.size.y):

				var cell = Vector2i(x, y)

				wall.erase_cell(0, cell)
				ground.set_cell(0, cell, 0, Vector2i.ZERO)

	# Carve corridors
	for cell in dungeon:

		wall.erase_cell(0, cell)
		ground.set_cell(0, cell, 0, Vector2i.ZERO)

# =====================================================
# Item Spawning
# =====================================================

func spawn_items():

	if hp_potion_scene == null and buff_potion_scene == null:
		return

	var item_count = rng.randi_range(min_items, max_items)

	for i in range(item_count):

		if rooms.is_empty():
			return

		var room = rooms.pick_random()

		var x = rng.randi_range(
			room.position.x + 1,
			room.position.x + room.size.x - 2
		)

		var y = rng.randi_range(
			room.position.y + 1,
			room.position.y + room.size.y - 2
		)

		var item: Node2D

		if rng.randi_range(0, 1) == 0:
			if hp_potion_scene == null:
				continue
			item = hp_potion_scene.instantiate()
		else:
			if buff_potion_scene == null:
				continue
			item = buff_potion_scene.instantiate()

		item.global_position = Vector2(
			x * TILE_SIZE + TILE_SIZE / 2,
			y * TILE_SIZE + TILE_SIZE / 2
		)

		item.add_to_group("Item")

		add_child(item)

# =====================================================
# Enemy Spawning
# =====================================================

func spawn_mobs():

	enemies_alive = 0

	var mob_scenes = []

	# Floor progression
	if current_floor < 10:

		mob_scenes = [
			mob1_scene,
			vampire_scene
		]

	elif current_floor < 20:

		mob_scenes = [
			mob1_scene,
			vampire_scene,
			spider_scene
		]

	else:

		mob_scenes = [
			mob1_scene,
			vampire_scene,
			spider_scene
		]

	# Increase enemy count every floor
	mob_count = 3 + int(current_floor / 2)

	update_enemy_label()

	for i in range(mob_count):

		if rooms.is_empty():
			break

		var room = rooms.pick_random()

		var x = rng.randi_range(
			room.position.x + 1,
			room.position.x + room.size.x - 2
		)

		var y = rng.randi_range(
			room.position.y + 1,
			room.position.y + room.size.y - 2
		)

		var mob = mob_scenes.pick_random().instantiate()

		mob.global_position = Vector2(
			x * TILE_SIZE + TILE_SIZE / 2,
			y * TILE_SIZE + TILE_SIZE / 2
		)

		mob.add_to_group("Enemy")

		# ===========================
		# Endless Scaling
		# ===========================

		mob.max_health = int(
			mob.max_health * (1.0 + current_floor * HEALTH_SCALE)
		)

		mob.health = mob.max_health

		mob.damage = int(
			mob.damage * (1.0 + current_floor * DAMAGE_SCALE)
		)

		mob.speed += current_floor * SPEED_SCALE

		mob.died.connect(enemy_defeated)

		add_child(mob)

		enemies_alive += 1

	update_enemy_label()

	print("Spawned ", enemies_alive, " enemies.")
	

# =====================================================
# Boss Spawning
# =====================================================

func spawn_boss():

	enemies_alive = 1

	update_enemy_label()

	if rooms.is_empty():
		return

	var room = rooms.pick_random()

	var boss = boss_scene.instantiate()

	var center = room.get_center()

	boss.global_position = Vector2(
		center.x * TILE_SIZE + TILE_SIZE / 2,
		center.y * TILE_SIZE + TILE_SIZE / 2
	)

	boss.add_to_group("Enemy")

	# =====================================
	# Endless Boss Scaling
	# =====================================

	boss.max_health = int(
		boss.max_health * (1.0 + current_floor * 0.20)
	)

	boss.health = boss.max_health

	boss.damage = int(
		boss.damage * (1.0 + current_floor * 0.15)
	)

	boss.speed += current_floor * 3

	# Optional attack speed scaling
	if "attack_cooldown" in boss.get_property_list().map(func(p): return p.name):
		boss.attack_cooldown = max(
			0.3,
			boss.attack_cooldown - current_floor * 0.02
		)

	boss.died.connect(enemy_defeated)

	if boss.has_method("set_boss_ui"):
		boss.set_boss_ui(boss_ui)

	add_child(boss)

	print("Boss Spawned on Floor ", current_floor)
	
# =====================================================
# Enemy Death
# =====================================================

func enemy_defeated():

	enemies_alive -= 1

	update_enemy_label()

	print("Enemies Remaining: ", enemies_alive)

	if enemies_alive > 0:
		return

	print("Floor Cleared!")

	await get_tree().create_timer(1.5).timeout

	next_floor()


# =====================================================
# UI
# =====================================================

func update_floor_label():

	if floor_label:
		floor_label.text = "Floor : " + str(current_floor)


func update_enemy_label():

	if enemy_label:
		enemy_label.text = "Enemies : " + str(enemies_alive)


# =====================================================
# Game Over
# =====================================================

func player_died():

	print("===================")
	print(" RUN OVER ")
	print("===================")
	print("Highest Floor:", current_floor)

	get_tree().paused = true

	if $HUD.has_method("show_game_over"):
		$HUD.show_game_over()



		
