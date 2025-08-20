# treatment_manager.gd
# -----------------------------------------------------------------------------
# Responsible for managing treatments (and later tests/consults/presentations).
# Right now: dummy data lives here. Later: load from CSV / Google Sheets.
# -----------------------------------------------------------------------------

extends Node
class_name TreatmentManager

# Array of treatments (each entry is a Dictionary for now)
var treatments: Array[Dictionary] = []

func _ready() -> void:
	print("TreatmentManager is ready!")
	_load_dummy_treatments()

# -----------------------------------------------------------------------------
# Dummy dataset (replace with CSV or Google Sheet later)
# -----------------------------------------------------------------------------
func _load_dummy_treatments() -> void:
	treatments.clear()

	treatments.append({
		"name": "IV Fluids",
		"minutes": 3,
		"description": "Start IV fluids for the patient.",
		"success_msg": "The patient looks more stable after fluids.",
		"failure_msg": "There is no noticeable difference."
	})

	treatments.append({
		"name": "Oxygen",
		"minutes": 2,
		"description": "Provide oxygen via mask or nasal cannula.",
		"success_msg": "Oxygen saturation improves.",
		"failure_msg": "No significant change."
	})

	treatments.append({
		"name": "Pain Relief",
		"minutes": 4,
		"description": "Give pain relief medication.",
		"success_msg": "Patient reports less pain.",
		"failure_msg": "Patient still appears uncomfortable."
	})

	print("Loaded %d dummy treatments" % treatments.size())

# -----------------------------------------------------------------------------
# Search helper
# -----------------------------------------------------------------------------
func search_treatments(query: String) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	var q = query.to_lower()

	for t in treatments:
		var name = str(t.get("name", "")).to_lower()
		var desc = str(t.get("description", "")).to_lower()

		if q in name or q in desc:
			matches.append(t)

	return matches
