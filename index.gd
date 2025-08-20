extends Control

# -----------------------------------------------------------------------------
# Scene references (same as your working layout, plus "orders")
# -----------------------------------------------------------------------------
var PATIENT_BACKGROUND = preload("res://patient_background.tscn")
@onready var pt_profile: Panel = $bg_green/Pt_profile

var button_theme = preload("res://styles/new1.0.tres")
@onready var pt_list: VBoxContainer = $bg_green/pt_list

@onready var patient_manager: PatientManagerB = $PatientManagerB

var pt_buttons: Array[Button] = []
var pt_backgrounds: Array = []

@onready var bg_popup_panel: Panel = $Bg_pop_up_panel

# IMPORTANT: add this node in the scene (see instructions above)
@onready var orders_list: VBoxContainer = $Bg_pop_up_panel/MarginContainer2/VBoxContainer/orders
@onready var results_list: VBoxContainer = $Bg_pop_up_panel/MarginContainer2/VBoxContainer/results

@onready var search_box: LineEdit = $Bg_pop_up_panel/MarginContainer/HBoxContainer/searchBox
@onready var treatment_manager: TreatmentManager = $TreatmentManager
<<<<<<< HEAD
<<<<<<< HEAD
@onready var time_system: TimeSystem = $TimeSystem
=======
=======

>>>>>>> parent of c24c9b7 (working search very happy!)

>>>>>>> parent of c24c9b7 (working search very happy!)

const SEARCH_ROW_SCENE: PackedScene = preload("res://ui/search/search.tscn")

# -----------------------------------------------------------------------------
# Modes (future: Test / Consult / DX / Present)
# -----------------------------------------------------------------------------
enum SearchMode { TREATMENT, TEST, CONSULT, DX, PRESENT }
var search_mode: int = SearchMode.TREATMENT

# -----------------------------------------------------------------------------
# Selection + per-patient memory
# -----------------------------------------------------------------------------
var current_patient_index: int = 0      # which background is visible
var current_patient_id: String = ""     # stable key like "GI|Wang"

# id -> buckets (orders = persistent rows; treatments = textual log)
# orders elements look like:
#   {
#     "item": Dictionary,          # original treatment/test dictionary
#     "duration_min": int,         # duration minutes
#     "start_min": int,            # when player pressed Apply
#     "status": String,            # "in_progress" | "complete"
#     "finished_min": int          # present when status == "complete"
#   }
var per_patient: Dictionary = {}

func _ensure_state(id: String) -> Dictionary:
	if not per_patient.has(id):
		per_patient[id] = {
			"orders": [],      # Array[Dictionary] -- persistent UI items for this patient
			"treatments": [],  # Array[String] logs ("X applied at HH:MM")
			"tests": [],
			"consults": [],
			"dx": [],
			"present": []
		}
	return per_patient[id]

# -----------------------------------------------------------------------------
# (Optional) simple, placeholder timed event system you can extend later
# -----------------------------------------------------------------------------
var patient_meta: Dictionary = {}   # id -> { "enter_min": int, "scheduled": Array[Dictionary], "fired": Array[Dictionary] }

func _ensure_patient_meta(id: String) -> void:
	if patient_meta.has(id):
		return
	var enter_min: int = time_system.get_current_minutes()
	patient_meta[id] = {
		"enter_min": enter_min,
		"scheduled": _make_default_events_for(id),
		"fired": []
	}

func _make_default_events_for(id: String) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []
	arr.append({
		"offset_min": 5,
		"type": "complaint",
		"message": "Patient %s complains about waiting." % id
	})
	arr.append({
		"offset_min": 12,
		"type": "deterioration",
		"message": "Patient %s looks worse. Vitals may be changing soon." % id
	})
	return arr

func _tick_patient_events(now_min: int) -> void:
	for id in patient_meta.keys():
		var meta: Dictionary = patient_meta[id]
		var enter_min: int = int(meta.get("enter_min", 0))

		var scheduled: Array[Dictionary] = []
		var s_raw = meta.get("scheduled", [])
		if s_raw is Array:
			for v in s_raw:
				if v is Dictionary:
					scheduled.append(v)

		var fired: Array[Dictionary] = []
		var f_raw = meta.get("fired", [])
		if f_raw is Array:
			for v in f_raw:
				if v is Dictionary:
					fired.append(v)

		var to_remove: Array[int] = []
		for i in scheduled.size():
			var ev: Dictionary = scheduled[i]
			var offset: int = int(ev.get("offset_min", 0))
			if now_min >= (enter_min + offset):
				_log_patient_event(id, ev)
				fired.append(ev)
				to_remove.append(i)

		for k in to_remove.size():
			var idx: int = to_remove[to_remove.size() - 1 - k]
			scheduled.remove_at(idx)

		meta["scheduled"] = scheduled
		meta["fired"] = fired
		patient_meta[id] = meta

func _log_patient_event(id: String, ev: Dictionary) -> void:
	var msg: String = str(ev.get("message", "An event occurred."))
	var lbl := Label.new()
	lbl.text = "[EVENT] " + msg
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if id == current_patient_id:
		# OLD (causes inference issue):
		# var bg := (pt_backgrounds[current_patient_index] if current_patient_index < pt_backgrounds.size() else null)

		# NEW: explicit type + simple assignment
		var bg: Node = null
		if current_patient_index < pt_backgrounds.size():
			bg = pt_backgrounds[current_patient_index]

		if bg != null and bg.has_node("LogContainer"):
			bg.get_node("LogContainer").add_child(lbl)
		else:
			pt_profile.add_child(lbl)
	else:
		pt_profile.add_child(lbl)


# -----------------------------------------------------------------------------
# Ready / setup
# -----------------------------------------------------------------------------
func _ready() -> void:
	# Drive countdowns and events every second
	time_system.second_changed.connect(_on_second_changed)

	# Debug prints you had
	print("CSV in CSV folder? ", FileAccess.file_exists("res://CSV/NLI_CS1.csv"))
	print("CSV in root? ", FileAccess.file_exists("res://NLI_CS1.csv"))
	print("index.gd _ready() running")
	print("pt_profile is: ", pt_profile)
	print("pt_list is: ", pt_list)
	print("patient_manager is: ", patient_manager)

	# When patients are loaded, build UI
	patient_manager.patients_loaded.connect(_on_patients_loaded)

	# Main popup buttons (existing)
	for button in $bg_green/Main_Buttons.get_children():
		if button is Button:
			button.pressed.connect(_on_main_button_pressed)

	# Search reacts as you type
	search_box.text_changed.connect(_on_search_box_text_changed)
<<<<<<< HEAD
<<<<<<< HEAD

# -----------------------------------------------------------------------------
# Search UI (results_list is ephemeral — safe to clear)
# -----------------------------------------------------------------------------
func _on_search_box_text_changed(new_text: String) -> void:
	var q: String = new_text.strip_edges()
	if q == "":
		_show_placeholder("Please type a term in the search box above")
		return

	var results: Array = treatment_manager.search_treatments(q)
	if results.is_empty():
		_show_placeholder("There are no results for the term you used. Try another keyword.")
	else:
		display_search_results(results)

func display_search_results(results: Array) -> void:
	# Keep header at index 0 in results_list, clear everything else in results_list ONLY.
	# We DO NOT touch orders_list here — that’s the persistent list.
=======
=======
>>>>>>> parent of c24c9b7 (working search very happy!)
	
func _on_search_box_text_changed(new_text):
	var results = treatment_manager.search_treatments(new_text)
	display_search_results(results)

func display_search_results(results: Array) -> void:
	print("Displaying results: ", results.size())
	# Remove old results
<<<<<<< HEAD
>>>>>>> parent of c24c9b7 (working search very happy!)
=======
>>>>>>> parent of c24c9b7 (working search very happy!)
	for i in range(1, results_list.get_child_count()):
		results_list.get_child(i).queue_free()
	# Add new results
	for treatment in results:
		var row = HBoxContainer.new()

<<<<<<< HEAD
<<<<<<< HEAD
	for item in results:
		var row_node: Node = SEARCH_ROW_SCENE.instantiate()
		results_list.add_child(row_node)

		var row := row_node as SearchRow
		if row == null:
			push_error("SearchRow.tscn is missing the SearchRow.gd script (cast failed).")
			continue

		row.set_data(item, {
			"text_key": "name",
			"time_key": "minutes",
			"time_suffix": " min",
			"button_text": "Apply"
		})

		# IMPORTANT:
		# - action_pressed → we'll MOVE this row to orders_list and start timer
		# - treatment_finished → record a log line and mark order as complete
		# - show_results → future hook (scroll to log line)
		row.action_pressed.connect(_on_row_start_treatment)
		row.treatment_finished.connect(_on_treatment_finished)
		row.show_results.connect(_on_show_results)

# -----------------------------------------------------------------------------
# “Apply” was pressed on a result row
# -----------------------------------------------------------------------------
func _on_row_start_treatment(item: Dictionary) -> void:
	if current_patient_id == "":
		push_warning("No current patient selected; ignoring action.")
		return

	var duration: int = int(item.get("minutes", 0))
	var start_min: int = time_system.get_current_minutes()

	# 1) Find the row in results_list, remove it, and attach it to orders_list.
	#    Keeping the same node preserves its connections and countdown logic.
	var moved: bool = false
	for child in results_list.get_children():
		if child is SearchRow and (child as SearchRow).item == item:
			results_list.remove_child(child)
			orders_list.add_child(child)
			(child as SearchRow).start_treatment(duration, start_min)
			moved = true
			break

	# 2) Persist this order into per-patient state so it restores on tab switch.
	var state := _ensure_state(current_patient_id)
	if not state.has("orders"):
		state["orders"] = []
	var orders: Array = state["orders"]

	orders.append({
		"item": item,
		"duration_min": duration,
		"start_min": start_min,
		"status": "in_progress"
	})
	state["orders"] = orders
	per_patient[current_patient_id] = state

	# 3) If the row wasn't found in results (edge-case), instantiate a fresh one directly in orders_list.
	if not moved:
		var row_node: Node = SEARCH_ROW_SCENE.instantiate()
		orders_list.add_child(row_node)
		var row := row_node as SearchRow
		row.set_data(item, {
			"text_key": "name",
			"time_key": "minutes",
			"time_suffix": " min",
			"button_text": "Apply"
		})
		row.action_pressed.connect(_on_row_start_treatment)
		row.treatment_finished.connect(_on_treatment_finished)
		row.show_results.connect(_on_show_results)
		row.start_treatment(duration, start_min)

# -----------------------------------------------------------------------------
# A row finished (turned blue): log + mark the corresponding order “complete”
# -----------------------------------------------------------------------------
func _on_treatment_finished(item: Dictionary, finished_time: int) -> void:
	var name_str: String = str(item.get("name", "Unknown"))
	var log_entry: String = "%s applied at %s" % [name_str, time_system.format_time(finished_time)]

	# 1) Append a human-readable log line (unchanged behavior)
	var state := _ensure_state(current_patient_id)
	state["treatments"].append(log_entry)

	# 2) Mark the structured order complete (so it restores blue on tab switch)
	var orders: Array = state.get("orders", [])
	for i in orders.size():
		var o: Dictionary = orders[i]
		if str(o.get("item", {}).get("name", "")) == name_str and str(o.get("status","")) != "complete":
			o["status"] = "complete"
			o["finished_min"] = finished_time
			orders[i] = o
			break
	state["orders"] = orders
	per_patient[current_patient_id] = state

	# 3) Show the log line in the current patient’s profile area
	var log_label := Label.new()
	log_label.text = log_entry
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

# OLD (causes inference issue):
# var bg := (pt_backgrounds[current_patient_index] if current_patient_index < pt_backgrounds.size() else null)

# NEW: explicit type + simple assignment
	var bg: Node = null
	if current_patient_index < pt_backgrounds.size():
		bg = pt_backgrounds[current_patient_index]

	if bg != null and bg.has_node("LogContainer"):
		bg.get_node("LogContainer").add_child(log_label)
	else:
		pt_profile.add_child(log_label)


# -----------------------------------------------------------------------------
# Time tick: update BOTH lists (orders_list + results_list) and fire events
# -----------------------------------------------------------------------------
func _on_second_changed(current_time_seconds: int) -> void:
	for child in orders_list.get_children():
		if child is SearchRow:
			(child as SearchRow).on_time_changed(current_time_seconds)

	# You can keep updating results rows too (handy if you ever keep timers there)
	for child in results_list.get_children():
		if child is SearchRow:
			(child as SearchRow).on_time_changed(current_time_seconds)

	# Fire placeholder timed events (per-patient)
	var now_min: int = int(current_time_seconds / 60)
	_tick_patient_events(now_min)

# -----------------------------------------------------------------------------
# Popup button (open search panel)
# -----------------------------------------------------------------------------
func _on_main_button_pressed() -> void:
	if not bg_popup_panel.visible:
		bg_popup_panel.visible = true
		var q: String = search_box.text.strip_edges()
		if q == "":
			_show_placeholder("Please type a term in the search box above")
		else:
			var results: Array = treatment_manager.search_treatments(q)
			if results.is_empty():
				_show_placeholder("There are no results for the term you used. Try another keyword.")
			else:
				display_search_results(results)
=======
=======
>>>>>>> parent of c24c9b7 (working search very happy!)
		var name_label = Label.new()
		name_label.text = treatment["name"]
		name_label.add_theme_color_override("font_color", Color.BLACK)
		row.add_child(name_label)

		var min_label = Label.new()
		min_label.text = str(treatment["minutes"]) + " min"
		min_label.add_theme_color_override("font_color", Color.BLACK)
		row.add_child(min_label)

		var action_btn = Button.new()
		action_btn.text = "Do Action"
		# Attach treatment info or index if you need it later:
		action_btn.pressed.connect(_on_treatment_action_pressed.bind(treatment))
		row.add_child(action_btn)

		results_list.add_child(row)

func _on_treatment_action_pressed(treatment):
	print("Action for treatment: ", treatment["name"])
	# Here you can call any function you want, or pass the treatment object further.
	
func _on_main_button_pressed(): #this is to make the popup visible
	if not bg_popup_panel.visible:
		bg_popup_panel.visible = true
<<<<<<< HEAD
=======

>>>>>>> parent of c24c9b7 (working search very happy!)

>>>>>>> parent of c24c9b7 (working search very happy!)

# -----------------------------------------------------------------------------
# Build patient list + backgrounds after CSV has loaded
# -----------------------------------------------------------------------------
func _on_patients_loaded() -> void:
	print("Patients loaded! Building UI... count: ", patient_manager.patients.size())
	_build_patient_ui()

func _build_patient_ui() -> void:
	pt_buttons.clear()
	for child in pt_profile.get_children():
		child.queue_free()
	pt_backgrounds.clear()
	for child in pt_list.get_children():
		child.queue_free()

	# Buttons per patient
	for i in patient_manager.patients.size():
		var btn := Button.new()
		var patient: Patient = patient_manager.patients[i]
		btn.text = patient.name
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.theme = button_theme

		var pid: String = patient.id
		btn.pressed.connect(_on_patient_pressed.bind(i, pid))

		pt_list.add_child(btn)
		pt_buttons.append(btn)

	# Backgrounds
	for i in patient_manager.patients.size():
		var patient: Patient = patient_manager.patients[i]
		var bg: Node = PATIENT_BACKGROUND.instantiate()
		if bg.has_method("set_patient"):
			bg.set_patient(patient)
		else:
			print("Background has NO set_patient method for: ", patient.name)
		pt_profile.add_child(bg)
		pt_backgrounds.append(bg)
		bg.visible = false

	_show_only_background(0)
	if pt_buttons.size() > 0:
		pt_buttons[0].disabled = true

# -----------------------------------------------------------------------------
# Switch patient: show the right background and REBUILD the orders list
# -----------------------------------------------------------------------------
func _on_patient_pressed(index: int, pid: String) -> void:
	print("Patient button pressed: ", index, " id=", pid)
	current_patient_index = index
	_show_only_background(index)

	for i in pt_buttons.size():
		pt_buttons[i].disabled = false
	pt_buttons[index].disabled = true

	current_patient_id = pid
	_ensure_state(pid)
	_ensure_patient_meta(pid)

	# Rebuild persistent orders for this patient
	_rebuild_orders_ui_for(pid)

	# Optional: refresh plain-text logs (if you want them in the popup list too)
	# _rebuild_text_logs_for(pid)  # left out to avoid clutter

# Build the orders_list from the saved structured state
func _rebuild_orders_ui_for(pid: String) -> void:
	# 1) Clear current UI nodes
	for child in orders_list.get_children():
		child.queue_free()

	# 2) Fetch saved orders
	var state := _ensure_state(pid)
	var orders: Array = state.get("orders", [])
	var now_min: int = time_system.get_current_minutes()

	for i in orders.size():
		var o: Dictionary = orders[i]
		var item: Dictionary = o.get("item", {})
		var duration_min: int = int(o.get("duration_min", 0))
		var start_min: int = int(o.get("start_min", now_min))
		var status: String = str(o.get("status", "in_progress"))

		# Create a row
		var row_node: Node = SEARCH_ROW_SCENE.instantiate()
		orders_list.add_child(row_node)
		var row := row_node as SearchRow
		row.set_data(item, {
			"text_key": "name",
			"time_key": "minutes",
			"time_suffix": " min",
			"button_text": "Apply"
		})
		row.action_pressed.connect(_on_row_start_treatment)
		row.treatment_finished.connect(_on_treatment_finished)
		row.show_results.connect(_on_show_results)

		# Recreate state:
		# - if still in progress: start with original start time and tick once
		# - if complete: start with a start time in the past so it flips to blue
		if status == "in_progress":
			row.start_treatment(duration_min, start_min)
			row.on_time_changed(now_min * 60)
		else:
			# force it to complete on first tick
			row.start_treatment(duration_min, start_min)
			row.on_time_changed((start_min + duration_min + 1) * 60)  # > end

# -----------------------------------------------------------------------------
# Background visibility
# -----------------------------------------------------------------------------
func _show_only_background(index: int) -> void:
	for i in pt_backgrounds.size():
		pt_backgrounds[i].visible = (i == index)
<<<<<<< HEAD
<<<<<<< HEAD

# -----------------------------------------------------------------------------
# Helpers for the results area (search list only)
# -----------------------------------------------------------------------------
func _show_placeholder(msg: String) -> void:
	# keep header at index 0, clear everything else in RESULTS ONLY
	for i in range(1, results_list.get_child_count()):
		results_list.get_child(i).queue_free()

	var lbl := Label.new()
	lbl.text = msg
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color.BLACK)
	results_list.add_child(lbl)
	
	
	# -------------------------------------------------------------------
# When a SearchRow is in COMPLETE (blue) state and user clicks it
# we get this callback. For now we just try to scroll/focus the
# latest matching log line in the visible patient area.
# -------------------------------------------------------------------
func _on_show_results(item: Dictionary) -> void:
	var name_str: String = str(item.get("name", "Unknown"))
	print("[RESULTS] Show results for: ", name_str)

	# 1) Try to find a LogContainer on the active patient's background
	var bg: Node = null
	if current_patient_index < pt_backgrounds.size():
		bg = pt_backgrounds[current_patient_index]

	if bg != null and bg.has_node("LogContainer"):
		var cont := bg.get_node("LogContainer")
		# naive highlight of last child
		if cont.get_child_count() > 0:
			var last := cont.get_child(cont.get_child_count() - 1)
			if last is Label:
				(last as Label).add_theme_color_override("font_color", Color.SKY_BLUE)
	else:
		# 2) Fallback: try to tint the last label directly under pt_profile
		if pt_profile.get_child_count() > 0:
			var last2 := pt_profile.get_child(pt_profile.get_child_count() - 1)
			if last2 is Label:
				(last2 as Label).add_theme_color_override("font_color", Color.SKY_BLUE)
=======
>>>>>>> parent of c24c9b7 (working search very happy!)
=======
>>>>>>> parent of c24c9b7 (working search very happy!)
