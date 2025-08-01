extends Control

@onready var days_label: Label = $DayControl/day
@onready var time_label: Label = $clock_bg/ClockControl/time

func _on_time_system_updated(date_time: DateTime) -> void:
	days_label.text = str(date_time.days)
	time_label.text = "%02d:%02d" % [date_time.hours, date_time.minutes]
