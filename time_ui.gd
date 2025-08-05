extends Control

@onready var days_label: Label = $DayControl/day
@onready var time_label: Label = $clock_bg/ClockControl/time

@onready var play_button: TextureButton = $Play_Button
@onready var ff_button: TextureButton = $FF_Button
@onready var skip_button: TextureButton = $Skip_Button

@onready var time_system: TimeSystem = $"../../TimeSystem"


func _on_time_system_updated(date_time: DateTime) -> void:
	days_label.text = str(date_time.days)
	time_label.text = "%02d:%02d:%02d" % [date_time.hours, date_time.minutes, date_time.seconds]


func _on_play_button_pressed() -> void:
	time_system.ticks_pr_second = 1

func _on_ff_button_pressed() -> void:
	time_system.ticks_pr_second = 150

func _on_skip_button_pressed() -> void:
	time_system.date_time.increase_by_sec(300)
