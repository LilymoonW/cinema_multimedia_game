extends Node2D

@onready var enemy_template: AnimatedSprite2D = $Enemy
@onready var boss_template: AnimatedSprite2D = $BossTemplate
@onready var enemy_layer: Node2D = $EnemyLayer
@onready var pip: AnimatedSprite2D = $UI/Pip
@onready var pip_text: Label = $UI/PipText
@onready var narration: Label = $UI/Narration
@onready var narration_bg: ColorRect = $UI/NarrationBg
@onready var narration_continue: Button = $UI/NarrationContinue
@onready var spell_buttons: HBoxContainer = $UI/SpellButtons
@onready var shine_btn: Button = $UI/SpellButtons/ShineBtn
@onready var purify_btn: Button = $UI/SpellButtons/PurifyBtn
@onready var choice_buttons: HBoxContainer = $UI/ChoiceButtons
@onready var observe_btn: Button = $UI/ChoiceButtons/ObserveBtn
@onready var walk_btn: Button = $UI/ChoiceButtons/WalkBtn
@onready var pip_choice_buttons: HBoxContainer = $UI/PipChoiceButtons
@onready var cheer_btn: Button = $UI/PipChoiceButtons/CheerBtn
@onready var heal_btn: Button = $UI/PipChoiceButtons/HealBtn
@onready var hope_label: Label = $UI/HopeLabel
@onready var player_hp_label: Label = $UI/PlayerHPLabel
@onready var pip_action_label: Label = $UI/PipActionLabel
@onready var run_button: Button = $UI/RunButton
@onready var action_buttons: HBoxContainer = $UI/ActionButtons
@onready var fight_btn: Button = $UI/ActionButtons/FightBtn
@onready var run_menu_btn: Button = $UI/ActionButtons/RunBtn
@onready var action_cursor: Label = $UI/ActionCursor
@onready var reticle: Label = $UI/Reticle
@onready var damage_flash: Sprite2D = $Damage
@onready var spell_effect: AnimatedSprite2D = $SpellEffect
@onready var profile: AnimatedSprite2D = $UI/Profile
@onready var actor_turn_label: Label = $UI/ActorTurnLabel

enum State { ACTION_SELECT, PLAYER_INPUT, RESOLVING, ENEMY_TURN, PIP_TURN, CHOICE, WIN, LOSE, ENDING }
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
	"Shine":  "Pip points... use Shine.",
	"Purify": "Pip points... use Purify.",
}

# Damage rolls per spell: [min, max]. ±1 variance around base.
const SPELL_POWER := {
	"Shine":  [2, 3],
	"Purify": [3, 4],
}

const ENEMY_MAX_HP := 4
const ENEMY_ATTACK_RANGE := [1, 3]
const BOSS_MAX_HP := 14
const BOSS_ATTACK_RANGE := [2, 4]

# Pip acts at the start of every round, before the player's spell.
const PIP_HEAL := 3
const PIP_BUFF := 2

const NARRATION := [
	["...mother..."],
	["...we were just—", "...please tell my—"],
	["...we never wanted—", "...is anyone going to remember—"],
]

const BOSS_FLASH_LINES := [
	"...please... I haven't seen my—",
	"...don't listen to it... it's lying...",
	"...my name was—",
	"...we were just running...",
	"...the light... the light hurts...",
	"...you don't have to do this...",
]

const BOSS_LETTER := "All we wanted was to have a better life here! It was for a better life for me and my children, but they they slowly turned against us blaming us for famine and disease. We had no option to run hide, and fight."

const PIP_GASLIGHT_LINES := [
	"Don't listen! It's trying to confuse you!",
	"It speaks in lies, hero. Strike again!",
	"The Shadow wears faces. Shine through it!",
	"It will say ANYTHING to stop you. END IT!",
	"That's not real. I'M real. Hit it!",
]

const OBSERVE_LINES := [
	"A small wooden charm rests in the dirt. A child's name, carved badly.",
	"Two of them fell holding each other. You hadn't noticed before.",
	"For some reason they look pitiful, they look malnourished, you doubt they are of any harm.",
]

const PIP_OBSERVE_REBUKES := [
	"Don't. Don't look so long, hero. They were Shadows.",
	"...you're imagining things. The light shows what's true.",
	"Eyes UP. There's more road ahead.",
	"Nothing to see there. Glory lies ahead.",
]

const PIP_RUN_HOVER_LINES := [
	"Don't you DARE run, hero!",
	"Cowards don't shine. FIGHT.",
	"You can't run from the LIGHT.",
	"Turn back and I'll never forgive you!",
]

const PIP_FIGHT_HOVER_LINES := [
	"Yes! Show them your light!",
	"That's MY hero!",
	"Strike them down!",
]

var enemies: Array = [] # [{ sprite, hp_label, hp, max_hp, alive }]
var target_index: int = 0
var damage_buff: int = 0
var is_boss_fight: bool = false
var current_enemy_index: int = 0
var friends_lost: bool = false
var boss_flash_active: bool = false
var current_actor: String = "player"
var action_index: int = 0
var spell_index: int = 0
var pip_choice_index: int = 0
var post_choice_index: int = 0
var boss_letter_choice: bool = false
const SPELL_NAMES := ["Shine", "Purify"]

func _ready() -> void:
	is_boss_fight = GameState.is_boss_next()
	enemy_template.visible = false
	boss_template.visible = false
	pip.play("sparkle")
	profile.play("idle")
	narration.text = ""
	pip_action_label.text = ""
	narration_bg.visible = false
	narration_continue.visible = false
	choice_buttons.visible = false
	pip_choice_buttons.visible = false
	run_button.visible = is_boss_fight
	reticle.visible = false
	if not run_button.pressed.is_connected(_on_run_pressed):
		run_button.pressed.connect(_on_run_pressed)
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
	if is_boss_fight:
		await _reveal_narration("A vast Shadow blocks the path.")
		_start_boss_flash_loop()
	_start_action_select()

func _process(_delta: float) -> void:
	match state:
		State.ACTION_SELECT:
			if Input.is_action_just_pressed("ui_left"):
				_cycle_action(-1)
			elif Input.is_action_just_pressed("ui_right"):
				_cycle_action(1)
			elif Input.is_action_just_pressed("ui_accept"):
				_confirm_action()
		State.PLAYER_INPUT:
			if Input.is_action_just_pressed("ui_left"):
				_cycle_spell(-1)
			elif Input.is_action_just_pressed("ui_right"):
				_cycle_spell(1)
			elif Input.is_action_just_pressed("ui_up"):
				_cycle_target(-1)
			elif Input.is_action_just_pressed("ui_down"):
				_cycle_target(1)
			elif Input.is_action_just_pressed("ui_accept"):
				_on_spell_pressed(SPELL_NAMES[spell_index])
		State.PIP_TURN:
			if Input.is_action_just_pressed("ui_left"):
				_cycle_pip_choice(-1)
			elif Input.is_action_just_pressed("ui_right"):
				_cycle_pip_choice(1)
			elif Input.is_action_just_pressed("ui_accept"):
				_confirm_pip_choice()
		State.CHOICE:
			if Input.is_action_just_pressed("ui_left"):
				_cycle_post_choice(-1)
			elif Input.is_action_just_pressed("ui_right"):
				_cycle_post_choice(1)
			elif Input.is_action_just_pressed("ui_accept"):
				_confirm_post_choice()

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
	var template: AnimatedSprite2D = boss_template if is_boss_fight else enemy_template
	for i in n:
		var spr: AnimatedSprite2D = template.duplicate()
		enemy_layer.add_child(spr)
		spr.visible = true
		spr.position = positions[i]
		spr.play("idle")
		if is_boss_fight:
			spr.scale = Vector2(1.4, 1.4)
			spr.modulate = Color(1.0, 0.85, 0.85)
		var bar_width: float = 150.0 if is_boss_fight else 110.0
		var bar_height: float = 14.0 if is_boss_fight else 12.0
		var y_off: float = 150.0 if is_boss_fight else 95.0
		var bar_root := Node2D.new()
		bar_root.position = positions[i] + Vector2(0, y_off)
		add_child(bar_root)
		var hp_bar_outer := ColorRect.new()
		hp_bar_outer.color = Color(0.95, 0.85, 1.0, 0.9)
		hp_bar_outer.size = Vector2(bar_width + 8, bar_height + 8)
		hp_bar_outer.position = Vector2(-(bar_width + 8) / 2.0, -(bar_height + 8) / 2.0)
		bar_root.add_child(hp_bar_outer)
		var hp_bar_bg := ColorRect.new()
		hp_bar_bg.color = Color(0.16, 0.08, 0.24, 0.92)
		hp_bar_bg.size = Vector2(bar_width + 4, bar_height + 4)
		hp_bar_bg.position = Vector2(-(bar_width + 4) / 2.0, -(bar_height + 4) / 2.0)
		bar_root.add_child(hp_bar_bg)
		var hp_bar_fill := ColorRect.new()
		hp_bar_fill.color = Color(0.55, 1.0, 0.85, 1.0)
		hp_bar_fill.size = Vector2(bar_width, bar_height)
		hp_bar_fill.position = Vector2(-bar_width / 2.0, -bar_height / 2.0)
		bar_root.add_child(hp_bar_fill)
		enemies.append({
			"sprite": spr,
			"hp_bar_root": bar_root,
			"hp_bar_fill": hp_bar_fill,
			"hp_bar_width": bar_width,
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
	for e in enemies:
		if e.alive:
			var ratio: float = clamp(float(e.hp) / float(e.max_hp), 0.0, 1.0)
			e.hp_bar_fill.size.x = e.hp_bar_width * ratio
			# Green when healthy, fading to red as HP drops.
			e.hp_bar_fill.color = Color(0.55, 1.0, 0.85).lerp(Color(1.0, 0.55, 0.75), 1.0 - ratio)
		else:
			e.hp_bar_root.visible = false

func _on_spell_pressed(spell_name: String = "Light") -> void:
	if state != State.PLAYER_INPUT:
		return
	if target_index < 0 or target_index >= enemies.size() or not enemies[target_index].alive:
		return
	state = State.RESOLVING
	action_cursor.visible = false
	_highlight_pair([shine_btn, purify_btn], -1)
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
	_play_spell_effect(spell_name, target.sprite.position)
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
			target.sprite.play(_default_enemy_anim())
	if _alive_count() == 0:
		return
	await _enemy_turn()

func _roll_spell_damage(spell_name: String) -> int:
	var range_pair: Array = SPELL_POWER.get(spell_name, [1, 1])
	var lo: int = int(range_pair[0])
	var hi: int = int(range_pair[1])
	return randi_range(lo, hi)

# --- Action select (FIGHT / RUN) ------------------------------------------

func _start_action_select() -> void:
	state = State.ACTION_SELECT
	_set_active_actor("player")
	spell_buttons.visible = false
	pip_choice_buttons.visible = false
	choice_buttons.visible = false
	action_buttons.visible = true
	action_cursor.visible = true
	action_index = 0
	_update_action_cursor()

func _cycle_action(dir: int) -> void:
	action_index = (action_index + dir) % 2
	if action_index < 0:
		action_index += 2
	Audio.play_sfx("tap", -6.0)
	_update_action_cursor()

func _update_action_cursor() -> void:
	var btn: Button = fight_btn if action_index == 0 else run_menu_btn
	# Anchor cursor to the left edge of the highlighted button.
	var rect: Rect2 = btn.get_global_rect()
	action_cursor.global_position = rect.position + Vector2(-28, rect.size.y / 2.0 - 18)
	# Visually highlight the focused button.
	fight_btn.modulate = Color(1, 1, 1) if action_index == 0 else Color(0.7, 0.7, 0.7)
	run_menu_btn.modulate = Color(1, 1, 1) if action_index == 1 else Color(0.7, 0.7, 0.7)
	# Pip reacts to what you're hovering.
	if boss_flash_active:
		return
	if action_index == 1:
		pip.modulate = MOOD_TINTS[Mood.ANGRY] * Color(1, 0.8, 0.8)
		pip.scale = Vector2(0.5, 0.5) * 1.2
		pip_text.text = PIP_RUN_HOVER_LINES[randi() % PIP_RUN_HOVER_LINES.size()]
	else:
		pip.modulate = MOOD_TINTS[mood]
		pip.scale = Vector2(0.5, 0.5)
		pip_text.text = PIP_FIGHT_HOVER_LINES[randi() % PIP_FIGHT_HOVER_LINES.size()]

func _confirm_action() -> void:
	if action_index == 0:
		_on_fight_pressed()
	else:
		_on_run_menu_pressed()

# --- Generic cursor helper ------------------------------------------------

func _show_cursor_at(btn: Button) -> void:
	action_cursor.visible = true
	var rect: Rect2 = btn.get_global_rect()
	action_cursor.global_position = rect.position + Vector2(-28, rect.size.y / 2.0 - 18)

func _highlight_pair(buttons: Array, focused_idx: int) -> void:
	# focused_idx == -1 clears highlight (used when leaving the menu).
	for i in buttons.size():
		if focused_idx < 0:
			buttons[i].modulate = Color(1, 1, 1)
		else:
			buttons[i].modulate = Color(1, 1, 1) if i == focused_idx else Color(0.7, 0.7, 0.7)

# --- Spell select (Shine / Purify) ----------------------------------------

func _refresh_spell_cursor() -> void:
	if state != State.PLAYER_INPUT:
		return
	var btn: Button = shine_btn if spell_index == 0 else purify_btn
	_show_cursor_at(btn)
	_highlight_pair([shine_btn, purify_btn], spell_index)

func _cycle_spell(dir: int) -> void:
	spell_index = (spell_index + dir) % SPELL_NAMES.size()
	if spell_index < 0:
		spell_index += SPELL_NAMES.size()
	Audio.play_sfx("tap", -6.0)
	_refresh_spell_cursor()

# --- Pip menu (Cheer / Heal) -------------------------------------------

func _refresh_pip_cursor() -> void:
	if state != State.PIP_TURN:
		return
	var btn: Button = cheer_btn if pip_choice_index == 0 else heal_btn
	_show_cursor_at(btn)
	_highlight_pair([cheer_btn, heal_btn], pip_choice_index)

func _cycle_pip_choice(dir: int) -> void:
	pip_choice_index = (pip_choice_index + dir) % 2
	if pip_choice_index < 0:
		pip_choice_index += 2
	Audio.play_sfx("tap", -6.0)
	_refresh_pip_cursor()

func _confirm_pip_choice() -> void:
	if pip_choice_index == 0:
		_on_cheer_pressed()
	else:
		_on_heal_pressed()

# --- Post-fight choice (Observe / Walk) -----------------------------------

func _refresh_post_choice_cursor() -> void:
	if state != State.CHOICE:
		return
	var btn: Button = observe_btn if post_choice_index == 0 else walk_btn
	_show_cursor_at(btn)
	_highlight_pair([observe_btn, walk_btn], post_choice_index)

func _cycle_post_choice(dir: int) -> void:
	post_choice_index = (post_choice_index + dir) % 2
	if post_choice_index < 0:
		post_choice_index += 2
	Audio.play_sfx("tap", -6.0)
	_refresh_post_choice_cursor()

func _confirm_post_choice() -> void:
	if post_choice_index == 0:
		_on_observe_pressed()
	else:
		_on_walk_pressed()

func _on_fight_pressed() -> void:
	if state != State.ACTION_SELECT:
		return
	Audio.play_sfx("tap")
	action_buttons.visible = false
	action_cursor.visible = false
	fight_btn.modulate = Color(1, 1, 1)
	run_menu_btn.modulate = Color(1, 1, 1)
	pip.modulate = MOOD_TINTS[mood]
	pip.scale = Vector2(0.5, 0.5)
	_start_round()

func _on_run_menu_pressed() -> void:
	if state != State.ACTION_SELECT:
		return
	Audio.play_sfx("tap")
	action_buttons.visible = false
	action_cursor.visible = false
	if is_boss_fight:
		GameState.ran_from_boss = true
		_start_ending(false)
		return
	# Regular encounter: you walk away. Pip rages but can't stop you.
	state = State.RESOLVING
	pip.modulate = MOOD_TINTS[Mood.ANGRY]
	pip.scale = Vector2(0.5, 0.5) * 1.2
	pip_text.text = PIP_RUN_HOVER_LINES[randi() % PIP_RUN_HOVER_LINES.size()]
	await _reveal_narration("You turn away from the Shadows. They do not chase you.")
	_finish_encounter()

# A round = Pip's choice → your spell → enemy turn.
func _start_round() -> void:
	if state == State.ENDING or state == State.LOSE or state == State.CHOICE:
		return
	if _alive_count() == 0:
		return
	_pip_turn()

# Player picks Pip's action. Resolves in _on_cheer_pressed / _on_heal_pressed.
func _pip_turn() -> void:
	state = State.PIP_TURN
	_set_active_actor("pip")
	if not boss_flash_active:
		pip_text.text = "Tell me, bless your strike, or lift you up?"
	spell_buttons.visible = false
	pip_choice_buttons.visible = true
	pip_choice_index = 0
	_refresh_pip_cursor()

func _on_cheer_pressed() -> void:
	if state != State.PIP_TURN:
		return
	action_cursor.visible = false
	_highlight_pair([cheer_btn, heal_btn], -1)
	Audio.play_sfx("power_up")
	damage_buff = PIP_BUFF
	pip_action_label.text = "Pip: Cheer!  next spell +%d" % PIP_BUFF
	if not boss_flash_active:
		pip_text.text = "I bless your strike!"
	_flash_cheer()
	_finish_pip_turn()

func _flash_cheer() -> void:
	var tex: Texture2D = load("res://assets/sprites/cheer.png")
	if tex == null:
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(480, 270)
	spr.z_index = 100
	var tex_size: Vector2 = tex.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		var s: float = min(600.0 / tex_size.x, 360.0 / tex_size.y)
		spr.scale = Vector2(s, s)
	spr.modulate = Color(1, 1, 1, 0)
	add_child(spr)
	var tw := create_tween()
	tw.tween_property(spr, "modulate:a", 1.0, 0.08)
	tw.tween_interval(0.18)
	tw.tween_property(spr, "modulate:a", 0.0, 0.55)
	tw.tween_callback(spr.queue_free)

func _on_heal_pressed() -> void:
	if state != State.PIP_TURN:
		return
	action_cursor.visible = false
	_highlight_pair([cheer_btn, heal_btn], -1)
	Audio.play_sfx("power_up")
	var heal: int = min(PIP_HEAL, GameState.PLAYER_MAX_HP - GameState.player_hp)
	GameState.player_hp += heal
	pip_action_label.text = "Pip: Heal!  +%d HP" % heal
	if not boss_flash_active:
		pip_text.text = "Stay bright, hero!"
	_show_damage_number(profile.position, heal, Color(0.7, 1, 0.7))
	_update_hud()
	_play_heal_animation()
	_finish_pip_turn()

func _play_heal_animation() -> void:
	var t1: Texture2D = load("res://assets/sprites/heal.png")
	var t2: Texture2D = load("res://assets/sprites/heal2.png")
	if t1 == null and t2 == null:
		return
	var spr := Sprite2D.new()
	var start_pos: Vector2 = pip.position
	var end_pos: Vector2 = profile.position
	spr.position = start_pos
	spr.z_index = 100
	var ref: Texture2D = t1 if t1 != null else t2
	var ref_size: Vector2 = ref.get_size()
	if ref_size.x > 0 and ref_size.y > 0:
		var s: float = min(80.0 / ref_size.x, 80.0 / ref_size.y)
		spr.scale = Vector2(s, s)
	spr.texture = ref
	$UI.add_child(spr)

	var travel_time := 1
	var arc_height: float = 90.0
	var control: Vector2 = (start_pos + end_pos) * 0.5 + Vector2(0, -arc_height)

	var flicker := create_tween()
	flicker.set_loops()
	var frame_time := 0.08
	if t1 != null:
		flicker.tween_callback(func(): spr.texture = t1)
		flicker.tween_interval(frame_time)
	if t2 != null:
		flicker.tween_callback(func(): spr.texture = t2)
		flicker.tween_interval(frame_time)

	var arc := create_tween()
	arc.tween_method(
		func(t: float) -> void:
			var a: Vector2 = start_pos.lerp(control, t)
			var b: Vector2 = control.lerp(end_pos, t)
			spr.position = a.lerp(b, t),
		0.0, 1.0, travel_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	arc.tween_property(spr, "modulate:a", 0.0, 0.2)
	arc.tween_callback(flicker.kill)
	arc.tween_callback(spr.queue_free)

func _finish_pip_turn() -> void:
	pip_choice_buttons.visible = false
	spell_buttons.visible = true
	state = State.PLAYER_INPUT
	_set_active_actor("player")
	if not boss_flash_active:
		pip_text.text = PIP_HINTS.get(expected_spell, "")
	# Bias cursor toward the spell Pip is hinting (if any).
	var hinted: int = SPELL_NAMES.find(expected_spell)
	spell_index = hinted if hinted >= 0 else 0
	_refresh_spell_cursor()

func _enemy_turn() -> void:
	state = State.ENEMY_TURN
	_set_active_actor("enemy")
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
	_flash_damage(profile.position)
	_show_damage_number(profile.position, total, Color(1, 0.5, 0.5))
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
	_start_round()

func _set_active_actor(who: String) -> void:
	current_actor = who
	# Tint profile, Pip and the actor turn label so it's clear whose turn it is.
	match who:
		"player":
			profile.modulate = Color(1, 1, 1)
			actor_turn_label.text = "Your turn"
			actor_turn_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1))
			if not boss_flash_active:
				pip.modulate = MOOD_TINTS[mood] * Color(0.7, 0.7, 0.7)
		"pip":
			profile.modulate = Color(0.7, 0.7, 0.8)
			actor_turn_label.text = "Pip's turn"
			actor_turn_label.add_theme_color_override("font_color", Color(1, 1, 0.6))
			pip.modulate = Color(1, 1, 0.6)
		"enemy":
			profile.modulate = Color(1, 0.55, 0.55)
			actor_turn_label.text = "Enemy turn"
			actor_turn_label.add_theme_color_override("font_color", Color(1, 0.6, 0.6))
			if not boss_flash_active:
				pip.modulate = MOOD_TINTS[mood] * Color(0.6, 0.6, 0.6)

func _default_enemy_anim() -> String:
	return "sad" if friends_lost and not is_boss_fight else "idle"

func _kill_enemy(idx: int) -> void:
	var e = enemies[idx]
	e.alive = false
	e.sprite.play("dead")
	e.sprite.modulate = Color(0.85, 0.85, 0.85)
	if e.hp_bar_root:
		e.hp_bar_root.visible = false
	Audio.play_sfx("explosion")
	Audio.play_sfx("power_up")
	GameState.hope += 1
	_set_mood(Mood.HAPPY)
	_update_hud()
	if not is_boss_fight:
		friends_lost = true
		var sad_anim: String = _default_enemy_anim()
		for other in enemies:
			if other.alive and other.sprite.sprite_frames != null and other.sprite.sprite_frames.has_animation(sad_anim):
				other.sprite.play(sad_anim)
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
			await _offer_boss_letter_choice()
		else:
			_offer_choice()

func _reveal_narration(line: String) -> void:
	narration.text = ""
	if line.length() > 0:
		Audio.start_speak()
	for i in line.length():
		narration.text = line.substr(0, i + 1)
		await get_tree().create_timer(REVEAL_CHAR_DELAY).timeout
	Audio.stop_speak()
	await get_tree().create_timer(0.5).timeout

func _offer_choice() -> void:
	state = State.CHOICE
	spell_buttons.visible = false
	choice_buttons.visible = true
	pip_text.text = "...will you look at what's left of them?"
	post_choice_index = 0
	_refresh_post_choice_cursor()

func _on_observe_pressed() -> void:
	if state != State.CHOICE:
		return
	state = State.RESOLVING
	action_cursor.visible = false
	_highlight_pair([observe_btn, walk_btn], -1)
	Audio.play_sfx("tap")
	GameState.compassion += 1
	choice_buttons.visible = false
	pip_text.text = ""
	if boss_letter_choice:
		boss_letter_choice = false
		narration_bg.visible = false
		narration.text = ""
		await _show_letter_scroll(BOSS_LETTER)
		_start_ending(true)
		return
	# Humanize the fallen: warm them out of the gray "dead" tint.
	var warm := Color(1.0, 0.95, 0.85)
	for e in enemies:
		if not e.alive:
			var tw := create_tween()
			tw.tween_property(e.sprite, "modulate", warm, 0.5)
	var enc: int = GameState.encounter_index
	var line: String = OBSERVE_LINES[enc] if enc < OBSERVE_LINES.size() else OBSERVE_LINES[OBSERVE_LINES.size() - 1]
	narration_bg.visible = true
	await _reveal_narration(line)
	# Pip cuts in to dismiss what you saw.
	pip.modulate = Color(1, 0.7, 0.7)
	pip_text.text = PIP_OBSERVE_REBUKES[randi() % PIP_OBSERVE_REBUKES.size()]
	narration_continue.visible = true
	narration_continue.grab_focus()
	await narration_continue.pressed
	Audio.play_sfx("tap")
	narration_continue.visible = false
	narration_bg.visible = false
	narration.text = ""
	pip.modulate = MOOD_TINTS[mood]
	_resolve_choice()

func _on_walk_pressed() -> void:
	if state != State.CHOICE:
		return
	action_cursor.visible = false
	_highlight_pair([observe_btn, walk_btn], -1)
	Audio.play_sfx("tap")
	if boss_letter_choice:
		boss_letter_choice = false
		choice_buttons.visible = false
		narration_bg.visible = false
		narration.text = ""
		_start_ending(true)
		return
	_resolve_choice()

func _offer_boss_letter_choice() -> void:
	boss_flash_active = false
	state = State.RESOLVING
	spell_buttons.visible = false
	pip_choice_buttons.visible = false
	action_buttons.visible = false
	run_button.visible = false
	reticle.visible = false
	narration_bg.visible = true
	await _reveal_narration("It falls. A folded letter rests in the dust where the Shadow stood.")
	pip.modulate = Color(1, 0.7, 0.7)
	pip.scale = Vector2(0.5, 0.5) * 1.25
	pip_text.text = "Don't read it, hero! It's full of lies!"
	state = State.CHOICE
	boss_letter_choice = true
	choice_buttons.visible = true
	post_choice_index = 0
	_refresh_post_choice_cursor()

func _show_letter_scroll(text: String) -> void:
	var w: float = 640.0
	var h: float = 320.0
	var origin := Vector2(480.0 - w / 2.0, 270.0 - h / 2.0)
	var border := ColorRect.new()
	border.color = Color(0.42, 0.26, 0.14, 0.0)
	border.size = Vector2(w + 12, h + 12)
	border.position = origin - Vector2(6, 6)
	border.z_index = 199
	add_child(border)
	var panel := ColorRect.new()
	panel.color = Color(0.96, 0.9, 0.74, 0.0)
	panel.size = Vector2(w, h)
	panel.position = origin
	panel.z_index = 200
	add_child(panel)
	var lbl := Label.new()
	lbl.text = ""
	lbl.position = origin + Vector2(32, 32)
	lbl.size = Vector2(w - 64, h - 110)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.18, 0.1, 0.05))
	lbl.modulate = Color(1, 1, 1, 0)
	lbl.z_index = 201
	add_child(lbl)
	# Reposition Continue to the bottom-right of the scroll so it doesn't cover the text.
	var btn_size := Vector2(140, 35)
	var saved_btn_pos := narration_continue.position
	narration_continue.position = origin + Vector2(w - btn_size.x - 24, h - btn_size.y - 20)
	narration_continue.z_index = 202
	action_cursor.visible = false
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(border, "color:a", 0.92, 0.4)
	tw.tween_property(panel, "color:a", 0.96, 0.4)
	tw.tween_property(lbl, "modulate:a", 1.0, 0.4)
	await tw.finished
	Audio.start_speak()
	for i in text.length():
		lbl.text = text.substr(0, i + 1)
		await get_tree().create_timer(REVEAL_CHAR_DELAY).timeout
	Audio.stop_speak()
	await get_tree().create_timer(0.4).timeout
	narration_continue.visible = true
	narration_continue.grab_focus()
	# Triangle indicator appears alongside Continue, anchored to its left edge.
	_show_cursor_at(narration_continue)
	action_cursor.z_index = 202
	await narration_continue.pressed
	Audio.play_sfx("tap")
	narration_continue.visible = false
	action_cursor.visible = false
	action_cursor.z_index = 0
	narration_continue.position = saved_btn_pos
	narration_continue.z_index = 0
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(border, "modulate:a", 0.0, 0.35)
	tw2.tween_property(panel, "modulate:a", 0.0, 0.35)
	tw2.tween_property(lbl, "modulate:a", 0.0, 0.35)
	await tw2.finished
	border.queue_free()
	panel.queue_free()
	lbl.queue_free()

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
	# Re-apply active-actor tinting so the mood change doesn't override it.
	_set_active_actor(current_actor)
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

func _play_spell_effect(spell_name: String, at: Vector2) -> void:
	var anim: String = "pow" if spell_name == "Purify" else "slash"
	spell_effect.position = at
	spell_effect.modulate = Color(1, 1, 1, 1)
	spell_effect.visible = true
	spell_effect.frame = 0
	spell_effect.play(anim)
	var tween := create_tween()
	tween.tween_interval(0.32)
	tween.tween_property(spell_effect, "modulate:a", 0.0, 0.18)
	tween.tween_callback(func():
		spell_effect.visible = false
		spell_effect.stop())

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
	var path: String
	if beat:
		# hope == 1 means only the boss fell (boss kill counts for +1 hope).
		path = "res://scenes/ending_boss_only.tscn" if GameState.hope <= 1 else "res://scenes/ending_massacre.tscn"
	else:
		path = "res://scenes/ending_pacifist.tscn" if GameState.hope == 0 else "res://scenes/ending_walkaway_regret.tscn"
	get_tree().change_scene_to_file(path)

func _on_shine_pressed() -> void: _on_spell_pressed("Shine")
func _on_purify_pressed() -> void: _on_spell_pressed("Purify")
