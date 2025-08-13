extends HBoxContainer
class_name SearchRow

signal action_pressed(item: Dictionary)

@onready var desc_label: Label = $DescLabel
@onready var time_label: Label = $TimeLabel
@onready var action_btn: Button = $ActionButton

var item: Dictionary = {}

func _ready() -> void:
	# keep spacing consistent and text readable regardless of theme
	add_theme_constant_override("separation", 8)
	desc_label.add_theme_color_override("font_color", Color.BLACK)
	time_label.add_theme_color_override("font_color", Color.BLACK)
	action_btn.pressed.connect(_on_action_pressed)

# Reuse for treatments or tests by changing keys via config
# config:
#   text_key   (default "name")
#   time_key   (default "minutes")
#   time_suffix (default " min")
#   button_text (default "Apply")
func set_data(new_item: Dictionary, config: Dictionary = {}) -> void:
	if not is_inside_tree():
		await ready  # ensure @onready vars exist
	item = new_item

	var text_key  = config.get("text_key", "name")
	var time_key  = config.get("time_key", "minutes")
	var suffix    = config.get("time_suffix", " min")
	var btn_text  = config.get("button_text", "Apply")

	desc_label.text = str(item.get(text_key, ""))
	time_label.text = (str(item[time_key]) + suffix) if item.has(time_key) else ""
	action_btn.text = btn_text

func _on_action_pressed() -> void:
	emit_signal("action_pressed", item)
