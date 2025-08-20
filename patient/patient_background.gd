extends Control
class_name PatientBackground

# ---------------- Patient data (kept) ----------------
var pending_patient: Patient = null

@onready var pt_photo: TextureRect    = $bg/PT_photo
@onready var case_data: RichTextLabel = $bg/Case_data  # stays in place; handles its own scroll
@onready var pt_data: Label           = $bg/Pt_data

# ---------------- Buttons & popup ----------------
@onready var btn_wait: Button     = $Main_Buttons/wait
@onready var btn_test: Button     = $Main_Buttons/test
@onready var btn_treat: Button    = $Main_Buttons/treat
@onready var btn_help: Button     = $Main_Buttons/help
@onready var btn_dx: Button       = $Main_Buttons/dx
@onready var btn_present: Button  = $Main_Buttons/present

@onready var popup_panel: Panel    = $Bg_pop_up_panel
@onready var search_box: LineEdit  = $Bg_pop_up_panel/MarginContainer/HBoxContainer/searchBox

# Popup content root (header + layers)
var list_root: VBoxContainer = null
var header_row: Control = null
var initial_results: VBoxContainer = null

# Optional per‑patient log
var log_container: VBoxContainer = null

# ---------------- External services ----------------
var treatment_manager: TreatmentManager
var time_system: TimeSystem

const SEARCH_ROW_SCENE: PackedScene = preload("res://ui/search/search.tscn")

# ---------------- Modes ----------------
enum SearchMode { TREATMENT, TEST, CONSULT, DX, PRESENT }
var patient_id: String = ""
var search_mode: int = SearchMode.TREATMENT
var last_query_by_mode: Array = ["", "", "", "", ""]

# Per‑mode layers
var treat_layer: VBoxContainer = null
var test_layer: VBoxContainer = null
var consult_layer: VBoxContainer = null
var dx_layer: VBoxContainer = null
var present_layer: VBoxContainer = null

# TREAT subnodes
var treat_active_box: VBoxContainer = null     # pinned rows
var treat_results_list: VBoxContainer = null   # transient search rows

# Simple state buckets
var state := {
	"treatments": [],
	"tests": [],
	"consults": [],
	"dx": [],
	"present": []
}

# --- NEW: track where each treatment line lives inside Case_data -------------
var treatment_line_by_name: Dictionary = {}  # name -> int (line index)
# -----------------------------------------------------------------------------

func _ready() -> void:
	if has_node("LogContainer"):
		log_container = $LogContainer as VBoxContainer

	# Ensure Case_data is ready to accept BBCode + selection + autowrap
	case_data.bbcode_enabled = true
	case_data.selection_enabled = true
	case_data.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_resolve_popup_nodes()
	_build_mode_layers()

	# Wire buttons
	btn_test.pressed.connect(_open_panel_for.bind(SearchMode.TEST))
	btn_treat.pressed.connect(_open_panel_for.bind(SearchMode.TREATMENT))
	btn_help.pressed.connect(_open_panel_for.bind(SearchMode.CONSULT))
	btn_dx.pressed.connect(_open_panel_for.bind(SearchMode.DX))
	btn_present.pressed.connect(_open_panel_for.bind(SearchMode.PRESENT))
	btn_wait.pressed.connect(_on_wait_pressed)

	search_box.text_changed.connect(_on_search_changed)
	_show_treat_placeholder("Please type a term in the search box above")

	# Fill patient UI
	if pending_patient != null:
		_set_patient_fields()

	# Timers
	if time_system and time_system.has_signal("updated"):
		if not time_system.updated.is_connected(_on_time_updated):
			time_system.updated.connect(_on_time_updated)

	_set_visible_layer(SearchMode.TREATMENT)

func set_patient(patient: Patient) -> void:
	pending_patient = patient
	patient_id = patient.id
	if case_data != null and pt_data != null:
		_set_patient_fields()

func set_services(treat_mgr: TreatmentManager, time_sys: TimeSystem) -> void:
	treatment_manager = treat_mgr
	time_system = time_sys
	if time_system and time_system.has_signal("updated"):
		if not time_system.updated.is_connected(_on_time_updated):
			time_system.updated.connect(_on_time_updated)

# ---------------- Popup resolve/build ----------------
func _resolve_popup_nodes() -> void:
	var base := $Bg_pop_up_panel.get_node_or_null("MarginContainer2/VBoxContainer")
	list_root = base as VBoxContainer
	if list_root != null:
		header_row = list_root.get_node_or_null("header")
		initial_results = list_root.get_node_or_null("results") as VBoxContainer

func _build_mode_layers() -> void:
	if list_root == null:
		push_error("[PatientBackground] Missing VBoxContainer under Bg_pop_up_panel/MarginContainer2.")
		return

	# Treat
	treat_layer = list_root.get_node_or_null("TreatLayer") as VBoxContainer
	if treat_layer == null:
		treat_layer = VBoxContainer.new(); treat_layer.name = "TreatLayer"; list_root.add_child(treat_layer)

	treat_active_box = treat_layer.get_node_or_null("active") as VBoxContainer
	if treat_active_box == null:
		treat_active_box = VBoxContainer.new(); treat_active_box.name = "active"; treat_layer.add_child(treat_active_box)

	treat_results_list = treat_layer.get_node_or_null("results") as VBoxContainer
	if treat_results_list == null:
		if initial_results != null and is_instance_valid(initial_results):
			initial_results.reparent(treat_layer)
			initial_results.name = "results"
			treat_results_list = initial_results
		else:
			treat_results_list = VBoxContainer.new(); treat_results_list.name = "results"; treat_layer.add_child(treat_results_list)

	if header_row != null:
		var children := list_root.get_children()
		var hdr_idx := children.find(header_row)
		if hdr_idx != -1:
			list_root.move_child(treat_layer, hdr_idx + 1)

	# Other layers (placeholders)
	test_layer = _ensure_layer_with_placeholder("TestLayer", "Functionality coming soon")
	consult_layer = _ensure_layer_with_placeholder("ConsultLayer", "Functionality coming soon")
	dx_layer = _ensure_layer_with_placeholder("DxLayer", "Functionality coming soon")
	present_layer = _ensure_layer_with_placeholder("PresentLayer", "Functionality coming soon")

func _ensure_layer_with_placeholder(name_str: String, text: String) -> VBoxContainer:
	var layer := list_root.get_node_or_null(name_str) as VBoxContainer
	if layer == null:
		layer = VBoxContainer.new()
		layer.name = name_str
		list_root.add_child(layer)
	for n in layer.get_children():
		n.queue_free()
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color.BLACK)
	layer.add_child(lbl)
	return layer

# ---------------- Patient text/photo (kept) ----------------
func _set_patient_fields() -> void:
	if case_data and pt_data and pending_patient:
		case_data.text = pending_patient.TEXT
		pt_data.text = "Sex: %s\nAge: %d\nHR: %d\nBP: %s\nSpO2: %d%%\nResp Rate: %d\nTemp: %.1f" % [
			pending_patient.SEX,
			pending_patient.AGE,
			pending_patient.HR,
			pending_patient.BP,
			pending_patient.SPO2,
			pending_patient.RESP_R,
			pending_patient.Temp
		]
		var photo_path = "res://art/%s.png" % pending_patient.Case_code
		if ResourceLoader.exists(photo_path):
			pt_photo.texture = load(photo_path)
		else:
			pt_photo.texture = load("res://art/placeholder.png")

# ---------------- Layer visibility + search routing ----------------
func _set_visible_layer(mode: int) -> void:
	if treat_layer != null:  treat_layer.visible = (mode == SearchMode.TREATMENT)
	if test_layer != null:   test_layer.visible  = (mode == SearchMode.TEST)
	if consult_layer != null:consult_layer.visible = (mode == SearchMode.CONSULT)
	if dx_layer != null:     dx_layer.visible    = (mode == SearchMode.DX)
	if present_layer != null:present_layer.visible = (mode == SearchMode.PRESENT)

func _open_panel_for(mode: int) -> void:
	search_mode = mode
	popup_panel.visible = true
	_set_visible_layer(mode)

	var q := search_box.text.strip_edges()
	var last_q := last_query_by_mode[mode] as String

	if mode != SearchMode.TREATMENT:
		return

	if (treat_results_list == null) or (treat_active_box == null):
		push_error("[PatientBackground] Treat layer not initialized.")
		return

	if q == last_q and (treat_results_list.get_child_count() > 0 or treat_active_box.get_child_count() > 0):
		return

	if q == "":
		_show_treat_placeholder("Please type a term in the search box above")
	else:
		_perform_treat_search(q)
		last_query_by_mode[mode] = q

func _on_search_changed(new_text: String) -> void:
	if not popup_panel.visible:
		return
	if search_mode != SearchMode.TREATMENT:
		return
	if (treat_results_list == null):
		return

	var q := new_text.strip_edges()
	if q == "":
		_show_treat_placeholder("Please type a term in the search box above")
		last_query_by_mode[SearchMode.TREATMENT] = ""
	else:
		if q != (last_query_by_mode[SearchMode.TREATMENT] as String):
			_perform_treat_search(q)
			last_query_by_mode[SearchMode.TREATMENT] = q

# ---------------- TREAT search & rows ----------------
func _perform_treat_search(q: String) -> void:
	_clear_treat_results_only()

	var results: Array = treatment_manager.search_treatments(q)
	if results.is_empty():
		_show_treat_placeholder("There are no results for the term you used. Try another keyword.")
		return

	for item in results:
		if _treat_has_active_row_for(item):
			continue

		var row_node: Node = SEARCH_ROW_SCENE.instantiate()
		treat_results_list.add_child(row_node)

		var row := row_node as SearchRow
		if row == null:
			push_error("SearchRow.tscn is missing SearchRow.gd (cast failed).")
			continue

		row.set_data(item, {
			"text_key": "name",
			"time_key": "minutes",
			"time_suffix": " min",
			"button_text": "Apply"
		})

		row.action_pressed.connect(_on_treat_row_start)
		row.treatment_finished.connect(_on_treat_finished)
		row.show_results.connect(_on_treat_show_results)

func _on_treat_row_start(item: Dictionary) -> void:
	if (treat_results_list == null) or (treat_active_box == null):
		return

	var duration: int = int(item.get("minutes", 0))
	var current_time_min: int = time_system.get_current_minutes()

	if _treat_has_active_row_for(item):
		return

	for child in treat_results_list.get_children():
		if child is SearchRow and child.item == item:
			child.start_treatment(duration, current_time_min)
			child.reparent(treat_active_box)
			child.set_meta("pinned", true)
			break

func _on_treat_finished(item: Dictionary, finished_time_seconds: int) -> void:
	var when_str := time_system.format_time(int(finished_time_seconds / 60))
	var name_str := str(item.get("name", "Unknown"))
	var log_entry := "%s applied at %s" % [name_str, when_str]
	state["treatments"].append(log_entry)
	_add_log(log_entry)

	# Append a line inside Case_data itself so it scrolls with the case
	_append_treatment_to_case_data(name_str)

func _on_treat_show_results(item: Dictionary) -> void:
	var name_str := str(item.get("name", "Unknown"))
	_scroll_and_flash_case_line(name_str)

# ---------------- Timers (TREAT) ----------------
func _on_time_updated(dt: DateTime) -> void:
	if treat_active_box == null or treat_results_list == null:
		return
	var secs := dt.get_minutes_total() * 60 + int(dt.second)

	for child in treat_active_box.get_children():
		if child is SearchRow:
			child.on_time_changed(secs)

	for child in treat_results_list.get_children():
		if child is SearchRow:
			child.on_time_changed(secs)

# ---------------- Wait button ----------------
func _on_wait_pressed() -> void:
	if time_system == null:
		return
	var t := time_system.format_time(time_system.get_current_minutes())
	_add_log("Waited at %s" % t)

# ---------------- Helpers ----------------
func _add_log(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", Color.BLACK)
	if log_container != null:
		log_container.add_child(lbl)
	else:
		add_child(lbl)

func _clear_treat_results_only() -> void:
	if treat_results_list == null:
		return
	for child in treat_results_list.get_children():
		child.queue_free()

func _show_treat_placeholder(msg: String) -> void:
	_clear_treat_results_only()
	if treat_results_list == null:
		return
	var lbl := Label.new()
	lbl.text = msg
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color.BLACK)
	treat_results_list.add_child(lbl)

func _treat_has_active_row_for(item: Dictionary) -> bool:
	if treat_active_box == null:
		return false
	var key := str(item.get("name", ""))
	for child in treat_active_box.get_children():
		if child is SearchRow:
			var nm := str(child.item.get("name", ""))
			if nm == key:
				return true
	return false

# ---------------- Case_data: append + highlight + scroll ----------------
func _append_treatment_to_case_data(name_str: String) -> void:
	# Record line index BEFORE we append (the new content will start at this index)
	var line_idx := case_data.get_line_count()

	# Append with BBCode; \n ensures it starts on a new line
	var bb := "\n[font_size=14][color=green]• %s[/color][/font_size]\n" % name_str
	case_data.append_text(bb)

	# Store where this treatment lives
	treatment_line_by_name[name_str] = line_idx

	# Optionally auto-scroll to the end so player sees new entry
	case_data.scroll_to_line(case_data.get_line_count() - 1)

func _scroll_and_flash_case_line(name_str: String) -> void:
	if not treatment_line_by_name.has(name_str):
		return
	var line := int(treatment_line_by_name[name_str])

	# Bring line into view
	case_data.scroll_to_line(line)

	# Brief highlight by selecting the whole line (selection is visible)
	case_data.deselect()
	case_data.selection_enabled = true
	# Select from start to a big column span to cover the line
	# Godot 4 RichTextLabel.select(from_line, from_col, to_line, to_col)
	case_data.select(line, 0, line, 1000)

	var timer := get_tree().create_timer(1.2)
	timer.timeout.connect(func ():
		if is_instance_valid(case_data):
			case_data.deselect()
	)
