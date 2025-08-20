extends Control

var PATIENT_BACKGROUND = preload("res://patient_background.tscn")
@onready var pt_profile: Panel = $bg_green/Pt_profile
var button_theme = preload("res://styles/new1.0.tres")
@onready var pt_list: VBoxContainer = $bg_green/pt_list

@onready var patient_manager: PatientManagerB = $PatientManagerB
@onready var treatment_manager: TreatmentManager = $TreatmentManager
@onready var time_system: TimeSystem = $TimeSystem

var pt_buttons: Array[Button] = []
var pt_backgrounds: Array[PatientBackground] = []

var current_patient_index: int = 0
var current_patient_id: String = ""

func _ready() -> void:
	print("index.gd _ready() running")
	patient_manager.patients_loaded.connect(_on_patients_loaded)

func _on_patients_loaded() -> void:
	_build_patient_ui()

func _build_patient_ui() -> void:
	pt_buttons.clear()
	for c in pt_profile.get_children():
		c.queue_free()
	pt_backgrounds.clear()
	for c in pt_list.get_children():
		c.queue_free()

	# Patient selector buttons
	for i in patient_manager.patients.size():
		var p: Patient = patient_manager.patients[i]
		var btn := Button.new()
		btn.text = p.name
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.theme = button_theme
		btn.pressed.connect(_on_patient_pressed.bind(i, p.id))
		pt_list.add_child(btn)
		pt_buttons.append(btn)

	# Background instances (each owns its buttons + popup)
	for i in patient_manager.patients.size():
		var p: Patient = patient_manager.patients[i]
		var bg := PATIENT_BACKGROUND.instantiate() as PatientBackground
		if bg == null:
			push_error("patient_background.tscn missing PatientBackground.gd.")
			continue
		bg.set_patient(p)
		bg.set_services(treatment_manager, time_system)
		pt_profile.add_child(bg)
		pt_backgrounds.append(bg)
		bg.visible = false

	_show_only_background(0)
	if pt_buttons.size() > 0:
		pt_buttons[0].disabled = true
	current_patient_index = 0
	current_patient_id = patient_manager.patients[0].id if patient_manager.patients.size() > 0 else ""

func _on_patient_pressed(index: int, pid: String) -> void:
	current_patient_index = index
	current_patient_id = pid
	_show_only_background(index)
	for i in pt_buttons.size():
		pt_buttons[i].disabled = false
	pt_buttons[index].disabled = true

func _show_only_background(index: int) -> void:
	for i in pt_backgrounds.size():
		pt_backgrounds[i].visible = (i == index)
