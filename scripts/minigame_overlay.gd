extends Control

signal finished(reward: int, result_text: String)

var mode := ""
var score := 0
var time_left := 20.0
var target := Vector2(380, 260)
var target_timer := 0.0
var fishing_cursor := 0.0
var fishing_direction := 1.0
var active := false


func start_game(game_mode: String) -> void:
	mode = game_mode
	score = 0
	time_left = 20.0
	active = true
	visible = true
	set_process(true)
	move_target()
	queue_redraw()


func _process(delta: float) -> void:
	if not active: return
	time_left -= delta
	if mode == "mole":
		target_timer -= delta
		if target_timer <= 0.0: move_target()
	else:
		fishing_cursor += fishing_direction * delta * 0.85
		if fishing_cursor >= 1.0 or fishing_cursor <= 0.0:
			fishing_cursor = clampf(fishing_cursor, 0.0, 1.0)
			fishing_direction *= -1.0
	if time_left <= 0.0:
		end_game()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not active: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mode == "mole" and event.position.distance_to(target) < 48.0:
			score += 1
			move_target()
		elif mode == "fishing":
			if fishing_cursor >= 0.42 and fishing_cursor <= 0.62:
				score += 1
				time_left = maxf(0.0, time_left - 1.5)


func move_target() -> void:
	target = Vector2(randf_range(130, size.x - 130), randf_range(150, size.y - 100))
	target_timer = randf_range(0.7, 1.35)


func end_game() -> void:
	active = false
	set_process(false)
	visible = false
	var reward := score * (9 if mode == "fishing" else 6)
	var label := "낚시" if mode == "fishing" else "두더지 잡기"
	finished.emit(reward, "%s: %d점, %dG 획득" % [label, score, reward])


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#24170ff0"))
	draw_rect(Rect2(Vector2(18, 18), size - Vector2(36, 36)), Color("#c89b5b"), false, 6)
	draw_string(ThemeDB.fallback_font, Vector2(34, 48), "ESC 대신 20초 동안 플레이", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d9f1e5"))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 250, 48), "남은 시간 %.1f  |  점수 %d" % [time_left, score], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
	if mode == "mole":
		draw_rect(Rect2(target - Vector2(48, 24), Vector2(96, 48)), Color("#704b38"))
		draw_rect(Rect2(target + Vector2(-34, -40), Vector2(68, 58)), Color("#b57b50"))
		draw_rect(Rect2(target + Vector2(-15, -18), Vector2(8, 8)), Color("#272622"))
		draw_rect(Rect2(target + Vector2(7, -18), Vector2(8, 8)), Color("#272622"))
		draw_string(ThemeDB.fallback_font, Vector2(34, 82), "나타나는 두더지를 클릭하세요!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#ffd889"))
	else:
		var bar := Rect2(110, size.y * 0.52, size.x - 220, 54)
		draw_rect(bar.grow(6), Color("#d8a85f"))
		draw_rect(bar, Color("#ead49d"))
		draw_rect(Rect2(lerpf(bar.position.x, bar.end.x, 0.42), bar.position.y, bar.size.x * 0.20, bar.size.y), Color("#6e9b4f"))
		var cursor_x := lerpf(bar.position.x, bar.end.x, fishing_cursor)
		draw_rect(Rect2(cursor_x - 5, bar.position.y - 12, 10, bar.size.y + 24), Color("#f2b34f"))
		draw_string(ThemeDB.fallback_font, Vector2(110, bar.position.y - 35), "표시가 초록 구간에 올 때 클릭!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
