extends Control


var pending_patient: Patient = null

@onready var pt_photo: TextureRect = $bg/PT_photo
@onready var case_data: RichTextLabel = $bg/Case_data
@onready var pt_data: Label = $bg/Pt_data


func _ready():
	# If patient was assigned before _ready, update fields now
	if pending_patient != null:
		_set_patient_fields()

func set_patient(patient: Patient) -> void:
	pending_patient = patient
	# If nodes are already initialized, update fields right away
	if case_data != null and pt_data != null:
		_set_patient_fields()

func _set_patient_fields():
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
		# Set patient photo
		var photo_path = "res://art/%s.png" % pending_patient.Case_code
		if ResourceLoader.exists(photo_path):  # Only try to load if the file exists
			pt_photo.texture = load(photo_path)
		else:
			pt_photo.texture = load("res://art/placeholder.png")
