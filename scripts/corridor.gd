extends Node2D

@export var walk_speed: float = 80.0
@export var distance_between_encounters: float = 600.0

@onready var player: AnimatedSprite2D = $Player
@onready var pip: AnimatedSprite2D = $Pip
@onready var sky: Sprite2D = $Parallax/Sky
@onready var grass: Sprite2D = $Parallax/Grass
@onready var trees: Node2D = $Parallax/Trees

var distance_walked: float = 0.0
var encounter_pending: bool = true

func _ready() -> void:
	player.play("walk")
	pip.play("sparkle")

func _process(delta: float) -> void:
	if not encounter_pending:
		return

	# Player stays centered; world scrolls left.
	var dx := walk_speed * delta
	distance_walked += dx
	_scroll_world(dx)

	if distance_walked >= distance_between_encounters:
		_trigger_encounter()

func _scroll_world(dx: float) -> void:
	# Sky barely moves (parallax), grass moves at full speed, trees move at full speed.
	sky.position.x -= dx * 0.1
	grass.position.x -= dx
	for child in trees.get_children():
		child.position.x -= dx

func _trigger_encounter() -> void:
	encounter_pending = false
	# Hand off to combat scene; GameState carries which encounter we're on.
	get_tree().change_scene_to_file("res://scenes/combat.tscn")
