extends Control

var PATIENT_BACKGROUND = preload("res://patient_background.tscn")
@onready var pt_profile: Panel = $bg_green/Pt_profile

var button_theme = preload("res://styles/new1.0.tres")
@onready var pt_list: VBoxContainer = $bg_green/pt_list

@onready var patient_manager: PatientManagerB = $PatientManagerB

var pt_buttons: Array[Button] = []
var pt_backgrounds: Array = []

@onready var bg_popup_panel: Panel = $Bg_pop_up_panel
@onready var results_list: VBoxContainer = $Bg_pop_up_panel/MarginContainer2/VBoxContainer
@onready var search_box: LineEdit = $Bg_pop_up_panel/MarginContainer/HBoxContainer/searchBox
@onready var treatment_manager: TreatmentManager = $TreatmentManager

const SEARCH_ROW_SCENE: PackedScene = preload("res://ui/search/search.tscn") # 13/8 ensure correct scene + type

# --- NEW: modes for future Test/Consult/DX/Present support ----------------- # 13/8
enum SearchMode { TREATMENT, TEST, CONSULT, DX, PRESENT }                     # 13/8
var search_mode: int = SearchMode.TREATMENT                                   # 13/8
# ---------------------------------------------------------------------------- # 13/8

# --- Step 3.1: who is selected & per-patient memory ------------------------- # 13/8
var current_patient_index: int = 0              # UI highlight helper
var current_patient_id: String = ""             # stable identity (e.g., "GI|Wang")

# id -> buckets of actions taken for that patient
var per_patient: Dictionary = {}

func _ensure_state(id: String) -> Dictionary:
	if not per_patient.has(id):
		per_patient[id] = {
			"treatments": [],
			"tests": [],
			"consults": [],
			"dx": [],
			"present": []
		}
	return per_patient[id]
# ---------------------------------------------------------------------------- # 13/8


func _ready() -> void:
	print("CSV in CSV folder? ", FileAccess.file_exists("res://CSV/NLI_CS1.csv"))
	print("CSV in root? ", FileAccess.file_exists("res://NLI_CS1.csv"))
	
	
	print("index.gd _ready() running")
	print("pt_profile is: ", pt_profile)
	print("pt_list is: ", pt_list)
	print("patient_manager is: ", patient_manager)
	patient_manager.patients_loaded.connect(_on_patients_loaded)
	
	for button in $bg_green/Main_Buttons.get_children():
		if button is Button:
			button.pressed.connect(_on_main_button_pressed)
			
	search_box.text_changed.connect(_on_search_box_text_changed)


func _on_search_box_text_changed(new_text: String) -> void: # 13/8 typed
	var q: String = new_text.strip_edges()
	if q == "":
		_show_placeholder("Please type a term in the search box above") # 13/8
		return

	# For now, search treatments; later we’ll branch by search_mode           # 13/8
	var results: Array = treatment_manager.search_treatments(q)
	if results.is_empty():
		_show_placeholder("There are no results for the term you used. Try another keyword.") # 13/8
	else:
		display_search_results(results)


func display_search_results(results: Array) -> void:
	print("Displaying results: ", results.size())
	# keep header at index 0, clear the rest
	for i in range(1, results_list.get_child_count()):
		results_list.get_child(i).queue_free()

	# add 1 SearchRow per result
	for item in results:
		# create node from scene and add to tree so @onready runs
		var row_node: Node = SEARCH_ROW_SCENE.instantiate()                      # 13/8 (robust instancing)
		results_list.add_child(row_node)                                         # 13/8

		# cast to your script type so we can call set_data()
		var row := row_node as SearchRow                                         # 13/8
		if row == null:                                                          # 13/8
			push_error("SearchRow.tscn is missing the SearchRow.gd script (cast failed).") # 13/8
			continue                                                             # 13/8

		# fill the row (treatment config for now)
		row.set_data(item, {
			"text_key": "name",
			"time_key": "minutes",
			"time_suffix": " min",
			"button_text": "Apply"
		})
		row.action_pressed.connect(_on_search_row_action) # button callback


# --- Step 3.4: write actions to the active patient's bucket ----------------- # 13/8
func _on_search_row_action(item: Dictionary) -> void:
	if current_patient_id == "":
		push_warning("No current patient selected; ignoring action.")
		return

	var state := _ensure_state(current_patient_id)

	match search_mode:
		SearchMode.TREATMENT:
			state["treatments"].append(item)
			print("[STATE] Added treatment for", current_patient_id, ":", item.get("name",""))
		SearchMode.TEST:
			state["tests"].append(item)
			print("[STATE] Added test for", current_patient_id, ":", item.get("name",""))
		SearchMode.CONSULT:
			state["consults"].append(item)
			print("[STATE] Added consult for", current_patient_id, ":", item.get("name",""))
		SearchMode.DX:
			state["dx"].append(item)
			print("[STATE] Added dx for", current_patient_id, ":", item.get("name",""))
		SearchMode.PRESENT:
			state["present"].append(item)
			print("[STATE] Added present item for", current_patient_id, ":", item.get("name",""))
# ---------------------------------------------------------------------------- # 13/8


func _on_treatment_action_pressed(treatment): # (kept for reference, unused now)
	print("Action for treatment: ", treatment["name"])
	# Here you can call any function you want, or pass the treatment object further.
	

func _on_main_button_pressed() -> void: # this is to make the popup visible
	if not bg_popup_panel.visible:
		bg_popup_panel.visible = true
		var q: String = search_box.text.strip_edges() # 13/8 typed
		if q == "":
			_show_placeholder("Please type a term in the search box above") # 13/8
		else:
			# For now: treatments; later branch by search_mode               # 13/8
			var results: Array = treatment_manager.search_treatments(q)
			if results.is_empty():
				_show_placeholder("There are no results for the term you used. Try another keyword.") # 13/8
			else:
				display_search_results(results)


func _on_patients_loaded() -> void:
	print("Patients loaded! Building UI... count: ", patient_manager.patients.size())
	_build_patient_ui()


func _build_patient_ui() -> void:
	print("Building UI for ", patient_manager.patients.size(), " patients")
	pt_buttons.clear()
	for child in pt_profile.get_children():
		child.queue_free()
	pt_backgrounds.clear()
	for child in pt_list.get_children():
		child.queue_free()

	# Create buttons for each patient
	for i in patient_manager.patients.size():
		var btn = Button.new()
		var patient = patient_manager.patients[i]
		btn.text = patient.name
		#print("Adding button for: ", patient.name)
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.theme = button_theme

		# --- Step 3.2: bind BOTH index and patient.id into the signal ------ # 13/8
		var pid: String = patient.id                         # from Patient.gd computed property
		btn.pressed.connect(_on_patient_pressed.bind(i, pid))# 13/8
		# -------------------------------------------------------------------

		pt_list.add_child(btn)
		pt_buttons.append(btn)

	# Create dynamic backgrounds for each patient
	for i in patient_manager.patients.size():
		var patient = patient_manager.patients[i]
		var bg = PATIENT_BACKGROUND.instantiate()
		#print("Instantiating background for: ", patient.name)
		if bg.has_method("set_patient"):
			#print("Calling set_patient for: ", patient.name)
			bg.set_patient(patient)
		else:
			print("Background has NO set_patient method for: ", patient.name)
		pt_profile.add_child(bg)
		pt_backgrounds.append(bg)
		bg.visible = false

	print("Total buttons: ", pt_buttons.size())
	print("Total backgrounds: ", pt_backgrounds.size())

	_show_only_background(0)
	if pt_buttons.size() > 0:
		pt_buttons[0].disabled = true


func _on_patient_pressed(index: int, pid: String) -> void: # 13/8 signature updated
	print("Patient button pressed: ", index, " id=", pid)
	current_patient_index = index
	_show_only_background(index)
	# Enable all buttons first
	for i in pt_buttons.size():
		pt_buttons[i].disabled = false
	# Then disable the clicked one
	pt_buttons[index].disabled = true

	# --- NEW: remember who is active & ensure their state exists ---- # 13/8
	current_patient_id = pid
	_ensure_state(pid)
	# ---------------------------------------------------------------- # 13/8


func _show_only_background(index: int) -> void:
	print("Showing only background: ", index)
	for i in pt_backgrounds.size():
		pt_backgrounds[i].visible = (i == index)


# Helpers to manage the results area and placeholders ------------------------- # 13/8
func _clear_results_keep_header() -> void:
	# keep header at index 0, clear everything else
	for i in range(1, results_list.get_child_count()):
		results_list.get_child(i).queue_free()

func _show_placeholder(msg: String) -> void:
	_clear_results_keep_header()
	var lbl := Label.new()
	lbl.text = msg
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color.BLACK)
	results_list.add_child(lbl)
# ----------------------------------------------------------------------------- # 13/8
