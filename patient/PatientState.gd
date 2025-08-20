# res://patient/PatientState.gd
# -----------------------------------------------------------------------------
# A lightweight, serializable container for one patient's UI/game state.
# Use this as a Resource so we can save/load later if needed.
# -----------------------------------------------------------------------------
extends Resource
class_name PatientState

# ------------------- Identity -------------------
@export var patient_id: String = ""          # e.g. "GI|Wang"

# ------------------- Orders (UI) ----------------
# Rows the user has started (yellow countdown) or finished (blue).
# Each item is a Dictionary you control, e.g.:
# { "name":"Aspirin", "minutes":10, "started_min":123, "end_min":133, "state":"IN_PROGRESS|COMPLETE" }
@export var orders_active: Array[Dictionary] = []   # currently ticking
@export var orders_finished: Array[Dictionary] = [] # completed items

# ------------------- Per-patient events ---------
# Minute the patient entered the ER (game minutes)
@export var event_enter_min: int = 0

# Events scheduled to fire X minutes after enter_min
# Each event: { "offset_min":5, "type":"complaint|deterioration", "message":"..." }
@export var scheduled_events: Array[Dictionary] = []

# Fired history: same shape as scheduled + when it fired if you want to add it later
@export var fired_events: Array[Dictionary] = []

# ------------------- Helpers (optional) ---------
func add_active_order(order: Dictionary) -> void:
	# Defensive copy to avoid accidental reference sharing
	orders_active.append(order.duplicate(true))

func finish_order(order: Dictionary) -> void:
	# Move from active → finished; if you already have the finished dict, just append it
	orders_finished.append(order.duplicate(true))
	# Best-effort removal from active (if present)
	for i in orders_active.size():
		if orders_active[i] == order:
			orders_active.remove_at(i)
			break
