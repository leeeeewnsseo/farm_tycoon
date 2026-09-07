extends Control

var crop_name := ""
var values: Array = []
var months: Array = []


func set_series(new_name: String, new_values: Array, new_months: Array) -> void:
	crop_name = new_name
	values = new_values.duplicate()
	months = new_months.duplicate()
	queue_redraw()


func _draw() -> void:
	var area := Rect2(48, 42, size.x - 78, size.y - 92)
	draw_rect(Rect2(Vector2.ZERO, size), Color("#d9bd7f"))
	draw_rect(Rect2(Vector2(4, 4), size - Vector2(8, 8)), Color("#ead49d"), false, 4)
	draw_string(ThemeDB.fallback_font, Vector2(20, 26), "%s · 최근 6개월 시세" % crop_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#3b281d"))
	for line_index in range(1, 4):
		var grid_y := lerpf(area.position.y, area.end.y, float(line_index) / 4.0)
		draw_dashed_line(Vector2(area.position.x, grid_y), Vector2(area.end.x, grid_y), Color("#9c7b4f88"), 2, 7)
	draw_line(area.position, Vector2(area.position.x, area.end.y), Color("#4b3020"), 4)
	draw_line(Vector2(area.position.x, area.end.y), area.end, Color("#4b3020"), 4)
	if values.is_empty():
		return
	var minimum := float(values.min()) * 0.85
	var maximum := float(values.max()) * 1.15
	if is_equal_approx(minimum, maximum): maximum += 1.0
	var points := PackedVector2Array()
	for i in range(values.size()):
		var ratio_x := float(i) / maxf(1.0, values.size() - 1.0)
		var ratio_y := (float(values[i]) - minimum) / (maximum - minimum)
		var point := Vector2(lerpf(area.position.x, area.end.x, ratio_x), lerpf(area.end.y, area.position.y, ratio_y))
		points.append(point)
		draw_rect(Rect2(point - Vector2(5, 5), Vector2(10, 10)), Color("#d05a3a"))
		draw_string(ThemeDB.fallback_font, point + Vector2(-12, -10), "%d" % int(values[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#3b281d"))
		var month_text := str(months[i]) if i < months.size() else ""
		draw_string(ThemeDB.fallback_font, Vector2(point.x - 16, area.end.y + 22), month_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#5d402a"))
	if points.size() > 1:
		draw_polyline(points, Color("#d05a3a"), 4, false)
