extends Node2D

@onready var enemy: AnimatedSprite2D = $Enemy
@onready var pip: AnimatedSprite2D = $Pip
@onready var pip_text: Label = $UI/PipText
@onready var narration: Label = $UI/Narration
@onready var spell_buttons: HBoxContainer = $UI/SpellButtons
@onready var hope_label: Label = $UI/HopeLabel

# Per-enemy HP. Designed to feel weak — 2 hits each.
const ENEMY_MAX_HP := 2
var enemy_hp: int = ENEMY_MAX_HP
var enemies_remaining: int = 1

# Pre-death narration fragments, indexed by encounter then by enemy slot.
const NARRATION := [
	["...mother..."],
	["...we were just—", "...please tell my—"],
	["...my children are—", "...we never wanted—"],
	["...I'm so tired...", "...don't tell them how it ends...", "...is anyone going to remember—", "...we sang to them once..."],
]

const PIP_CHEERS := [
	"Amazing! +1 HOPE!",
	"You're so powerful!",
	"The Bright One shines!",
	"Keep going, hero!",
]

var current_enemy_index: int = 0

func _ready() -> void:
	enemies_remaining = GameState.enemies_for_current_encounter()
	if enemies_remaining == 0:
		# Boss fight will replace this later.
		_finish_encounter()
		return
	enemy.play("idle")
	pip.play("sparkle")
	pip_text.text = "Defeat the corruption!"
	narration.text = ""
	hope_label.text = "HOPE: %d" % GameState.hope

func _on_spell_pressed() -> void:
	if enemy_hp <= 0:
		return
	enemy_hp -= 1
	if enemy_hp <= 0:
		_kill_enemy()
	else:
		enemy.play("sad")

func _kill_enemy() -> void:
	# Show pre-death narration for this slot.
	var enc := GameState.encounter_index
	if enc < NARRATION.size() and current_enemy_index < NARRATION[enc].size():
		narration.text = NARRATION[enc][current_enemy_index]
	enemy.play("dead")
	GameState.hope += 1
	hope_label.text = "HOPE: %d" % GameState.hope
	pip_text.text = PIP_CHEERS[randi() % PIP_CHEERS.size()]
	await get_tree().create_timer(1.5).timeout
	current_enemy_index += 1
	enemies_remaining -= 1
	if enemies_remaining > 0:
		_next_enemy()
	else:
		_finish_encounter()

func _next_enemy() -> void:
	enemy_hp = ENEMY_MAX_HP
	narration.text = ""
	enemy.play("idle")

func _finish_encounter() -> void:
	GameState.encounter_index += 1
	get_tree().change_scene_to_file("res://scenes/corridor.tscn")
