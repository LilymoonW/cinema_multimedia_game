extends Node2D

@export var walk_speed: float = 80.0
@export var enemy_spawn_x: float = 900.0
@export var enemy_spacing: float = 90.0
@export var collision_offset: float = 80.0

@onready var player: AnimatedSprite2D = $Player
@onready var pip: AnimatedSprite2D = $Pip
@onready var cry_template: AnimatedSprite2D = $Cry
@onready var sky: Sprite2D = $Parallax/Sky
@onready var ground: Sprite2D = $Parallax/Ground
@onready var ground_top: Sprite2D = $Parallax/GroundTop
@onready var trees: Node2D = $Parallax/Trees
@onready var dialog: Control = $UI/DialogBox
@onready var dialog_text: Label = $UI/DialogBox/Text
@onready var dialog_speaker: Label = $UI/DialogBox/Speaker
@onready var walk_prompt: Label = $UI/WalkPrompt

const INTRO_LINES := [
	"Hi I've been waiting for your appearance",
	"Your  is in danger from the Shadows.",
	"Hold the right arrow key to walk — your light will save us!",
]

var dialog_index: int = 0
var can_walk: bool = false
var transitioning: bool = false
var enemies: Array = []

func _ready() -> void:
	player.play("walk")
	pip.play("sparkle")
	walk_prompt.visible = false
	Audio.play_music()
	_spawn_enemies()
	if GameState.encounter_index == 0:
		_show_dialog_line(0)
	else:
		dialog.visible = false
		_begin_walk_phase()

func _spawn_enemies() -> void:
	var n: int = GameState.enemies_for_current_encounter()
	if n <= 0:
		cry_template.queue_free()
		return
	cry_template.position = Vector2(enemy_spawn_x, 430)
	cry_template.visible = true
	cry_template.play("cry")
	enemies.append(cry_template)
	for i in range(1, n):
		var e: AnimatedSprite2D = cry_template.duplicate()
		add_child(e)
		e.position = Vector2(enemy_spawn_x + i * enemy_spacing, 430)
		e.visible = true
		e.play("cry")
		enemies.append(e)

func _process(delta: float) -> void:
	if transitioning:
		return
	if not can_walk:
		player.pause()
		return
	if Input.is_action_pressed("ui_right"):
		var dx: float = walk_speed * delta
		_scroll_world(dx)
		if not player.is_playing():
			player.play("walk")
		walk_prompt.visible = false
		if enemies.size() > 0 and enemies[0].position.x <= player.position.x + collision_offset:
			_trigger_encounter()
	else:
		player.pause()
		walk_prompt.visible = true

func _scroll_world(dx: float) -> void:
	sky.position.x -= dx * 0.1
	ground.region_rect.position.x += dx
	ground_top.region_rect.position.x += dx
	for child in trees.get_children():
		child.position.x -= dx
	for e in enemies:
		e.position.x -= dx

func _show_dialog_line(i: int) -> void:
	dialog_index = i
	dialog.visible = true
	dialog_speaker.text = "Pip"
	dialog_text.text = INTRO_LINES[i]

func _on_next_pressed() -> void:
	Audio.play_sfx("tap")
	dialog_index += 1
	if dialog_index >= INTRO_LINES.size():
		dialog.visible = false
		_begin_walk_phase()
	else:
		_show_dialog_line(dialog_index)

func _begin_walk_phase() -> void:
	can_walk = true
	walk_prompt.visible = true
	player.pause()

func _trigger_encounter() -> void:
	if transitioning:
		return
	transitioning = true
	Audio.play_sfx("jump")
	get_tree().change_scene_to_file("res://scenes/combat.tscn")
