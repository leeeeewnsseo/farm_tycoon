extends Node2D

const TILE := 64
const WORLD_SIZE := Vector2(4096, 2560)
const MONTH_SECONDS := 3600.0
const FARM_ORIGIN := Vector2(1120, 880)
const PLOT_SIZE := Vector2(112, 104)
const PLOT_STEP := Vector2(132, 126)
const FARM_CLICK_DISTANCE := 210.0
const PLAYER_RADIUS := 28.0
const GRAPH_SCRIPT: Script = preload("res://scripts/market_graph.gd")
const MINIGAME_SCRIPT: Script = preload("res://scripts/minigame_overlay.gd")

const TILE_GRASS: Texture2D = preload("res://assets/cute_fantasy/tiles/Grass_Middle.png")
const TILE_FARMLAND: Texture2D = preload("res://assets/cute_fantasy/tiles/FarmLand_Tile.png")
const TILE_PATH: Texture2D = preload("res://assets/cute_fantasy/tiles/Path_Middle.png")
const TILE_WATER: Texture2D = preload("res://assets/cute_fantasy/tiles/Water_Middle.png")
const TILE_WATER_EDGE: Texture2D = preload("res://assets/cute_fantasy/tiles/Water_Tile.png")
const TILE_BEACH: Texture2D = preload("res://assets/cute_fantasy/tiles/Beach_Tile.png")
const TREE_ART: Texture2D = preload("res://assets/cute_fantasy/outdoor/Oak_Tree.png")
const SMALL_TREES: Texture2D = preload("res://assets/cute_fantasy/outdoor/Oak_Tree_Small.png")
const HOUSE_ART: Texture2D = preload("res://assets/cute_fantasy/outdoor/House_1_Wood_Base_Blue.png")
const DECOR_ART: Texture2D = preload("res://assets/cute_fantasy/outdoor/Outdoor_Decor_Free.png")
const FENCE_ART: Texture2D = preload("res://assets/cute_fantasy/outdoor/Fences.png")
const BRIDGE_ART: Texture2D = preload("res://assets/cute_fantasy/outdoor/Bridge_Wood.png")
const CHEST_ART: Texture2D = preload("res://assets/cute_fantasy/outdoor/Chest.png")
const PLAYER_ART: Texture2D = preload("res://assets/cute_fantasy/player/Player.png")
const CHICKEN_ART: Texture2D = preload("res://assets/cute_fantasy/animals/Chicken.png")
const COW_ART: Texture2D = preload("res://assets/cute_fantasy/animals/Cow.png")
const PIG_ART: Texture2D = preload("res://assets/cute_fantasy/animals/Pig.png")
const SHEEP_ART: Texture2D = preload("res://assets/cute_fantasy/animals/Sheep.png")

const SEASON_CROPS := {
	0: ["potato", "lettuce", "strawberry", "carrot", "pea", "radish"],
	1: ["corn", "tomato", "watermelon", "cucumber", "pepper", "sunflower"],
	2: ["rice", "pumpkin", "sweet_potato", "apple", "grape", "cabbage"],
	3: ["spinach", "broccoli", "onion", "garlic", "tangerine", "winter_wheat"],
}
const CROP_NAMES := {
	"potato":"감자", "lettuce":"상추", "strawberry":"딸기", "carrot":"당근", "pea":"완두", "radish":"봄무",
	"corn":"옥수수", "tomato":"토마토", "watermelon":"수박", "cucumber":"오이", "pepper":"고추", "sunflower":"해바라기",
	"rice":"베", "pumpkin":"호박", "sweet_potato":"고구마", "apple":"사과", "grape":"포도", "cabbage":"배추",
	"spinach":"시금치", "broccoli":"브로콜리", "onion":"양파", "garlic":"마늘", "tangerine":"귤", "winter_wheat":"겨울밀",
}
const BASE_PRICE := {
	"potato":28, "lettuce":22, "strawberry":52, "carrot":25, "pea":31, "radish":24,
	"corn":35, "tomato":42, "watermelon":68, "cucumber":27, "pepper":38, "sunflower":45,
	"rice":48, "pumpkin":57, "sweet_potato":39, "apple":55, "grape":62, "cabbage":34,
	"spinach":30, "broccoli":44, "onion":32, "garlic":50, "tangerine":58, "winter_wheat":41,
}

var player_position := Vector2(1120, 820)
var target_position := player_position
var move_speed := 310.0
var year := 1
var month := 1
var month_elapsed := 0.0
var gold := 300
var selected_crop := "potato"
var walk_animation_time := 0.0
var environment_animation_time := 0.0
var player_facing := Vector2.DOWN
var near_place := ""
var message := "밭 가까이에서 원하는 칸을 클릭해 씨앗을 심어 보세요."
var seeds: Dictionary = {}
var storage: Dictionary = {}
var price_history: Dictionary = {}
var price_months: Array[String] = []
var plots: Array[Dictionary] = []

var camera: Camera2D
var time_label: Label
var place_label: Label
var status_label: Label
var message_label: Label
var interact_button: Button
var npc_panel: PanelContainer
var npc_content: VBoxContainer
var crop_select: OptionButton
var market_graph: Control
var minigame: Control
var ui_layer: CanvasLayer
var crop_picker: PanelContainer
var crop_picker_content: VBoxContainer
var pending_plot_index := -1

var locations := {
	"npc_chief": Vector2(1120, 800),
	"npc_farmer": Vector2(2040, 1260),
	"npc_rancher": Vector2(3370, 660),
	"npc_carpenter": Vector2(2820, 960),
	"npc_fisher": Vector2(650, 1850),
	"npc_cook": Vector2(2260, 1960),
	"npc_miner": Vector2(400, 1150),
	"npc_traveler": Vector2(3500, 1900),
	"fishing": Vector2(650, 1850),
	"mole": Vector2(3370, 1900),
}

var npc_info := {
	"npc_chief": ["이장님", "종묘상·판매·시세는 저에게 물어보세요.", "#da875c"],
	"npc_farmer": ["농부 하나", "작물은 두 달이 지나면 수확할 수 있어요.", "#6f9b57"],
	"npc_rancher": ["목장주 미소", "북쪽 초원은 동물들이 살기 좋은 곳이에요.", "#b98555"],
	"npc_carpenter": ["목수 우드", "나무는 마을을 풍요롭게 만드는 소중한 자원이죠.", "#916d4e"],
	"npc_fisher": ["낚시꾼 파랑", "표시가 초록색에 올 때 눌러야 물고기를 잡을 수 있어요.", "#4f8ea4"],
	"npc_cook": ["요리사 달래", "신선한 계절 작물이 가장 맛있는 법이에요.", "#d27472"],
	"npc_miner": ["광부 돌이", "서쪽에서 좋은 돌을 찾고 있어요. 다음에 도구를 만들어 줄게요.", "#777481"],
	"npc_traveler": ["여행자 나루", "이 섬은 넓으니 길을 따라 천천히 돌아보세요.", "#9a70b5"],
}


func _ready() -> void:
	for key in CROP_NAMES:
		seeds[key] = 2
		storage[key] = 0
		price_history[key] = []
	for back in range(5, -1, -1):
		price_months.append("%d월전" % back if back > 0 else "이번 달")
	for key in CROP_NAMES:
		var history: Array = price_history[key]
		var base := int(BASE_PRICE[key])
		for i in range(6): history.append(maxi(8, int(base * randf_range(0.76, 1.25))))
	for i in range(24):
		plots.append({"crop":"", "growth":0})
	camera = Camera2D.new()
	camera.position = player_position
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WORLD_SIZE.x)
	camera.limit_bottom = int(WORLD_SIZE.y)
	add_child(camera)
	camera.make_current()
	build_ui()
	update_ui()
	queue_redraw()
	if "--map-shot" in OS.get_cmdline_user_args():
		prepare_map_capture.call_deferred()


func _process(delta: float) -> void:
	environment_animation_time += delta
	if npc_panel.visible or minigame.visible:
		queue_redraw()
		return
	month_elapsed += delta
	if month_elapsed >= MONTH_SECONDS:
		month_elapsed -= MONTH_SECONDS
		advance_month()
	if player_position.distance_to(target_position) > 3.0:
		var next_position := player_position.move_toward(target_position, move_speed * delta)
		var movement := next_position - player_position
		if movement.length_squared() > 0.01:
			player_facing = movement.normalized()
			walk_animation_time += delta
		player_position = move_with_house_collision(next_position)
	else:
		walk_animation_time = 0.0
	player_position.x = clampf(player_position.x, 40, WORLD_SIZE.x - 40)
	player_position.y = clampf(player_position.y, 40, WORLD_SIZE.y - 40)
	camera.position = player_position
	update_near_place()
	update_clock_label()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if crop_picker != null and crop_picker.visible:
		return
	if event.is_action_pressed("ui_accept") and not near_place.is_empty():
		interact()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_E and not near_place.is_empty():
		interact()
	elif event is InputEventMouseButton and event.pressed and not npc_panel.visible:
		var click_pos := get_global_mouse_position()
		var plot_index := plot_at_position(click_pos)
		if plot_index >= 0 and event.button_index == MOUSE_BUTTON_RIGHT:
			open_crop_picker(plot_index)
			return
		if plot_index >= 0 and event.button_index == MOUSE_BUTTON_LEFT:
			use_plot(plot_index)
			return
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		target_position = Vector2(
			clampf(click_pos.x, 40, WORLD_SIZE.x - 40),
			clampf(click_pos.y, 40, WORLD_SIZE.y - 40)
		)


func move_with_house_collision(next_position: Vector2) -> Vector2:
	if not is_position_blocked(next_position):
		return next_position
	# Resolve each axis independently so the player slides along a wall.
	var x_only := Vector2(next_position.x, player_position.y)
	if not is_position_blocked(x_only):
		return x_only
	var y_only := Vector2(player_position.x, next_position.y)
	if not is_position_blocked(y_only):
		return y_only
	target_position = player_position
	return player_position


func is_position_blocked(pos: Vector2) -> bool:
	var house_footprints := [
		Rect2(700, 530, 248, 190),
		Rect2(2460, 1470, 200, 174),
	]
	for footprint in house_footprints:
		if footprint.grow(PLAYER_RADIUS).has_point(pos):
			return true
	return false


func get_plot_rect(index: int) -> Rect2:
	var col := index % 6
	var row := index / 6 as int
	return Rect2(FARM_ORIGIN + Vector2(col * PLOT_STEP.x, row * PLOT_STEP.y), PLOT_SIZE)


func plot_at_position(pos: Vector2) -> int:
	for index in range(plots.size()):
		if get_plot_rect(index).has_point(pos):
			return index
	return -1


func use_plot(index: int) -> void:
	var rect := get_plot_rect(index)
	var nearest := Vector2(
		clampf(player_position.x, rect.position.x, rect.end.x),
		clampf(player_position.y, rect.position.y, rect.end.y)
	)
	if player_position.distance_to(nearest) > FARM_CLICK_DISTANCE:
		message = "밭에 더 가까이 가서 클릭해 주세요."
		target_position = nearest
		update_ui()
		return
	var plot: Dictionary = plots[index]
	if plot["crop"] != "":
		if int(plot["growth"]) >= 2:
			storage[plot["crop"]] += 1
			message = "%s 1개를 수확했습니다." % CROP_NAMES[plot["crop"]]
			plot["crop"] = ""
			plot["growth"] = 0
		else:
			message = "%s이(가) 아직 자라는 중입니다." % CROP_NAMES[plot["crop"]]
	elif selected_crop not in SEASON_CROPS[season_index()]:
		message = "%s은(는) 현재 계절에 심을 수 없습니다." % CROP_NAMES[selected_crop]
	elif seeds[selected_crop] <= 0:
		message = "씨앗이 없습니다. 이장님에게 구매하세요."
	else:
		plot["crop"] = selected_crop
		plot["growth"] = 0
		seeds[selected_crop] -= 1
		message = "%s를 선택한 밭에 심었습니다." % CROP_NAMES[selected_crop]
	update_ui()


func open_crop_picker(index: int) -> void:
	var rect := get_plot_rect(index)
	var nearest := Vector2(
		clampf(player_position.x, rect.position.x, rect.end.x),
		clampf(player_position.y, rect.position.y, rect.end.y)
	)
	if player_position.distance_to(nearest) > FARM_CLICK_DISTANCE:
		message = "종자를 고르려면 밭에 더 가까이 가야 합니다."
		target_position = nearest
		update_ui()
		return
	pending_plot_index = index
	clear_container(crop_picker_content)
	crop_picker_content.add_child(section_header("심을 종자 선택 · %s" % season_name()))
	var guide := label(16, "#6e604e")
	guide.text = "종자를 고르면 우클릭한 밭에 바로 심습니다."
	crop_picker_content.add_child(guide)
	for key in SEASON_CROPS[season_index()]:
		var button_text := "%s · 보유 %d개" % [CROP_NAMES[key], seeds[key]]
		crop_picker_content.add_child(menu_button(button_text, plant_crop_from_picker.bind(key)))
	crop_picker_content.add_child(menu_button("닫기", close_crop_picker))
	crop_picker.visible = true


func plant_crop_from_picker(key: String) -> void:
	selected_crop = key
	var index := pending_plot_index
	close_crop_picker()
	if index >= 0:
		use_plot(index)


func close_crop_picker() -> void:
	crop_picker.visible = false
	pending_plot_index = -1


func _draw() -> void:
	draw_cute_fantasy_background()
	for npc_key in npc_info:
		draw_npc(locations[npc_key], npc_info[npc_key][0], npc_info[npc_key][2])
	draw_farm()
	draw_pond()
	draw_mole_field()
	draw_scenery()
	draw_player(player_position)


func draw_cute_fantasy_background() -> void:
	for y in range(0, int(WORLD_SIZE.y / TILE) + 1):
		for x in range(0, int(WORLD_SIZE.x / TILE) + 1):
			var pos := Vector2(x * TILE, y * TILE)
			var tile_tex: Texture2D = TILE_GRASS
			# Bright paths are deliberately separated from the dark tilled plots.
			if is_path_tile(x, y):
				tile_tex = TILE_PATH
			draw_texture_rect(tile_tex, Rect2(pos, Vector2(TILE, TILE)), false)
			if tile_tex == TILE_PATH:
				draw_dirt_details(pos, x, y)
				draw_path_edges(pos, x, y)
			elif tile_tex == TILE_GRASS and (x * 5 + y * 3) % 4 == 0:
				draw_grass_details(pos, x, y)

	var tree_positions := [
		Vector2(420, 420), Vector2(1180, 340), Vector2(1480, 460), Vector2(3320, 500),
		Vector2(3080, 1740), Vector2(1320, 1920), Vector2(2400, 1960)
	]
	for pos in tree_positions:
		draw_texture_rect(TREE_ART, Rect2(pos - Vector2(0, 32), Vector2(128, 160)), false)
	# Small trees, flowers and stones extracted from the supplied asset pack.
	for i in range(20):
		var small_pos := Vector2(180 + (i * 509) % 3700, 180 + (i * 283) % 2180)
		draw_texture_rect_region(SMALL_TREES, Rect2(small_pos, Vector2(96, 96)), Rect2((i % 2) * 48, 0, 48, 48))
	for i in range(36):
		var decor_pos := Vector2(120 + (i * 241) % 3820, 140 + (i * 397) % 2240)
		var decor_source := Rect2((i % 5) * 16, (i % 2) * 16, 16, 16)
		draw_texture_rect_region(DECOR_ART, Rect2(decor_pos, Vector2(32, 32)), decor_source)

	draw_texture_rect(HOUSE_ART, Rect2(Vector2(680, 340), Vector2(288, 384)), false)
	draw_texture_rect(HOUSE_ART, Rect2(Vector2(2440, 1320), Vector2(240, 320)), false)


func draw_dirt_details(pos: Vector2, tile_x: int, tile_y: int) -> void:
	# Deterministic pixel clusters make the path read as compacted soil.
	var seed_value := tile_x * 37 + tile_y * 71
	for i in range(5):
		var px := 7 + posmod(seed_value + i * 19, 50)
		var py := 8 + posmod(seed_value * 3 + i * 23, 48)
		var color := Color("#8b6740") if i % 2 == 0 else Color("#e0b86f")
		draw_rect(Rect2(pos + Vector2(px, py), Vector2(5, 3)), color)
		if i % 2 == 0:
			draw_rect(Rect2(pos + Vector2(px + 5, py + 2), Vector2(3, 2)), Color("#6f5135"))
	for groove in range(2):
		var groove_y := 19.0 + groove * 27.0 + float(posmod(seed_value, 5))
		draw_line(pos + Vector2(4, groove_y), pos + Vector2(60, groove_y + 3), Color("#a77b48aa"), 2)


func is_path_tile(x: int, y: int) -> bool:
	return (y >= 11 and y <= 13) or (x >= 14 and x <= 16) or (x >= 29 and x <= 31 and y >= 13 and y <= 35)


func draw_path_edges(pos: Vector2, tile_x: int, tile_y: int) -> void:
	var dark := Color("#765332")
	var light := Color("#d9ae67")
	if not is_path_tile(tile_x - 1, tile_y):
		draw_rect(Rect2(pos, Vector2(5, TILE)), dark)
		draw_rect(Rect2(pos + Vector2(5, 0), Vector2(3, TILE)), light)
	if not is_path_tile(tile_x + 1, tile_y):
		draw_rect(Rect2(pos + Vector2(TILE - 5, 0), Vector2(5, TILE)), dark)
		draw_rect(Rect2(pos + Vector2(TILE - 8, 0), Vector2(3, TILE)), light)
	if not is_path_tile(tile_x, tile_y - 1):
		draw_rect(Rect2(pos, Vector2(TILE, 5)), dark)
		draw_rect(Rect2(pos + Vector2(0, 5), Vector2(TILE, 3)), light)
	if not is_path_tile(tile_x, tile_y + 1):
		draw_rect(Rect2(pos + Vector2(0, TILE - 5), Vector2(TILE, 5)), dark)
		draw_rect(Rect2(pos + Vector2(0, TILE - 8), Vector2(TILE, 3)), light)


func draw_grass_details(pos: Vector2, tile_x: int, tile_y: int) -> void:
	var seed_value := tile_x * 53 + tile_y * 97
	for i in range(3):
		var base := pos + Vector2(9 + posmod(seed_value + i * 23, 47), 16 + posmod(seed_value * 2 + i * 17, 39))
		var blade_color := Color("#2f793f") if (seed_value + i) % 2 == 0 else Color("#8fcf58")
		draw_line(base, base + Vector2(-3, -7), blade_color, 2)
		draw_line(base, base + Vector2(1, -9), blade_color, 2)
		draw_line(base, base + Vector2(5, -6), blade_color, 2)
	if (tile_x * 11 + tile_y * 7) % 9 == 0:
		var flower := pos + Vector2(46, 18)
		draw_rect(Rect2(flower, Vector2(3, 8)), Color("#397844"))
		draw_rect(Rect2(flower + Vector2(-3, -3), Vector2(4, 4)), Color("#f0cf58"))
		draw_rect(Rect2(flower + Vector2(2, -4), Vector2(4, 4)), Color("#fff1ae"))


func draw_house(origin: Vector2) -> void:
	draw_texture(HOUSE_ART, origin)


func draw_npc(pos: Vector2, npc_name: String, clothing_color: String) -> void:
	var tint := Color(clothing_color).lightened(0.42)
	draw_texture_rect_region(PLAYER_ART, Rect2(pos + Vector2(-48, -72), Vector2(96, 96)), Rect2(0, 0, 32, 32), tint)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-40, -64), npc_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#3c3026"))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-42, -67), npc_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fff5d6"))


func draw_farm() -> void:
	var origin := FARM_ORIGIN
	for i in range(24):
		var rect := get_plot_rect(i)
		draw_style_box(box("#5b3826", 9, "#f2d28a", 5), rect.grow(6))
		draw_texture_rect(TILE_FARMLAND, rect, false)
		for furrow in range(3):
			draw_line(rect.position + Vector2(10, 25 + furrow * 27), rect.end - Vector2(10, 79 - furrow * 27), Color("#70472f"), 3)
		var crop: String = plots[i]["crop"]
		if not crop.is_empty():
			var crop_index := CROP_NAMES.keys().find(crop) % 6
			var growth := mini(int(plots[i]["growth"]), 2)
			var source := Rect2(crop_index * 16, 96 + growth * 16, 16, 16)
			for p in range(3):
				draw_texture_rect_region(DECOR_ART, Rect2(rect.position + Vector2(7 + p * 34, 25), Vector2(32, 32)), source)
	draw_farm_fence()
	draw_texture_rect(CHEST_ART, Rect2(origin + Vector2(790, 398), Vector2(48, 48)), false)
	draw_string(ThemeDB.fallback_font, origin + Vector2(0, -28), "우리 농장 · 가까이서 밭을 클릭", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#fff5d6"))


func draw_farm_fence() -> void:
	var left := FARM_ORIGIN.x - 34.0
	var right := FARM_ORIGIN.x + 6.0 * PLOT_STEP.x - 6.0
	var top := FARM_ORIGIN.y - 38.0
	var bottom := FARM_ORIGIN.y + 4.0 * PLOT_STEP.y - 8.0
	for x in range(int(left), int(right), 96):
		if x < FARM_ORIGIN.x + 310 or x > FARM_ORIGIN.x + 470:
			draw_texture_rect_region(FENCE_ART, Rect2(x, top, 96, 32), Rect2(16, 0, 48, 16))
		draw_texture_rect_region(FENCE_ART, Rect2(x, bottom, 96, 32), Rect2(16, 0, 48, 16))
	for y in range(int(top), int(bottom), 96):
		draw_texture_rect_region(FENCE_ART, Rect2(left, y, 32, 96), Rect2(0, 0, 16, 48))
		draw_texture_rect_region(FENCE_ART, Rect2(right, y, 32, 96), Rect2(0, 0, 16, 48))


func draw_pond() -> void:
	var pos: Vector2 = locations["fishing"]
	var shore := Rect2(pos - Vector2(370, 250), Vector2(740, 500))
	draw_style_box(box("#d9b96d", 118, "#6f8f52", 12), shore)
	draw_style_box(box("#397b9e", 102, "#b8d58b", 10), shore.grow(-24))
	# Layered shoreline pixels and shallow-water patches.
	for angle_index in range(16):
		var angle := TAU * float(angle_index) / 16.0
		var bank_pos := pos + Vector2(cos(angle) * 330.0, sin(angle) * 205.0)
		draw_texture_rect_region(TILE_BEACH, Rect2(bank_pos - Vector2(30, 22), Vector2(60, 44)), Rect2(0, 0, 48, 48))
	for y in range(-2, 3):
		for x in range(-4, 5):
			var shimmer := 0.93 + sin(environment_animation_time * 1.8 + x * 0.7 + y) * 0.07
			draw_texture_rect(TILE_WATER, Rect2(pos + Vector2(x * TILE, y * TILE), Vector2(TILE, TILE)), false, Color(shimmer, shimmer, 1.0, 1.0))
	for ripple_index in range(8):
		var phase := environment_animation_time * (34.0 + ripple_index * 2.0)
		var base_x := -270.0 + float((ripple_index * 83) % 540)
		var base_y := -145.0 + float((ripple_index * 59) % 290)
		var moving_offset := Vector2(fmod(phase + ripple_index * 31.0, 70.0) - 35.0, sin(environment_animation_time * 1.7 + ripple_index) * 8.0)
		var ripple_pos := pos + Vector2(base_x, base_y) + moving_offset
		var ripple_width := 15.0 + fmod(environment_animation_time * 9.0 + ripple_index * 5.0, 17.0)
		var alpha := 0.45 + sin(environment_animation_time * 2.2 + ripple_index) * 0.18
		draw_arc(ripple_pos, ripple_width, 0.15, PI - 0.15, 10, Color(0.68, 0.9, 0.94, alpha), 3)
	for sparkle_index in range(7):
		var sparkle_phase := environment_animation_time * 2.5 + sparkle_index * 1.7
		var sparkle_pos := pos + Vector2(-250 + (sparkle_index * 79) % 500, -115 + (sparkle_index * 67) % 230)
		var sparkle_alpha := 0.25 + (sin(sparkle_phase) + 1.0) * 0.3
		draw_line(sparkle_pos - Vector2(8, 0), sparkle_pos + Vector2(8, 0), Color(0.85, 0.97, 1.0, sparkle_alpha), 3)
		draw_line(sparkle_pos - Vector2(0, 5), sparkle_pos + Vector2(0, 5), Color(0.85, 0.97, 1.0, sparkle_alpha), 2)
	# Animated reeds along the bank.
	for reed_index in range(12):
		var reed_x := -285.0 + reed_index * 51.0
		var reed_base := pos + Vector2(reed_x, 190 + sin(reed_index * 1.4) * 14)
		var sway := sin(environment_animation_time * 1.8 + reed_index * 0.7) * 4.0
		draw_line(reed_base, reed_base + Vector2(sway, -30), Color("#315f36"), 4)
		draw_line(reed_base + Vector2(2, -15), reed_base + Vector2(10 + sway, -22), Color("#75a84b"), 3)
	# Lily pads and flowers from the provided decoration sprite sheet.
	for offset in [Vector2(-170, 70), Vector2(70, -105), Vector2(210, 65)]:
		draw_texture_rect_region(DECOR_ART, Rect2(pos + offset, Vector2(40, 40)), Rect2(0, 0, 16, 16))
	draw_texture_rect_region(BRIDGE_ART, Rect2(pos + Vector2(275, -80), Vector2(112, 128)), Rect2(96, 0, 48, 48))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-96, -250), "낚시터", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#fff5d6"))


func draw_mole_field() -> void:
	var pos: Vector2 = locations["mole"]
	draw_style_box(box("#c69e61", 45), Rect2(pos - Vector2(300, 210), Vector2(600, 420)))
	for y in range(3):
		for x in range(4): draw_pixel_ellipse(pos + Vector2(-210 + x * 140, -115 + y * 115), Vector2(42, 21), Color("#654936"))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-120, -235), "두더지 놀이터", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#4f3d2c"))


func draw_scenery() -> void:
	for i in range(34):
		var x := 260.0 + float((i * 337) % 3500)
		var y := 240.0 + float((i * 173) % 2050)
		if Vector2(x, y).distance_to(player_position) < 1: continue
		draw_texture_rect(TREE_ART, Rect2(Vector2(x - 48, y - 72), Vector2(96, 120)), false)
	# Ranch animals use the supplied Cute Fantasy sprite sheets.
	draw_animal(COW_ART, Vector2(3280, 520), 0)
	draw_animal(COW_ART, Vector2(3440, 560), 1)
	draw_animal(PIG_ART, Vector2(3250, 720), 0)
	draw_animal(PIG_ART, Vector2(3410, 740), 1)
	draw_animal(SHEEP_ART, Vector2(3530, 650), 0)
	draw_animal(CHICKEN_ART, Vector2(3180, 650), 0)


func draw_animal(texture: Texture2D, pos: Vector2, frame: int) -> void:
	draw_texture_rect_region(texture, Rect2(pos - Vector2(32, 32), Vector2(64, 64)), Rect2((frame % 4) * 16, 0, 16, 16))


func draw_player(pos: Vector2) -> void:
	var row := 0
	if absf(player_facing.x) > absf(player_facing.y):
		row = 1 if player_facing.x > 0 else 3
	elif player_facing.y < 0:
		row = 2
	var moving := player_position.distance_to(target_position) > 3.0
	var frame := int(walk_animation_time * 9.0) % 6 if moving else 0
	draw_texture_rect_region(PLAYER_ART, Rect2(pos + Vector2(-48, -72), Vector2(96, 96)), Rect2(frame * 32, row * 32, 32, 32))


func build_ui() -> void:
	var layer := CanvasLayer.new()
	ui_layer = layer
	add_child(layer)
	var hud := Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	var top := PanelContainer.new()
	top.position = Vector2(22, 20)
	top.size = Vector2(720, 78)
	top.add_theme_stylebox_override("panel", pixel_box("#3d271b", "#d8a85f", 5))
	hud.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	top.add_child(row)
	time_label = label(20, "#fff0c9")
	place_label = label(18, "#d8eee2")
	status_label = label(18, "#ffffff")
	row.add_child(time_label); row.add_child(place_label); row.add_child(status_label)
	message_label = label(17, "#3b281d")
	message_label.position = Vector2(22, 112)
	message_label.size = Vector2(610, 54)
	message_label.add_theme_stylebox_override("normal", pixel_box("#f3d99aee", "#754b2d", 4))
	hud.add_child(message_label)
	interact_button = Button.new()
	interact_button.position = Vector2(970, 620)
	interact_button.size = Vector2(280, 68)
	interact_button.add_theme_font_size_override("font_size", 20)
	apply_pixel_button_style(interact_button)
	interact_button.pressed.connect(interact)
	interact_button.visible = false
	hud.add_child(interact_button)
	build_npc_panel(hud)
	build_crop_picker(hud)
	minigame = MINIGAME_SCRIPT.new()
	minigame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	minigame.visible = false
	minigame.mouse_filter = Control.MOUSE_FILTER_STOP
	minigame.finished.connect(on_minigame_finished)
	hud.add_child(minigame)


func build_crop_picker(parent: Control) -> void:
	crop_picker = PanelContainer.new()
	crop_picker.position = Vector2(850, 120)
	crop_picker.size = Vector2(390, 520)
	crop_picker.add_theme_stylebox_override("panel", pixel_box("#ead095f8", "#4b3020", 6))
	crop_picker.visible = false
	crop_picker.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(crop_picker)
	crop_picker_content = VBoxContainer.new()
	crop_picker_content.add_theme_constant_override("separation", 9)
	crop_picker.add_child(crop_picker_content)


func prepare_map_capture() -> void:
	ui_layer.visible = false
	camera.position_smoothing_enabled = false
	camera.position = WORLD_SIZE * 0.5
	camera.zoom = Vector2(0.28, 0.28)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png("res://build/사계절농장_맵전체.png")
	print("맵 캡처 저장: ", error)
	get_tree().quit()


func build_npc_panel(parent: Control) -> void:
	npc_panel = PanelContainer.new()
	npc_panel.position = Vector2(180, 85)
	npc_panel.size = Vector2(920, 570)
	npc_panel.add_theme_stylebox_override("panel", pixel_box("#ead095f8", "#4b3020", 6))
	npc_panel.visible = false
	npc_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(npc_panel)
	npc_content = VBoxContainer.new()
	npc_content.add_theme_constant_override("separation", 12)
	npc_panel.add_child(npc_content)
	show_npc_menu()


func show_npc_menu() -> void:
	clear_container(npc_content)
	var title := label(27, "#334d45")
	title.text = "이장님  |  무엇을 도와드릴까?"
	npc_content.add_child(title)
	var intro := label(17, "#6e604e")
	intro.text = "씨앗 구매, 수확물 판매, 농산물 시세 확인은 저에게 말씀하세요."
	npc_content.add_child(menu_button("종묘상 · 이번 계절 작물 6종", show_seed_shop))
	npc_content.add_child(menu_button("수확물 판매", show_sell_menu))
	npc_content.add_child(menu_button("시세 확인 · 최근 6개월 그래프", show_market_menu))
	npc_content.add_spacer(false)
	npc_content.add_child(menu_button("대화 끝내기", close_npc_panel))


func show_seed_shop() -> void:
	clear_container(npc_content)
	npc_content.add_child(section_header("종묘상 · %s 작물" % season_name()))
	crop_select = OptionButton.new()
	apply_pixel_option_style(crop_select)
	for key in SEASON_CROPS[season_index()]:
		crop_select.add_item("%s  |  씨앗 %dG  |  보유 %d" % [CROP_NAMES[key], seed_price(key), seeds[key]])
		crop_select.set_item_metadata(crop_select.item_count - 1, key)
	crop_select.custom_minimum_size.y = 52
	npc_content.add_child(crop_select)
	npc_content.add_child(menu_button("선택한 씨앗 1개 구매", buy_selected_seed))
	npc_content.add_child(menu_button("선택한 작물을 농장 심기 대상으로 설정", select_shop_crop))
	npc_content.add_child(menu_button("뒤로", show_npc_menu))


func show_sell_menu() -> void:
	clear_container(npc_content)
	npc_content.add_child(section_header("수확물 판매"))
	crop_select = OptionButton.new()
	apply_pixel_option_style(crop_select)
	for key in CROP_NAMES:
		if storage[key] > 0:
			crop_select.add_item("%s  %d개  ×  %dG" % [CROP_NAMES[key], storage[key], current_price(key)])
			crop_select.set_item_metadata(crop_select.item_count - 1, key)
	if crop_select.item_count == 0: crop_select.add_item("판매할 수확물이 없습니다")
	crop_select.custom_minimum_size.y = 52
	npc_content.add_child(crop_select)
	npc_content.add_child(menu_button("선택 수확물 전부 판매", sell_selected_crop))
	npc_content.add_child(menu_button("뒤로", show_npc_menu))


func show_market_menu() -> void:
	clear_container(npc_content)
	npc_content.add_child(section_header("농산물 시세 확인"))
	crop_select = OptionButton.new()
	apply_pixel_option_style(crop_select)
	for key in CROP_NAMES:
		crop_select.add_item("%s  현재 %dG" % [CROP_NAMES[key], current_price(key)])
		crop_select.set_item_metadata(crop_select.item_count - 1, key)
	crop_select.item_selected.connect(update_market_graph)
	npc_content.add_child(crop_select)
	market_graph = GRAPH_SCRIPT.new()
	market_graph.custom_minimum_size = Vector2(0, 340)
	npc_content.add_child(market_graph)
	npc_content.add_child(menu_button("뒤로", show_npc_menu))
	update_market_graph(0)


func update_near_place() -> void:
	var previous := near_place
	near_place = ""
	var best := 150.0
	for key in locations:
		var distance := player_position.distance_to(locations[key])
		if distance < best:
			best = distance
			near_place = key
	if previous != near_place:
		interact_button.visible = not near_place.is_empty()
		interact_button.text = interaction_text(near_place)


func interact() -> void:
	match near_place:
		"npc_chief":
			npc_panel.visible = true
			show_npc_menu()
		"fishing": minigame.start_game("fishing")
		"mole": minigame.start_game("mole")
		_:
			if near_place.begins_with("npc_"):
				message = "%s: \"%s\"" % [npc_info[near_place][0], npc_info[near_place][1]]
				update_ui()


func plant_or_harvest() -> void:
	for plot in plots:
		if plot["crop"] != "" and int(plot["growth"]) >= 2:
			storage[plot["crop"]] += 1
			message = "%s 1개를 수확했습니다." % CROP_NAMES[plot["crop"]]
			plot["crop"] = ""; plot["growth"] = 0
			update_ui(); return
	if selected_crop not in SEASON_CROPS[season_index()]:
		message = "%s은(는) 현재 계절에 심을 수 없습니다." % CROP_NAMES[selected_crop]
	elif seeds[selected_crop] <= 0:
		message = "씨앗이 없습니다. 집 앞 이장님에게 구매하세요."
	else:
		for plot in plots:
			if plot["crop"] == "":
				plot["crop"] = selected_crop; plot["growth"] = 0; seeds[selected_crop] -= 1
				message = "%s를 심었습니다. 2개월 후 수확할 수 있습니다." % CROP_NAMES[selected_crop]
				break
	update_ui()


func advance_month() -> void:
	month += 1
	if month > 12: month = 1; year += 1
	for plot in plots:
		if plot["crop"] != "": plot["growth"] += 1
	price_months.pop_front(); price_months.append("%d월" % month)
	for key in price_history:
		var history: Array = price_history[key]
		var previous := int(history.back())
		history.pop_front()
		history.append(maxi(8, int(previous * randf_range(0.82, 1.22))))
	message = "%d년 %d월이 시작됐습니다. 시세가 갱신됐습니다." % [year, month]
	update_ui()


func buy_selected_seed() -> void:
	if crop_select.item_count == 0: return
	var key: String = crop_select.get_item_metadata(crop_select.selected)
	var price := seed_price(key)
	if gold < price: message = "돈이 부족합니다."
	else: gold -= price; seeds[key] += 1; message = "%s 씨앗을 구매했습니다." % CROP_NAMES[key]
	show_seed_shop(); update_ui()


func select_shop_crop() -> void:
	selected_crop = crop_select.get_item_metadata(crop_select.selected)
	message = "농장에서 %s를 심을 준비를 했습니다." % CROP_NAMES[selected_crop]
	update_ui()


func sell_selected_crop() -> void:
	if crop_select.item_count == 0 or crop_select.get_item_metadata(crop_select.selected) == null: return
	var key: String = crop_select.get_item_metadata(crop_select.selected)
	var count := int(storage[key]); var income := count * current_price(key)
	gold += income; storage[key] = 0
	message = "%s %d개를 %dG에 판매했습니다." % [CROP_NAMES[key], count, income]
	show_sell_menu(); update_ui()


func update_market_graph(index: int) -> void:
	var key: String = crop_select.get_item_metadata(index)
	market_graph.set_series(CROP_NAMES[key], price_history[key], price_months)


func on_minigame_finished(reward: int, result: String) -> void:
	gold += reward; message = result; update_ui()


func close_npc_panel() -> void:
	npc_panel.visible = false


func update_ui() -> void:
	update_clock_label()
	place_label.text = "계절  %s" % season_name()
	status_label.text = "%dG  |  선택 %s 씨앗 %d" % [gold, CROP_NAMES[selected_crop], seeds[selected_crop]]
	message_label.text = "  %s" % message
	queue_redraw()


func update_clock_label() -> void:
	var remain := int(MONTH_SECONDS - month_elapsed)
	time_label.text = "%d년 %d월  |  다음 달 %02d:%02d" % [year, month, remain / 60, remain % 60]


func interaction_text(place: String) -> String:
	if place.begins_with("npc_"):
		return "E  %s와(과) 대화" % npc_info[place][0]
	return {"fishing":"E  낚시 미니게임", "mole":"E  두더지 잡기"}.get(place, "")


func season_index() -> int: return int((month - 1) / 3.0)
func season_name() -> String: return ["봄", "여름", "가을", "겨울"][season_index()]
func seed_price(key: String) -> int: return maxi(8, int(current_price(key) * 0.42))
func current_price(key: String) -> int: return int(price_history[key].back())


func label(font_size: int, color: String) -> Label:
	var node := Label.new()
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", Color(color))
	node.add_theme_color_override("font_outline_color", Color("#2a1b14"))
	node.add_theme_constant_override("outline_size", 1)
	return node


func section_header(text: String) -> Label:
	var node := label(27, "#334d45"); node.text = text; return node


func menu_button(text: String, callback: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 54
	node.add_theme_font_size_override("font_size", 18)
	apply_pixel_button_style(node)
	node.pressed.connect(callback)
	return node


func apply_pixel_button_style(node: Button) -> void:
	node.add_theme_color_override("font_color", Color("#fff1c7"))
	node.add_theme_color_override("font_hover_color", Color.WHITE)
	node.add_theme_color_override("font_pressed_color", Color("#3b281d"))
	node.add_theme_stylebox_override("normal", pixel_box("#8b5431", "#3d271b", 4))
	node.add_theme_stylebox_override("hover", pixel_box("#b56b38", "#f0c66d", 4))
	node.add_theme_stylebox_override("pressed", pixel_box("#d8a85f", "#3d271b", 4))
	node.add_theme_stylebox_override("focus", pixel_box("#a66137", "#fff0a6", 3))


func apply_pixel_option_style(node: OptionButton) -> void:
	apply_pixel_button_style(node)
	node.add_theme_font_size_override("font_size", 17)
	node.custom_minimum_size.y = 52


func pixel_box(color: String, border_color: String, border_width: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color)
	style.border_color = Color(border_color)
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_color = Color("#24170f88")
	style.shadow_size = 4
	style.shadow_offset = Vector2(4, 4)
	return style


func clear_container(container: Container) -> void:
	for child in container.get_children(): child.queue_free()


func box(color: String, radius: int, border_color: String = "#00000000", border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color(color); style.corner_radius_top_left = radius; style.corner_radius_top_right = radius; style.corner_radius_bottom_left = radius; style.corner_radius_bottom_right = radius; style.border_color = Color(border_color); style.set_border_width_all(border_width); style.content_margin_left = 18; style.content_margin_right = 18; style.content_margin_top = 14; style.content_margin_bottom = 14; return style


func draw_pixel_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var angle := TAU * i / 24.0; points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
