extends Node2D

# Shared script for every ending scene. Each ending scene has its own
# Background, Text, and Continue button — this script just wires up the
# button and returns to the title screen.

func _ready() -> void:
	var btn: Button = find_child("Continue", true, false) as Button
	if btn != null:
		if not btn.pressed.is_connected(_on_continue_pressed):
			btn.pressed.connect(_on_continue_pressed)
		btn.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_on_continue_pressed()

func _on_continue_pressed() -> void:
	Audio.play_sfx("tap")
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/title.tscn")
