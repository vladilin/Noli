extends Node

func _ready():
	apply_integer_scale()

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		apply_integer_scale()

func apply_integer_scale():
	get_tree().root.content_scale_factor = get_best_integer_scale()

func get_best_integer_scale() -> int:
	var screen_size = DisplayServer.window_get_size()
	var base_size = Vector2(1536, 1024)  # Your design resolution
	var scale = floor(min(screen_size.x / base_size.x, screen_size.y / base_size.y))
	return max(1, scale)  # Ensure scale factor is at least 1
