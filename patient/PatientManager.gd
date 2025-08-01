extends Node
class_name PatientManager

var patients: Array[Patient] = []

func _ready():
	load_patients_from_csv()

func load_patients_from_csv() -> void:
	var records = preload("res://CSV/CS1.csv").records
	for row in records:
		patients.append(Patient.new(
			row["Name"],         # <-- Must match CSV header
			row["Case_code"],
			row["Disease"],
			row["TEXT"],
			int(row["AGE"]),
			row["SEX"],
			int(row["HR"]),
			row["BP"],
			float(row["SPO2"]),
			int(row["RESP_R"]),
			float(row["Temp"])
		))
	print("Loaded %d patients from CSV!" % patients.size())
