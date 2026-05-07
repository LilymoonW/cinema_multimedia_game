extends Node2D

@export var walk_speed: float = 110.0
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
@onready var tufts: Node2D = $Parallax/Tufts
@onready var dialog: Control = $UI/DialogBox
@onready var dialog_text: Label = $UI/DialogBox/Text
@onready var dialog_speaker: Label = $UI/DialogBox/Speaker
@onready var walk_prompt: Label = $UI/WalkPrompt
@onready var walk_prompt_bg: ColorRect = $UI/WalkPromptBg

const INTRO_LINES := [
	"Hi I've been waiting for your appearance",
	"The world is in danger of currupt individuals.",
	"Hold the right arrow key to walk and purify enemies!",
]

const DIALOG_REVEAL_DELAY := 0.04

var dialog_index: int = 0
var can_walk: bool = false
var transitioning: bool = false
var enemies: Array = []
var revealing: bool = false
var current_line: String = ""
var reveal_gen: int = 0

func _ready() -> void:
	player.play("walk")
	pip.play("sparkle")
	walk_prompt.visible = false
	walk_prompt_bg.visible = false
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
	var is_boss: bool = GameState.is_boss_next()
	cry_template.position = Vector2(enemy_spawn_x, 430)
	cry_template.visible = true
	cry_template.play("cry")
	if is_boss:
		cry_template.scale = Vector2(1.6, 1.6)
		cry_template.modulate = Color(0.5, 0.45, 0.55)
		cry_template.position.y = 410
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
		Audio.play_walk()
		walk_prompt.visible = false
		walk_prompt_bg.visible = false
		if enemies.size() > 0 and enemies[0].position.x <= player.position.x + collision_offset:
			_trigger_encounter()
	else:
		player.pause()
		Audio.stop_walk()
		walk_prompt.visible = true
		walk_prompt_bg.visible = true

func _scroll_world(dx: float) -> void:
	sky.position.x -= dx * 0.1
	ground.region_rect.position.x += dx
	ground_top.region_rect.position.x += dx
	for child in trees.get_children():
		child.position.x -= dx
	for child in tufts.get_children():
		child.position.x -= dx
	for e in enemies:
		e.position.x -= dx

func _show_dialog_line(i: int) -> void:
	dialog_index = i
	dialog.visible = true
	dialog_speaker.text = "Pip"
	current_line = INTRO_LINES[i]
	_reveal_dialog(current_line)

func _reveal_dialog(line: String) -> void:
	reveal_gen += 1
	var my_gen: int = reveal_gen
	revealing = true
	dialog_text.text = ""
	if line.length() > 0:
		Audio.start_speak()
	for j in line.length():
		if my_gen != reveal_gen:
			return
		dialog_text.text = line.substr(0, j + 1)
		await get_tree().create_timer(DIALOG_REVEAL_DELAY).timeout
	if my_gen != reveal_gen:
		return
	Audio.stop_speak()
	revealing = false

func _on_next_pressed() -> void:
	if revealing:
		# Skip to end of current line.
		reveal_gen += 1
		revealing = false
		Audio.stop_speak()
		dialog_text.text = current_line
		Audio.play_sfx("tap")
		return
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
	walk_prompt_bg.visible = true
	player.pause()

func _trigger_encounter() -> void:
	if transitioning:
		return
	transitioning = true
	Audio.stop_walk()
	Audio.play_sfx("jump")
	get_tree().change_scene_to_file("res://scenes/combat.tscn")
