extends Node
class_name PatientManagerB
signal patients_loaded

var patients: Array[Patient] = []
const CsvParser = preload("res://csv_parser.gd")

const SHEET_URL      := "https://docs.google.com/spreadsheets/d/e/2PACX-1vScvgRjIjX3OwMOFXKsvK_kGnDT2Jj3444GJ6Gwiq877uxLdtRkY9BAdrM3mf5V2sWz7DrqfakqxKUN/pub?gid=734144177&single=true&output=csv"
const BACKUP_CSV_URL := "https://homepages.ecs.vuw.ac.nz/~ilinvlad/zombie/CSV/NLI_CS1.csv"

@onready var http_request: HTTPRequest = $HTTPRequest

# NEW: redirect/timeout guards
var _redirect_count: int = 0
const MAX_REDIRECTS: int = 3

var _request_active: bool = false          # true while Google attempt is in flight
var _parsed_once: bool = false             # ensure we only parse/emit once
const SHEET_TIMEOUT_SEC := 4.0             # tweak between 3–6s to taste

func _ready() -> void:
	print("PatientManagerB is ready!")
	if http_request:
		_start_google_request()
	else:
		print("Error: HTTPRequest node not found!")
		_request_backup_csv()

func _start_google_request() -> void:
	_redirect_count = 0
	_request_active = true
	# Kick off Google request
	http_request.request(SHEET_URL)
	# Start a one-shot timer that will flip to backup if Google is slow
	var t := get_tree().create_timer(SHEET_TIMEOUT_SEC)
	t.timeout.connect(_on_sheet_timeout)

func _on_sheet_timeout() -> void:
	# If Google hasn't returned within the timeout, cancel and fall back.
	if _parsed_once or not _request_active:
		return
	print("Google Sheet slow; cancelling and switching to backup.")
	if http_request:
		http_request.cancel_request()
	_request_active = false
	_request_backup_csv()

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	_request_active = false

	# Follow redirects (Google returns 307 with a short-lived URL)
	if response_code == 307 and _redirect_count < MAX_REDIRECTS:
		for header in headers:
			if header.begins_with("Location: "):
				var redirect_url := header.substr(10)
				_redirect_count += 1
				_request_active = true
				$HTTPRequest.request(redirect_url)
				return
		# No Location? bail to backup
		_request_backup_csv()
		return

	# Anything non-200 → use backup
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("Google request failed (result %s, code %s). Using backup." % [str(result), str(response_code)])
		_request_backup_csv()
		return

	# Parse Google CSV
	var csv_data := body.get_string_from_utf8()
	_parse_csv(csv_data)

func _request_backup_csv() -> void:
	if _parsed_once:
		return
	if http_request:
		http_request.request(BACKUP_CSV_URL)
	else:
		print("No HTTPRequest node found for backup CSV.")

# Shared parse path
func _parse_csv(csv_text: String) -> void:
	if _parsed_once:
		return
	_parsed_once = true

	patients.clear()

	var rows := CsvParser.new().parse(csv_text)
	if rows.size() < 2:
		print("CSV missing header/data")
		emit_signal("patients_loaded")
		return

	var headers: PackedStringArray = rows[0]
	for i in range(1, rows.size()):
		var fields: PackedStringArray = rows[i]
		if fields.size() != headers.size():
			continue

		var row := {}
		for j in range(headers.size()):
			row[headers[j].strip_edges()] = fields[j].strip_edges()

		var spo2_str : String = row.get("SPO2", "").replace("%", "")
		var spo2 := float(spo2_str) if spo2_str != "" and spo2_str.is_valid_float() else 0.0
		var resp := int(row["RESP"]) if row.has("RESP") and row["RESP"].is_valid_int() else 0
		var temp := float(row["Temp"]) if row.has("Temp") and row["Temp"].is_valid_float() else 0.0

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

	print("Loaded %d patients from CSV!" % patients.size())
	emit_signal("patients_loaded")
