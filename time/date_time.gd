class_name DateTime
extends Resource

@export var year: int = 2025
@export var month: int = 1
@export var day: int = 1
@export var hour: int = 0
@export var minute: int = 0
@export var second: float = 0.0

# Increase time by seconds, handling rollovers
func increase_by_sec(seconds: float) -> void:
	second += seconds
	while second >= 60.0:
		second -= 60.0
		minute += 1
	while minute >= 60:
		minute -= 60
		hour += 1
	while hour >= 24:
		hour -= 24
		day += 1
		# TODO: month/year rollover if needed

func get_minutes_total() -> int:
	return hour * 60 + minute

func get_seconds_total() -> int:
	return get_minutes_total() * 60 + int(second)

func format_time() -> String:
	return "%02d:%02d" % [hour, minute]
