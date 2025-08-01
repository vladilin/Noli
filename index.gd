extends Control

var PATIENT_BACKGROUND = preload("res://patient_background.tscn")
@onready var pt_profile: Panel = $bg_green/Pt_profile

var button_theme = preload("res://styles/new1.0.tres")
@onready var pt_list: VBoxContainer = $bg_green/pt_list

@onready var patient_manager: PatientManagerB = $PatientManagerB

var pt_buttons: Array[Button] = []
var pt_backgrounds: Array = []

func _ready():
	print("index.gd _ready() running")
	print("pt_profile is: ", pt_profile)
	print("pt_list is: ", pt_list)
	print("patient_manager is: ", patient_manager)
	patient_manager.patients_loaded.connect(_on_patients_loaded)

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
