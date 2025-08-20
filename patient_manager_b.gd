# patient_manager_b.gd
# -----------------------------------------------------------------------------
# Loads patients from a local CSV using Godot's CSV reader (no external parser).
# Emits `patients_loaded` when ready. Keeps API identical for index.gd.
# -----------------------------------------------------------------------------

extends Node
class_name PatientManagerB

signal patients_loaded

const CSV_PATH: String = "res://CSV/NLI_CS1.csv"

var patients: Array[Patient] = []

func _ready() -> void:
	print("PatientManagerB _ready() called")
	_load_patients_from_csv()

# -----------------------------------------------------------------------------
# Read CSV with FileAccess.get_csv_line() (handles quotes/newlines safely)
# -----------------------------------------------------------------------------
func _load_patients_from_csv() -> void:
	if not FileAccess.file_exists(CSV_PATH):
		push_error("CSV not found at: " + CSV_PATH)
		emit_signal("patients_loaded")
		return

	var f: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	if f == null:
		push_error("Failed to open CSV: " + CSV_PATH)
		emit_signal("patients_loaded")
		return

	var header: PackedStringArray = []
	patients.clear()

	# Read header row
	if not f.eof_reached():
		header = f.get_csv_line()
	# Normalize header keys (trim spaces)
	for i in header.size():
		header[i] = header[i].strip_edges()

	# Read each subsequent row and build a Dictionary -> Patient
	while not f.eof_reached():
		var cols: PackedStringArray = f.get_csv_line()

		# Skip empty rows (only whitespace)
		var nonempty: bool = false
		for c: String in cols:
			if c.strip_edges() != "":
				nonempty = true
				break
		if not nonempty:
			continue

		var row: Dictionary = {}
		var count: int = min(header.size(), cols.size())  # <- typed to avoid Variant
		for i in count:
			row[header[i]] = cols[i].strip_edges()

		# Construct Patient from the row dictionary.
		# Your Patient.gd should accept Dictionary and do type conversions.
		var p: Patient = Patient.new(row)
		patients.append(p)

	print("Loaded %d patients from CSV!" % patients.size())
	emit_signal("patients_loaded")
