extends Node2D

@onready var enemy_template: AnimatedSprite2D = $Enemy
@onready var enemy_layer: Node2D = $EnemyLayer
@onready var pip: AnimatedSprite2D = $UI/Pip
@onready var pip_text: Label = $UI/PipText
@onready var narration: Label = $UI/Narration
@onready var spell_buttons: HBoxContainer = $UI/SpellButtons
@onready var choice_buttons: HBoxContainer = $UI/ChoiceButtons
@onready var hope_label: Label = $UI/HopeLabel
@onready var player_hp_label: Label = $UI/PlayerHPLabel
@onready var enemy_hp_label: Label = $UI/EnemyHPLabel
@onready var pip_action_label: Label = $UI/PipActionLabel
@onready var run_button: Button = $UI/RunButton
@onready var reticle: Label = $UI/Reticle
@onready var damage_flash: Sprite2D = $Damage
@onready var ending_panel: ColorRect = $UI/EndingPanel
@onready var ending_text: Label = $UI/EndingPanel/Text
@onready var ending_button: Button = $UI/EndingPanel/Continue

enum State { PLAYER_INPUT, RESOLVING, ENEMY_TURN, PIP_TURN, CHOICE, WIN, LOSE, ENDING }
const REVEAL_CHAR_DELAY := 0.035
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

# Damage rolls per spell: [min, max]. ±1 variance around base.
const SPELL_POWER := {
	"Light":  [1, 2],
	"Shine":  [2, 3],
	"Purify": [3, 4],
}

const ENEMY_MAX_HP := 4
const ENEMY_ATTACK_RANGE := [1, 3]
const BOSS_MAX_HP := 14
const BOSS_ATTACK_RANGE := [2, 4]

# Pip turn: every Nth player turn, Pip acts.
const PIP_TURN_INTERVAL := 2
const PIP_HEAL := 3
const PIP_BUFF := 2
const PIP_HEAL_THRESHOLD := 12

const NARRATION := [
	["...mother..."],
	["...we were just—", "...please tell my—"],
	["...my children are—", "...we never wanted—"],
	["...I'm so tired...", "...don't tell them how it ends...", "...is anyone going to remember—", "...we sang to them once..."],
]

const BOSS_FLASH_LINES := [
	"...please... I haven't seen my—",
	"...don't listen to it... it's lying...",
	"...my name was—",
	"...we were just running...",
	"...the light... the light hurts...",
	"...you don't have to do this...",
]

const PIP_GASLIGHT_LINES := [
	"Don't listen! It's trying to confuse you!",
	"It speaks in lies, hero. Strike again!",
	"The Shadow wears faces. Shine through it!",
	"It will say ANYTHING to stop you. END IT!",
	"That's not real. I'M real. Hit it!",
]

var enemies: Array = [] # [{ sprite, hp_label, hp, max_hp, alive }]
var target_index: int = 0
var damage_buff: int = 0
var turns_taken: int = 0
var is_boss_fight: bool = false
var current_enemy_index: int = 0
var boss_flash_active: bool = false

func _ready() -> void:
	is_boss_fight = GameState.is_boss_next()
	enemy_template.visible = false
	pip.play("sparkle")
	narration.text = ""
	pip_action_label.text = ""
	ending_panel.visible = false
	choice_buttons.visible = false
	run_button.visible = is_boss_fight
	reticle.visible = false
	if not run_button.pressed.is_connected(_on_run_pressed):
		run_button.pressed.connect(_on_run_pressed)
	if not ending_button.pressed.is_connected(_on_ending_continue):
		ending_button.pressed.connect(_on_ending_continue)
	var n: int = GameState.enemies_for_current_encounter()
	if n <= 0:
		_finish_encounter()
		return
	Audio.play_music()
	_spawn_enemies(n)
	target_index = 0
	_update_reticle()
	_update_hud()
	_pick_expected_spell()
	_set_mood(Mood.NORMAL)
	state = State.PLAYER_INPUT
	if is_boss_fight:
		await _reveal_narration("A vast Shadow blocks the path.")
		_start_boss_flash_loop()

func _process(_delta: float) -> void:
	if state != State.PLAYER_INPUT:
		return
	if Input.is_action_just_pressed("ui_left"):
		_cycle_target(-1)
	elif Input.is_action_just_pressed("ui_right"):
		_cycle_target(1)

func _cycle_target(dir: int) -> void:
	var alive_idxs: Array = []
	for i in enemies.size():
		if enemies[i].alive:
			alive_idxs.append(i)
	if alive_idxs.is_empty():
		return
	var pos: int = alive_idxs.find(target_index)
	if pos == -1:
		target_index = alive_idxs[0]
	else:
		var new_pos: int = (pos + dir) % alive_idxs.size()
		if new_pos < 0:
			new_pos += alive_idxs.size()
		target_index = alive_idxs[new_pos]
	Audio.play_sfx("tap", -6.0)
	_update_reticle()
	_update_hud()

func _spawn_enemies(n: int) -> void:
	var positions: Array = _enemy_positions(n)
	var max_hp: int = BOSS_MAX_HP if is_boss_fight else ENEMY_MAX_HP
	for i in n:
		var spr: AnimatedSprite2D = enemy_template.duplicate()
		enemy_layer.add_child(spr)
		spr.visible = true
		spr.position = positions[i]
		spr.play("idle")
		if is_boss_fight:
			spr.scale = Vector2(1.4, 1.4)
			spr.modulate = Color(1.0, 0.7, 0.7)
		var hp_label := Label.new()
		hp_label.add_theme_font_size_override("font_size", 14)
		hp_label.add_theme_color_override("font_color", Color(1, 0.9, 0.9))
		hp_label.text = "%d/%d" % [max_hp, max_hp]
		hp_label.size = Vector2(80, 20)
		var y_off: float = -120.0 if is_boss_fight else -90.0
		hp_label.position = positions[i] + Vector2(-40, y_off)
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(hp_label)
		enemies.append({
			"sprite": spr,
			"hp_label": hp_label,
			"hp": max_hp,
			"max_hp": max_hp,
			"alive": true,
		})

func _enemy_positions(n: int) -> Array:
	var y: float = 320.0
	var center_x: float = 480.0
	var spacing: float = 130.0
	if n == 1:
		return [Vector2(center_x, y)]
	var positions: Array = []
	var total_w: float = spacing * float(n - 1)
	var start_x: float = center_x - total_w / 2.0
	for i in n:
		positions.append(Vector2(start_x + float(i) * spacing, y))
	return positions

func _alive_count() -> int:
	var c: int = 0
	for e in enemies:
		if e.alive:
			c += 1
	return c

func _update_reticle() -> void:
	if target_index < 0 or target_index >= enemies.size() or not enemies[target_index].alive:
		reticle.visible = false
		return
	var e = enemies[target_index]
	reticle.visible = true
	var pos: Vector2 = e.sprite.position
	var y_off: float = -150.0 if is_boss_fight else -110.0
	reticle.position = pos + Vector2(-15, y_off)
	# Highlight target, dim others.
	for i in enemies.size():
		var en = enemies[i]
		if not en.alive:
			continue
		if i == target_index:
			en.sprite.modulate = Color(1.0, 0.7, 0.7) if is_boss_fight else Color(1, 1, 1)
		else:
			en.sprite.modulate = Color(0.7, 0.55, 0.55) if is_boss_fight else Color(0.6, 0.6, 0.6)

func _update_hud() -> void:
	hope_label.text = "HOPE: %d" % GameState.hope
	player_hp_label.text = "HP: %d/%d" % [GameState.player_hp, GameState.PLAYER_MAX_HP]
	if target_index >= 0 and target_index < enemies.size() and enemies[target_index].alive:
		var e = enemies[target_index]
		var lbl: String = "Boss" if is_boss_fight else "Target"
		enemy_hp_label.text = "%s: %d/%d" % [lbl, max(e.hp, 0), e.max_hp]
	else:
		enemy_hp_label.text = ""
	for e in enemies:
		if e.alive:
			e.hp_label.text = "%d/%d" % [max(e.hp, 0), e.max_hp]
		else:
			e.hp_label.visible = false

func _on_spell_pressed(spell_name: String = "Light") -> void:
	if state != State.PLAYER_INPUT:
		return
	if target_index < 0 or target_index >= enemies.size() or not enemies[target_index].alive:
		return
	state = State.RESOLVING
	Audio.play_sfx("enchant")
	if spell_name == expected_spell:
		wrong_spell_streak = 0
		_set_mood(Mood.EXCITED)
	else:
		wrong_spell_streak += 1
		_set_mood(Mood.ANGRY if wrong_spell_streak >= 2 else Mood.UPSET)
	var damage: int = _roll_spell_damage(spell_name)
	if damage_buff > 0:
		damage += damage_buff
		damage_buff = 0
		pip_action_label.text = ""
	var target = enemies[target_index]
	target.hp -= damage
	_flash_damage(target.sprite.position)
	_show_damage_number(target.sprite.position, damage)
	_update_hud()
	if target.hp <= 0:
		await _kill_enemy(target_index)
		if state == State.ENDING or state == State.CHOICE:
			return
	else:
		target.sprite.play("cry")
		await get_tree().create_timer(0.6).timeout
		if target.alive:
			target.sprite.play("idle")
	if _alive_count() == 0:
		return
	await _advance_turn()

func _roll_spell_damage(spell_name: String) -> int:
	var range_pair: Array = SPELL_POWER.get(spell_name, [1, 1])
	var lo: int = int(range_pair[0])
	var hi: int = int(range_pair[1])
	return randi_range(lo, hi)

func _advance_turn() -> void:
	turns_taken += 1
	if turns_taken % PIP_TURN_INTERVAL == 0:
		await _pip_turn()
	if state == State.ENDING or state == State.LOSE:
		return
	await _enemy_turn()

func _pip_turn() -> void:
	state = State.PIP_TURN
	await get_tree().create_timer(0.4).timeout
	var did_heal: bool = GameState.player_hp <= PIP_HEAL_THRESHOLD
	Audio.play_sfx("power_up")
	if did_heal:
		var heal: int = min(PIP_HEAL, GameState.PLAYER_MAX_HP - GameState.player_hp)
		GameState.player_hp += heal
		pip_action_label.text = "Pip: Cheer!  +%d HP" % heal
		if not boss_flash_active:
			pip_text.text = "Stay bright, hero!"
		_show_damage_number(Vector2(150, 250), heal, Color(0.7, 1, 0.7))
	else:
		damage_buff = PIP_BUFF
		pip_action_label.text = "Pip: Enchant!  next spell +%d" % PIP_BUFF
		if not boss_flash_active:
			pip_text.text = "I bless your strike!"
	pip.modulate = Color(1, 1, 0.6)
	pip.scale = Vector2(0.5, 0.5) * 1.25
	_update_hud()
	await get_tree().create_timer(0.9).timeout
	pip.modulate = MOOD_TINTS[mood]
	pip.scale = Vector2(0.5, 0.5)

func _enemy_turn() -> void:
	state = State.ENEMY_TURN
	await get_tree().create_timer(0.4).timeout
	if _alive_count() == 0:
		return
	var atk_range: Array = BOSS_ATTACK_RANGE if is_boss_fight else ENEMY_ATTACK_RANGE
	var total: int = 0
	if is_boss_fight:
		total = randi_range(int(atk_range[0]), int(atk_range[1]))
	else:
		for e in enemies:
			if e.alive:
				total += randi_range(int(atk_range[0]), int(atk_range[1]))
	GameState.player_hp -= total
	Audio.play_sfx("hurt")
	_flash_damage(Vector2(480, 270))
	_show_damage_number(Vector2(480, 250), total, Color(1, 0.5, 0.5))
	_set_mood(Mood.UPSET)
	_update_hud()
	if GameState.player_hp <= 0:
		GameState.player_hp = 0
		_update_hud()
		state = State.LOSE
		_game_over()
		return
	await get_tree().create_timer(0.5).timeout
	_pick_expected_spell()
	_set_mood(Mood.NORMAL)
	state = State.PLAYER_INPUT

func _kill_enemy(idx: int) -> void:
	var e = enemies[idx]
	e.alive = false
	e.sprite.play("dead")
	e.sprite.modulate = Color(0.85, 0.85, 0.85)
	if e.hp_label:
		e.hp_label.visible = false
	Audio.play_sfx("explosion")
	Audio.play_sfx("power_up")
	GameState.hope += 1
	_set_mood(Mood.HAPPY)
	_update_hud()
	if not is_boss_fight:
		var enc: int = GameState.encounter_index
		if enc < NARRATION.size() and current_enemy_index < NARRATION[enc].size():
			await _reveal_narration(NARRATION[enc][current_enemy_index])
		else:
			await get_tree().create_timer(0.6).timeout
		current_enemy_index += 1
	else:
		await get_tree().create_timer(0.8).timeout
	# Move target if it died.
	if _alive_count() > 0 and not enemies[target_index].alive:
		_cycle_target(1)
		_update_hud()
	if _alive_count() == 0:
		if is_boss_fight:
			GameState.beat_boss = true
			_start_ending(true)
		else:
			_offer_choice()

func _reveal_narration(line: String) -> void:
	narration.text = ""
	for i in line.length():
		narration.text = line.substr(0, i + 1)
		await get_tree().create_timer(REVEAL_CHAR_DELAY).timeout
	await get_tree().create_timer(0.5).timeout

func _offer_choice() -> void:
	state = State.CHOICE
	spell_buttons.visible = false
	choice_buttons.visible = true
	pip_text.text = "Did you hear them?"

func _on_listen_pressed() -> void:
	if state != State.CHOICE:
		return
	Audio.play_sfx("tap")
	GameState.compassion += 1
	_resolve_choice()

func _on_walk_pressed() -> void:
	if state != State.CHOICE:
		return
	Audio.play_sfx("tap")
	_resolve_choice()

func _resolve_choice() -> void:
	choice_buttons.visible = false
	spell_buttons.visible = true
	state = State.WIN
	_finish_encounter()

func _finish_encounter() -> void:
	GameState.encounter_index += 1
	get_tree().change_scene_to_file("res://scenes/corridor.tscn")

func _pick_expected_spell() -> void:
	var keys: Array = SPELL_POWER.keys()
	expected_spell = keys[randi() % keys.size()]

func _set_mood(new_mood: Mood) -> void:
	mood = new_mood
	pip.modulate = MOOD_TINTS[new_mood]
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
	if boss_flash_active:
		return
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

func _show_damage_number(at: Vector2, amount: int, color: Color = Color(1, 0.95, 0.6)) -> void:
	var lbl := Label.new()
	var prefix: String = "+" if color.g > color.r else "-"
	lbl.text = "%s%d" % [prefix, amount]
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", color)
	lbl.position = at + Vector2(-12, -40)
	add_child(lbl)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -30), 0.7)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(lbl.queue_free)

func _game_over() -> void:
	pip_text.text = "The light fades..."
	await get_tree().create_timer(2.0).timeout
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/title.tscn")

# --- Boss flashes ----------------------------------------------------------

func _start_boss_flash_loop() -> void:
	while is_boss_fight and state != State.ENDING and state != State.LOSE and _alive_count() > 0:
		await get_tree().create_timer(randf_range(4.5, 7.5)).timeout
		if state == State.ENDING or state == State.LOSE or _alive_count() == 0:
			return
		await _do_boss_flash()

func _do_boss_flash() -> void:
	if enemies.is_empty() or not enemies[0].alive:
		return
	boss_flash_active = true
	var boss_spr: AnimatedSprite2D = enemies[0].sprite
	var prior_mod: Color = boss_spr.modulate
	var prior_scale: Vector2 = boss_spr.scale
	var frames: SpriteFrames = boss_spr.sprite_frames
	var has_normal: bool = frames != null and frames.has_animation("normal")
	if has_normal:
		boss_spr.play("normal")
	boss_spr.modulate = Color(1.0, 1.0, 1.0)
	boss_spr.scale = prior_scale * 0.95
	await _reveal_narration(BOSS_FLASH_LINES[randi() % BOSS_FLASH_LINES.size()])
	# Pip cuts in.
	pip_text.text = PIP_GASLIGHT_LINES[randi() % PIP_GASLIGHT_LINES.size()]
	pip.modulate = Color(1, 0.7, 0.7)
	pip.scale = Vector2(0.5, 0.5) * 1.25
	await get_tree().create_timer(1.6).timeout
	# Restore.
	if enemies[0].alive:
		boss_spr.play("idle")
		boss_spr.modulate = prior_mod
		boss_spr.scale = prior_scale
	boss_flash_active = false
	narration.text = ""
	pip.modulate = MOOD_TINTS[mood]
	pip.scale = Vector2(0.5, 0.5)
	if state == State.PLAYER_INPUT:
		pip_text.text = PIP_HINTS.get(expected_spell, "")

# --- Run / Ending ---------------------------------------------------------

func _on_run_pressed() -> void:
	if not is_boss_fight:
		return
	if state == State.ENDING or state == State.LOSE:
		return
	Audio.play_sfx("tap")
	GameState.ran_from_boss = true
	_start_ending(false)

func _start_ending(beat: bool) -> void:
	state = State.ENDING
	run_button.visible = false
	spell_buttons.visible = false
	choice_buttons.visible = false
	reticle.visible = false
	pip_action_label.text = ""
	enemy_hp_label.text = ""
	ending_panel.visible = true
	var lines: Array
	if beat:
		lines = [
			"The Shadow falls.",
			"For a moment you see what it was: a face. Tired. Small.",
			"Pip beams. \"HOPE: %d. We did it, hero!\"" % GameState.hope,
			"The corridor is quiet now.",
			"Somewhere, a small bright voice is greeting another traveler.",
		]
	else:
		lines = [
			"You turn and walk back the way you came.",
			"The Shadow does not follow. It never could.",
			"Behind you, Pip's voice rises, sweet again.",
			"\"Hello? — Oh! Hello, traveler!\"",
			"You keep walking. You keep walking. You keep walking.",
		]
	ending_text.text = "\n\n".join(lines)
	ending_button.grab_focus()

func _on_ending_continue() -> void:
	Audio.play_sfx("tap")
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/title.tscn")

func _on_light_pressed() -> void: _on_spell_pressed("Light")
func _on_shine_pressed() -> void: _on_spell_pressed("Shine")
func _on_purify_pressed() -> void: _on_spell_pressed("Purify")
