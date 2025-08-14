# -----------------------------------------------------------------------------
# SearchRow.gd  (attach to res://ui/search/search.tscn)
# Ultra-defensive: explicit typing, stringify everything, banner logs
# -----------------------------------------------------------------------------

extends HBoxContainer
class_name SearchRow

const VERSION: String = "SearchRow v1.3 (ultra-safe)"

# ---------------------------- Signals ----------------------------------------
signal action_pressed(item: Dictionary)
signal treatment_finished(item: Dictionary, finished_time: int)
signal show_results(item: Dictionary)

# --------------------------- Child node refs ---------------------------------
@onready var desc_label: Label  = $DescLabel
@onready var time_label: Label  = $TimeLabel
@onready var action_btn: Button = $ActionButton

# --------------------------- State machine -----------------------------------
enum TreatmentState { IDLE, IN_PROGRESS, COMPLETE }

var state: int = TreatmentState.IDLE           # explicit int
var end_time_seconds: int = 0
var item: Dictionary = {}

# -----------------------------------------------------------------------------
# Convert ANY value to a safe string for Label.text
func _to_label_string(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return ""
		TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL:
			return str(value)
		_:
			# Dictionary / Array / other complex types → JSON text
			return JSON.stringify(value)

# Set label text SAFELY (with debug prints)
func _safe_set_label_text(label: Label, raw_value: Variant, label_name: String) -> void:
	var t: int = typeof(raw_value)
	#print("[SearchRow] setting ", label_name, " typeof=", t) # uncomment if needed
	label.text = _to_label_string(raw_value)

# -----------------------------------------------------------------------------
func _ready() -> void:
	print(VERSION, " | script=", get_script().resource_path)
	add_theme_constant_override("separation", 8)
	desc_label.add_theme_color_override("font_color", Color.BLACK)
	time_label.add_theme_color_override("font_color", Color.BLACK)
	action_btn.pressed.connect(_on_action_pressed)

# -----------------------------------------------------------------------------
# Configure the row with an item and optional key mapping.
# config keys (all strings): text_key, time_key, time_suffix, button_text
func set_data(new_item: Dictionary, config: Dictionary = {}) -> void:
	if not is_inside_tree():
		await ready

	item = new_item

	# --- EXPLICIT TYPES (avoid Variant inference) ----------------------------
	var text_key: String    = str(config.get("text_key", "name"))
	var time_key: String    = str(config.get("time_key", "minutes"))
	var time_suffix: String = str(config.get("time_suffix", " min"))
	var btn_text: String    = str(config.get("button_text", "Apply"))

	# Safe description text
	var raw_desc: Variant = item.get(text_key, "")
	_safe_set_label_text(desc_label, raw_desc, "DescLabel")

	# Safe time text (only show if non-empty after stringify)
	var raw_time: Variant = item.get(time_key, "")
	var time_str: String = _to_label_string(raw_time)
	time_label.text = (time_str + time_suffix) if time_str != "" else ""

	# Initial button look/state
	action_btn.text = btn_text
	action_btn.modulate = Color(0, 1, 0)  # Green
	state = TreatmentState.IDLE

# -----------------------------------------------------------------------------
# Start countdown. API expects MINUTES, and current time in MINUTES.
func start_treatment(duration_minutes: int, current_time_minutes: int) -> void:
	state = TreatmentState.IN_PROGRESS
	var start_seconds: int = current_time_minutes * 60
	var duration_seconds: int = duration_minutes * 60
	end_time_seconds = start_seconds + duration_seconds
	action_btn.modulate = Color(1, 1, 0)  # Yellow

# -----------------------------------------------------------------------------
# Minutes-based tick (what index.gd calls)
func on_minute_changed(current_time_minutes: int) -> void:
	var current_seconds: int = current_time_minutes * 60
	_on_time_changed_seconds(current_seconds)

# -----------------------------------------------------------------------------
# Seconds-based tick (if you later emit seconds)
func on_time_changed(current_time_seconds: int) -> void:
	_on_time_changed_seconds(current_time_seconds)

# -----------------------------------------------------------------------------
# Core countdown logic (seconds)
func _on_time_changed_seconds(current_time_seconds: int) -> void:
	if state != TreatmentState.IN_PROGRESS:
		return

	var remaining: int = end_time_seconds - current_time_seconds

	if remaining > 0:
		var mins: int = remaining / 60
		var secs: int = remaining % 60
		time_label.text = "%02d:%02d" % [mins, secs]  # countdown shown here
		return

	# Finished → blue Results
	state = TreatmentState.COMPLETE
	time_label.text = ""                 # hide countdown in blue state
	action_btn.text = "Results"
	action_btn.modulate = Color(0, 0, 1) # Blue
	emit_signal("treatment_finished", item, current_time_seconds)

# -----------------------------------------------------------------------------
# Button behavior by state
func _on_action_pressed() -> void:
	match state:
		TreatmentState.COMPLETE:
			emit_signal("show_results", item)
		_:
			emit_signal("action_pressed", item)
