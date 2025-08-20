extends Node
class_name PatientManagerB
signal patients_loaded

# -------------------------------------------------------------------
# Simple, robust CSV loader with timeout + multi-source fallback
# Sources (in order):
#  1) Google (published/export) — with CORS proxy on Web builds
#  2) Backup CSV (plain URL)
# Handles one request at a time, cancels before retrying, and logs clearly.
# -------------------------------------------------------------------

var patients: Array[Patient] = []
const CsvParser = preload("res://csv_parser.gd")

@onready var http_request: HTTPRequest = $HTTPRequest

# ---------------------- CONFIG -------------------------------------

# 1) Published sheet (File → Share → Publish to web → CSV)
const SHEET_PUBLISHED := "https://docs.google.com/spreadsheets/d/e/2PACX-1vScvgRjIjX3OwMOFXKsvK_kGnDT2Jj3444GJ6Gwiq877uxLdtRkY9BAdrM3mf5V2sWz7DrqfakqxKUN/pub?output=csv"

# 2) Export (works if the doc & sheet tab are public; add gid if multiple sheets)
const SHEET_EXPORT := "https://docs.google.com/spreadsheets/d/e/2PACX-1vScvgRjIjX3OwMOFXKsvK_kGnDT2Jj3444GJ6Gwiq877uxLdtRkY9BAdrM3mf5V2sWz7DrqfakqxKUN/pub?gid=734144177&single=true&output=csv"

# Back-up CSV (your server or any static file)
const BACKUP_CSV_URL := "https://homepages.ecs.vuw.ac.nz/~ilinvlad/zombie/CSV/NLI_CS1.csv"

# CORS proxy for Web builds (browsers block direct Google CSV in WASM)
const CORS_PROXY_PREFIX := "https://corsproxy.io/?"

# How long we wait per source before failing over (seconds)
const TIMEOUT_SEC := 6.0

# Redirect guard (Google will 307 to short-lived URLs)
const MAX_REDIRECTS := 3

# ---------------------- INTERNAL STATE ------------------------------
enum Source { PUBLISHED, EXPORT, BACKUP }

var _sources: Array = []         # will be filled in _ready()
var _src_idx: int = 0            # current source index
var _redirects: int = 0
var _timer: SceneTreeTimer = null
var _requesting: bool = false
var _done: bool = false          # parsed & emitted

# ---------------------- LIFECYCLE -----------------------------------

func _ready() -> void:
	print_rich("[color=yellow][PMB][/color] Ready. Starting Sheet load…")
	if not http_request:
		push_error("[PMB] No HTTPRequest node found!")
		_finish_with_failure([])
		return

	# Build source list in order; for Web builds, wrap Google with CORS proxy
	var on_web := OS.has_feature("web")
	var pub_url := (CORS_PROXY_PREFIX + SHEET_PUBLISHED) if on_web else SHEET_PUBLISHED
	var exp_url := (CORS_PROXY_PREFIX + SHEET_EXPORT) if on_web else SHEET_EXPORT

	_sources = [
		{"name":"PUBLISHED", "url": pub_url},
		{"name":"EXPORT",    "url": exp_url},
		{"name":"BACKUP",    "url": BACKUP_CSV_URL},
	]

	# Listen once for completion
	if not http_request.is_connected("request_completed", Callable(self, "_on_request_completed")):
		http_request.request_completed.connect(_on_request_completed)

	_src_idx = 0
	_start_current_source()

# ---------------------- REQUEST FLOW --------------------------------

func _start_current_source() -> void:
	if _done:
		return
	if _src_idx >= _sources.size():
		print_rich("[color=orangered][PMB][/color] No more sources to try.")
		_finish_with_failure([])
		return

	# Ensure we’re not already requesting
	if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http_request.cancel_request()

	_redirects = 0
	var s = _sources[_src_idx]
	print_rich("[color=yellow][PMB][/color] (%d) Requesting %s CSV…" % [_src_idx+1, s["name"]])

	var err := http_request.request(s["url"])
	if err != OK:
		print_rich("[color=orangered][PMB][/color] Couldn’t start request (err=%s). Trying next source…" % str(err))
		_next_source()
		return

	_requesting = true
	# Start/replace timeout timer
	if _timer:
		_timer.disconnect("timeout", Callable(self, "_on_timeout"))
	_timer = get_tree().create_timer(TIMEOUT_SEC)
	_timer.timeout.connect(_on_timeout)

func _on_timeout() -> void:
	if _done:
		return
	if not _requesting:
		return  # request already finished
	var s = _sources[_src_idx]
	print_rich("[color=orangered][PMB][/color] [%s] Timed out after ~%.1fs" % [s["name"], TIMEOUT_SEC])
	http_request.cancel_request()
	_requesting = false
	_next_source()

func _next_source() -> void:
	if _done:
		return
	_src_idx += 1
	_start_current_source()

# ---------------------- COMPLETION HANDLER --------------------------

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	_requesting = false

	# Stop timer for this source
	if _timer:
		_timer.disconnect("timeout", Callable(self, "_on_timeout"))
		_timer = null

	var s = _sources[_src_idx]
	# Handle 307 redirects (Google temporary URL)
	if response_code == 307 and _redirects < MAX_REDIRECTS:
		var redirect_url := ""
		for h in headers:
			if h.begins_with("Location: "):
				redirect_url = h.substr(10)
				break
		if redirect_url != "":
			_redirects += 1
			print_rich("[color=yellow][PMB][/color] [%s] Redirect → (%d/%d)" % [s["name"], _redirects, MAX_REDIRECTS])
			# Cancel any active connection before re-requesting
			if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
				http_request.cancel_request()
			_requesting = true
			var err := http_request.request(redirect_url)
			if err != OK:
				print_rich("[color=orangered][PMB][/color] Redirect request failed (err=%s). Trying next source…" % str(err))
				_next_source()
				return
			# Restart timeout for redirected URL
			_timer = get_tree().create_timer(TIMEOUT_SEC)
			_timer.timeout.connect(_on_timeout)
			return
		# No Location header → try next
		print_rich("[color=orangered][PMB][/color] [%s] 307 without Location. Trying next source." % s["name"])
		_next_source()
		return

	# Non-200 response → try next
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print_rich("[color=orangered][PMB][/color] [%s] Non-200 or failed (result=%s, code=%s). Trying next source." % [s["name"], str(result), str(response_code)])
		_next_source()
		return

	# Success: parse
	var csv_text := body.get_string_from_utf8()
	var ok := _parse_csv(csv_text)
	if ok:
		print_rich("[color=green][PMB][/color] Loaded %d patients from CSV!" % patients.size())
		_done = true
		emit_signal("patients_loaded")
	else:
		print_rich("[color=orangered][PMB][/color] [%s] CSV parse failed. Trying next source." % s["name"])
		_next_source()

# ---------------------- PARSE CSV -----------------------------------

func _parse_csv(csv_text: String) -> bool:
	patients.clear()

	var rows: Array = CsvParser.new().parse(csv_text)
	if rows.size() < 2:
		print("[PMB] CSV missing header or data.")
		return false

	var headers: PackedStringArray = rows[0]
	for i in range(1, rows.size()):
		var fields: PackedStringArray = rows[i]
		if fields.size() != headers.size():
			continue

		var row := {}
		for j in range(headers.size()):
			row[headers[j].strip_edges()] = fields[j].strip_edges()

		# Typed & safe conversions
		var spo2_str: String = ""
		if row.has("SPO2"):
			spo2_str = str(row["SPO2"]).replace("%", "")
		var spo2: float = 0.0
		if spo2_str != "" and spo2_str.is_valid_float():
			spo2 = float(spo2_str)

		var resp: int = 0
		if row.has("RESP") and str(row["RESP"]).is_valid_int():
			resp = int(row["RESP"])

		var temp: float = 0.0
		if row.has("Temp") and str(row["Temp"]).is_valid_float():
			temp = float(row["Temp"])

		var age: int = 0
		if row.has("AGE") and str(row["AGE"]).is_valid_int():
			age = int(row["AGE"])

		var hr: int = 0
		if row.has("HR") and str(row["HR"]).is_valid_int():
			hr = int(row["HR"])

		patients.append(Patient.new(
			row.get("Name", ""),
			row.get("Abbr", ""),
			row.get("Disease", ""),
			row.get("TEXT", ""),
			age,
			row.get("SEX", ""),
			hr,
			row.get("BP", ""),
			spo2,
			resp,
			temp
		))

	return patients.size() > 0

# ---------------------- FAILURE PATH --------------------------------

func _finish_with_failure(_why: Array) -> void:
	# Don’t spam UI here; caller scene can show a message if patients is empty.
	_done = true
	emit_signal("patients_loaded")
