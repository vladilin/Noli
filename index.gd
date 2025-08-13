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
const SEARCH_ROW_SCENE := preload("res://ui/search/search.tscn")

func _ready():
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
	
func _on_search_box_text_changed(new_text):
	var q: String = new_text.strip_edges()
	if q == "":
		_show_placeholder("Please type a term in the search box above")
		return
	var results := treatment_manager.search_treatments(q)
	if results.is_empty():
		_show_placeholder("There are no results for the term you used. Try another keyword.")
	else:
		display_search_results(results)


func display_search_results(results: Array) -> void:
	print("Displaying results: ", results.size())
	# keep header at index 0, clear the rest
	for i in range(1, results_list.get_child_count()):
		results_list.get_child(i).queue_free()

	# add 1 SearchRow per result
	for item in results:
		var row := SEARCH_ROW_SCENE.instantiate() as SearchRow
		results_list.add_child(row)  # add first so @onready vars exist
		row.set_data(item, {
			"text_key": "name",
			"time_key": "minutes",
			"time_suffix": " min",
			"button_text": "Apply"
		})
		row.action_pressed.connect(_on_search_row_action)
		
func _on_search_row_action(item: Dictionary) -> void:
	print("Action pressed for:", item.get("name", item.get("description", "(no name)")))
	# TODO: perform your action here
#func display_search_results(results: Array) -> void:
	#print("Displaying results: ", results.size())
	## Remove old results
	#for i in range(1, results_list.get_child_count()):
		#results_list.get_child(i).queue_free()
	## Add new results
	#for treatment in results:
		#var row = HBoxContainer.new()
#
		#var name_label = Label.new()
		#name_label.text = treatment["name"]
		#name_label.add_theme_color_override("font_color", Color.BLACK)
		#row.add_child(name_label)
#
		#var min_label = Label.new()
		#min_label.text = str(treatment["minutes"]) + " min"
		#min_label.add_theme_color_override("font_color", Color.BLACK)
		#row.add_child(min_label)
#
		#var action_btn = Button.new()
		#action_btn.text = "Do Action"
		## Attach treatment info or index if you need it later:
		#action_btn.pressed.connect(_on_treatment_action_pressed.bind(treatment))
		#row.add_child(action_btn)
#
		#results_list.add_child(row)

func _on_treatment_action_pressed(treatment):
	print("Action for treatment: ", treatment["name"])
	# Here you can call any function you want, or pass the treatment object further.
	
func _on_main_button_pressed():
	if not bg_popup_panel.visible:
		bg_popup_panel.visible = true
		var q := search_box.text.strip_edges()
		if q == "":
			_show_placeholder("Please type a term in the search box above")
		else:
			var results := treatment_manager.search_treatments(q)
			if results.is_empty():
				_show_placeholder("There are no results for the term you used. Try another keyword.")
			else:
				display_search_results(results)

func _on_patients_loaded():
	print("Patients loaded! Building UI... count: ", patient_manager.patients.size())
	_build_patient_ui()

func _build_patient_ui():
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
		print("Adding button for: ", patient.name)
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.theme = button_theme
		btn.pressed.connect(_on_patient_pressed.bind(i))
		pt_list.add_child(btn)
		pt_buttons.append(btn)

	# Create dynamic backgrounds for each patient
	for i in patient_manager.patients.size():
		var patient = patient_manager.patients[i]
		var bg = PATIENT_BACKGROUND.instantiate()
		print("Instantiating background for: ", patient.name)
		if bg.has_method("set_patient"):
			print("Calling set_patient for: ", patient.name)
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

func _on_patient_pressed(index: int) -> void:
	print("Patient button pressed: ", index)
	_show_only_background(index)
	# Enable all buttons first
	for i in pt_buttons.size():
		pt_buttons[i].disabled = false
	# Then disable the clicked one
	pt_buttons[index].disabled = true

func _show_only_background(index: int) -> void:
	print("Showing only background: ", index)
	for i in pt_backgrounds.size():
		pt_backgrounds[i].visible = (i == index)
		
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
