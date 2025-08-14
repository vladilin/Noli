class_name TimeSystem
extends Node

signal updated(date_time: DateTime)              # Fires every frame
signal minute_changed(current_minutes: int)      # Fires when minute changes
signal second_changed(current_seconds: int)      # NEW: Fires when second changes

@export var date_time: DateTime = DateTime.new()
@export var ticks_pr_second: int = 1  # How many in-game seconds pass per real second

var _last_minute: int = -1
var _last_second: int = -1

func _process(delta: float) -> void:
	# Advance the game time
	date_time.increase_by_sec(delta * ticks_pr_second)

	# Always tell listeners time changed
	updated.emit(date_time)

	# Minute change check
	var current_minute = date_time.get_minutes_total()
	if current_minute != _last_minute:
		_last_minute = current_minute
		minute_changed.emit(current_minute)

	# Second change check (NEW)
	var current_second = date_time.get_seconds_total()
	if current_second != _last_second:
		_last_second = current_second
		second_changed.emit(current_second)

func get_current_minutes() -> int:
	return date_time.get_minutes_total()

func format_time(minutes_total: int = -1) -> String:
	if minutes_total == -1:
		return date_time.format_time()
	var h = minutes_total / 60
	var m = minutes_total % 60
	return "%02d:%02d" % [h, m]
