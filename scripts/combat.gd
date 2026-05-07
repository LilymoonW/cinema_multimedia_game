extends Node2D

@onready var enemy: AnimatedSprite2D = $Enemy
@onready var pip: AnimatedSprite2D = $UI/Pip
@onready var pip_text: Label = $UI/PipText
@onready var narration: Label = $UI/Narration
@onready var spell_buttons: HBoxContainer = $UI/SpellButtons
@onready var hope_label: Label = $UI/HopeLabel
@onready var player_hp_label: Label = $UI/PlayerHPLabel
@onready var enemy_hp_label: Label = $UI/EnemyHPLabel
@onready var damage_flash: Sprite2D = $Damage

enum State { PLAYER_INPUT, RESOLVING, ENEMY_TURN, WIN, LOSE }
var state: State = State.PLAYER_INPUT

enum Mood { NORMAL, EXCITED, HAPPY, UPSET, ANGRY }
var mood: Mood = Mood.NORMAL
var wrong_spell_streak: int = 0
var expected_spell: String = "Light"

const MOOD_TINTS := {
	Mood.NORMAL:  Color(1, 1, 1, 1),
	Mood.EXCITED: Color(1, 1, 0.85, 1),
	Mood.HAPPY:   Color(1, 0.95, 0.75, 1),
	Mood.UPSET:   Color(0.85, 0.9, 1, 1),
	Mood.ANGRY:   Color(1, 0.8, 0.8, 1),
}

const PIP_LINES := {
	Mood.NORMAL:  ["..."],
	Mood.EXCITED: ["Yes! Hit them!", "That's the one!", "Good choice!"],
	Mood.HAPPY:   ["Amazing! +1 HOPE!", "You're so powerful!", "The Bright One shines!", "Keep going, hero!"],
	Mood.UPSET:   ["...you can do better.", "...that wasn't what I wanted.", "...try harder."],
	Mood.ANGRY:   ["WHY won't you LISTEN?!", "Stop disappointing me!", "USE THE RIGHT ONE!"],
}

const PIP_HINTS := {
	"Light":  "Pip points... use Light.",
	"Shine":  "Pip points... use Shine.",
	"Purify": "Pip points... use Purify.",
}

const ENEMY_MAX_HP := 4
const ENEMY_ATTACK := 2

# Per-spell damage. Tweak freely.
const SPELL_POWER := {
	"Light": 1,
	"Shine": 2,
	"Purify": 3,
}

var enemy_hp: int = ENEMY_MAX_HP
var enemies_remaining: int = 1
var current_enemy_index: int = 0

const NARRATION := [
	["...mother..."],
	["...we were just—", "...please tell my—"],
	["...my children are—", "...we never wanted—"],
	["...I'm so tired...", "...don't tell them how it ends...", "...is anyone going to remember—", "...we sang to them once..."],
]

func _ready() -> void:
	enemies_remaining = GameState.enemies_for_current_encounter()
	if enemies_remaining == 0:
		_finish_encounter()
		return
	enemy.play("idle")
	pip.play("sparkle")
	narration.text = ""
	_update_hud()
	_pick_expected_spell()
	_set_mood(Mood.NORMAL)
	state = State.PLAYER_INPUT

func _update_hud() -> void:
	hope_label.text = "HOPE: %d" % GameState.hope
	player_hp_label.text = "HP: %d/%d" % [GameState.player_hp, GameState.PLAYER_MAX_HP]
	enemy_hp_label.text = "Enemy: %d/%d" % [max(enemy_hp, 0), ENEMY_MAX_HP]

func _on_spell_pressed(spell_name: String = "Light") -> void:
	if state != State.PLAYER_INPUT:
		return
	state = State.RESOLVING
	if spell_name == expected_spell:
		wrong_spell_streak = 0
		_set_mood(Mood.EXCITED)
	else:
		wrong_spell_streak += 1
		_set_mood(Mood.ANGRY if wrong_spell_streak >= 2 else Mood.UPSET)
	var damage: int = SPELL_POWER.get(spell_name, 1)
	enemy_hp -= damage
	_flash_damage(enemy.position)
	_update_hud()
	if enemy_hp <= 0:
		await _kill_enemy()
		return
	enemy.play("cry")
	await get_tree().create_timer(0.8).timeout
	_enemy_turn()

func _enemy_turn() -> void:
	state = State.ENEMY_TURN
	await get_tree().create_timer(0.7).timeout
	GameState.player_hp -= ENEMY_ATTACK
	_flash_damage(Vector2(480, 270))
	_set_mood(Mood.UPSET)
	_update_hud()
	if GameState.player_hp <= 0:
		GameState.player_hp = 0
		_update_hud()
		state = State.LOSE
		_game_over()
		return
	enemy.play("idle")
	await get_tree().create_timer(0.6).timeout
	_pick_expected_spell()
	_set_mood(Mood.NORMAL)
	state = State.PLAYER_INPUT

func _kill_enemy() -> void:
	var enc := GameState.encounter_index
	if enc < NARRATION.size() and current_enemy_index < NARRATION[enc].size():
		narration.text = NARRATION[enc][current_enemy_index]
	enemy.play("dead")
	GameState.hope += 1
	_set_mood(Mood.HAPPY)
	_update_hud()
	await get_tree().create_timer(1.5).timeout
	current_enemy_index += 1
	enemies_remaining -= 1
	if enemies_remaining > 0:
		_next_enemy()
	else:
		state = State.WIN
		_finish_encounter()

func _next_enemy() -> void:
	enemy_hp = ENEMY_MAX_HP
	narration.text = ""
	enemy.play("idle")
	_update_hud()
	_pick_expected_spell()
	_set_mood(Mood.NORMAL)
	state = State.PLAYER_INPUT

func _finish_encounter() -> void:
	GameState.encounter_index += 1
	get_tree().change_scene_to_file("res://scenes/corridor.tscn")

func _pick_expected_spell() -> void:
	var keys: Array = SPELL_POWER.keys()
	expected_spell = keys[randi() % keys.size()]

func _set_mood(new_mood: Mood) -> void:
	mood = new_mood
	pip.modulate = MOOD_TINTS[new_mood]
	# Tiny scale punch on positive moods, droop on negative.
	var base_scale := Vector2(0.5, 0.5)
	match new_mood:
		Mood.EXCITED, Mood.HAPPY:
			pip.scale = base_scale * 1.15
		Mood.UPSET:
			pip.scale = base_scale * 0.9
		Mood.ANGRY:
			pip.scale = base_scale * 1.2
		_:
			pip.scale = base_scale
	# Pick a line for the mood, then on NORMAL append the hint.
	var lines: Array = PIP_LINES[new_mood]
	var line: String = lines[randi() % lines.size()]
	if new_mood == Mood.NORMAL:
		line = PIP_HINTS.get(expected_spell, "")
	pip_text.text = line

func _flash_damage(at: Vector2) -> void:
	damage_flash.position = at
	damage_flash.modulate.a = 1.0
	damage_flash.visible = true
	var tween := create_tween()
	tween.tween_property(damage_flash, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func(): damage_flash.visible = false)

func _game_over() -> void:
	pip_text.text = "The light fades..."
	await get_tree().create_timer(2.0).timeout
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/title.tscn")

func _on_light_pressed() -> void: _on_spell_pressed("Light")
func _on_shine_pressed() -> void: _on_spell_pressed("Shine")
func _on_purify_pressed() -> void: _on_spell_pressed("Purify")
