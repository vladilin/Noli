# time_system.gd
# -----------------------------------------------------------------------------
# Manages global game time. Keeps track of in-game minutes and seconds,
# emits signals when time advances.
# -----------------------------------------------------------------------------

extends Node
class_name TimeSystem

# -------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------
signal second_changed(current_time_seconds: int)
signal minute_changed(current_time_minutes: int)

# -------------------------------------------------------------------
# Properties
# -------------------------------------------------------------------

# Total game time (in seconds since start)
var current_time_seconds: int = 0

# Speed multiplier: 1 = real time, 2 = twice as fast, etc.
var time_scale: float = 1.0

# Internal accumulator for delta
var _accum: float = 0.0

# -------------------------------------------------------------------
# Process loop
# -------------------------------------------------------------------
func _process(delta: float) -> void:
	# Scale delta by time_scale (faster/slower time)
	_accum += delta * time_scale

	# When a full second passes
	while _accum >= 1.0:
		_accum -= 1.0
		current_time_seconds += 1

		# Emit signals
		second_changed.emit(current_time_seconds)

		if current_time_seconds % 60 == 0:
			var minutes: int = current_time_seconds / 60
			minute_changed.emit(minutes)

# -------------------------------------------------------------------
# Public helpers
# -------------------------------------------------------------------

func get_current_seconds() -> int:
	return current_time_seconds

func get_current_minutes() -> int:
	return current_time_seconds / 60

# Returns HH:MM string (24-hour style)
func format_time(total_minutes: int) -> String:
	var hours: int = total_minutes / 60
	var mins: int = total_minutes % 60
	return "%02d:%02d" % [hours, mins]

# Resets the timer (e.g., for restarting scenarios)
func reset_time() -> void:
	current_time_seconds = 0
	_accum = 0.0
