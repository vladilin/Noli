class_name Patient

var name: String
var Case_code: String
var Disease: String
var TEXT: String
var AGE: int
var SEX: String
var HR: int
var BP: String
var SPO2: int
var RESP_R: int
var Temp: float

func _init(
	_name: String = "",
	_Case_code: String = "",
	_Disease: String = "",
	_TEXT: String = "",
	_AGE: int = 0,
	_SEX: String = "",
	_HR: int = 0,
	_BP: String = "",
	_SPO2: int = 0,
	_RESP_R: int = 0,
	_Temp: float = 0.0
) -> void:
	name = _name
	Case_code = _Case_code
	Disease = _Disease
	TEXT = _TEXT
	AGE = _AGE
	SEX = _SEX
	HR = _HR
	BP = _BP
	SPO2 = _SPO2
	RESP_R = _RESP_R
	Temp = _Temp
