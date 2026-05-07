extends Node2D

func _ready() -> void:
	# Reset run state every time we land on the title screen.
	GameState.encounter_index = 0
	GameState.hope = 0
	$Pip.play("sparkle")
	Audio.play_music()

func _on_start_pressed() -> void:
	Audio.play_sfx("tap")
	get_tree().change_scene_to_file("res://scenes/corridor.tscn")
