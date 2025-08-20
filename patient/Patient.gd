# Patient.gd
# -----------------------------------------------------------------------------
# Defines a patient data structure with ID, name, demographics, and vitals.
# Parsed from CSV by PatientManagerB.
# -----------------------------------------------------------------------------

extends Resource
class_name Patient

# -------------------------------------------------------------------
# Properties
# -------------------------------------------------------------------

# A unique stable identifier for the patient (e.g. "GI|Wang")
var id: String = ""

# Basic info
var name: String = ""
var age: int = 0
var sex: String = ""

# Vitals (optional; depends on your CSV)
var heart_rate: int = 0
var bp: String = ""            # blood pressure stored as string e.g. "120/80"
var spo2: int = 0              # oxygen saturation
var resp_rate: int = 0         # respiratory rate

# Complaint / diagnosis placeholders (will come from CSV later)
var complaint: String = ""
var diagnosis: String = ""

# -------------------------------------------------------------------
# Initializer
# -------------------------------------------------------------------
func _init(data: Dictionary = {}) -> void:
	# If a dictionary is provided (from CSV), map fields
	if data.has("id"): id = str(data["id"])
	if data.has("name"): name = str(data["name"])
	if data.has("age"): age = int(data["age"])
	if data.has("sex"): sex = str(data["sex"])
	if data.has("heart_rate"): heart_rate = int(data["heart_rate"])
	if data.has("bp"): bp = str(data["bp"])
	if data.has("spo2"): spo2 = int(data["spo2"])
	if data.has("resp_rate"): resp_rate = int(data["resp_rate"])
	if data.has("complaint"): complaint = str(data["complaint"])
	if data.has("diagnosis"): diagnosis = str(data["diagnosis"])
