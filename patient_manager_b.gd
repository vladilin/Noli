extends Node
class_name PatientManagerB
signal patients_loaded

var patients: Array[Patient] = []
const CsvParser = preload("res://csv_parser.gd")  # Update the path if your file is elsewhere
# const Patient = preload("res://Patient.gd")     # Uncomment if Patient is not a global class

const SHEET_URL = "https://docs.google.com/spreadsheets/d/1FQYIbDn7SayINMZU5uttnsbu-3I69FUGhwkMh_9VPu4/export?format=csv"
const BACKUP_CSV_URL = "https://homepages.ecs.vuw.ac.nz/~ilinvlad/zombie/CSV/NLI_CS1.csv"  #6/8 IF local

@onready var http_request: HTTPRequest = $HTTPRequest

func _ready():
	print("PatientManagerB is ready!")
	print("PatientManagerB _ready() called")
	if http_request:
		print("HTTPRequest node found, making request.")
		http_request.request(SHEET_URL)
	else:
		print("Error: HTTPRequest node not found!")
		_request_backup_csv() #6/8 IF local

var _redirect_count = 0
const MAX_REDIRECTS = 3

func _on_http_request_request_completed(result, response_code, headers, body) -> void:
	print("Response code:", response_code)
	if response_code == 307 and _redirect_count < MAX_REDIRECTS:
		for header in headers:
			if header.begins_with("Location: "):
				var redirect_url = header.substr(10)
				print("Redirecting to:", redirect_url)
				_redirect_count += 1
				$HTTPRequest.request(redirect_url)
				return
		print("No Location header found in 307 response.")
		_request_backup_csv() #6/8 IF local
		return
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200: #6/8 IF local
		print("Failed to load from Google Sheets, loading backup server CSV instead.") #6/8 IF local
		_request_backup_csv() #6/8 IF local
		return
	if response_code == 200:
		var csv_data = body.get_string_from_utf8()
		#print("CSV data received:\n", csv_data)
		_parse_csv(csv_data)

func _request_backup_csv(): #6/8 IF local
	if http_request:
		print("Requesting backup CSV from server...")
		http_request.request(BACKUP_CSV_URL)
	else:
		print("No HTTPRequest node found for backup CSV.")

func _parse_csv(csv_text: String) -> void:
	print("_parse_csv() called")
	patients.clear()

	var patient_rows = CsvParser.new().parse(csv_text)
	#print("Parsed patients (parser):", patient_rows)

	if patient_rows.size() < 2:
		print("CSV missing header/data")
		return

	var headers = patient_rows[0]
	#print("CSV headers found: ", headers)

	for i in range(1, patient_rows.size()):
		var fields = patient_rows[i]
		if fields.size() != headers.size():
			print("Skipping malformed row at index %d: %s" % [i, fields])
			continue

		var row = {}
		for j in range(headers.size()):
			row[headers[j].strip_edges()] = fields[j].strip_edges()

		var spo2_str = row["SPO2"].replace("%", "") if row.has("SPO2") else "0"
		var spo2 = float(spo2_str) if spo2_str.is_valid_float() else 0.0
		var resp = int(row["RESP"]) if row.has("RESP") and row["RESP"].is_valid_int() else 0
		var temp = float(row["Temp"]) if row.has("Temp") and row["Temp"].is_valid_float() else 0.0

		#print("Patient parsed: Name=%s, Abbr=%s, Disease=%s, AGE=%s" % [
		#	row.get("Name", ""), row.get("Abbr", ""), row.get("Disease", ""), row.get("AGE", "")
		#])

		patients.append(Patient.new(
			row.get("Name", ""),
			row.get("Abbr", ""),
			row.get("Disease", ""),
			row.get("TEXT", ""),
			int(row["AGE"]) if row.has("AGE") and row["AGE"].is_valid_int() else 0,
			row.get("SEX", ""),
			int(row["HR"]) if row.has("HR") and row["HR"].is_valid_int() else 0,
			row.get("BP", ""),
			spo2,
			resp,
			temp
		))
	print("_parse_csv() complete. Total patients loaded: ", patients.size())
	emit_signal("patients_loaded")
