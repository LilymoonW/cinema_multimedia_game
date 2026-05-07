extends Node

# Singleton autoload — global music and SFX.

const SFX := {
	"tap":      "res://assets/sounds/tap.wav",
	"jump":     "res://assets/sounds/jump.wav",
	"hurt":     "res://assets/sounds/hurt.wav",
	"enchant":  "res://assets/sounds/enchant.wav",
	"power_up": "res://assets/sounds/power_up.wav",
	"explosion":"res://assets/sounds/explosion.wav",
}

const MUSIC_PATH := "res://assets/music/time_for_adventure.mp3"
const WALK_PATH := "res://assets/sounds/walk.mp3"
const SPEAK_PATH := "res://assets/sounds/speak.mp3"

var _music: AudioStreamPlayer
var _walk: AudioStreamPlayer
var _speak: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}
const POOL_SIZE := 6

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = "Master"
	_music.volume_db = -8.0
	var stream: AudioStream = load(MUSIC_PATH)
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_music.stream = stream
	add_child(_music)
	_walk = AudioStreamPlayer.new()
	_walk.bus = "Master"
	_walk.volume_db = -6.0
	var walk_stream: AudioStream = load(WALK_PATH)
	if walk_stream is AudioStreamMP3:
		(walk_stream as AudioStreamMP3).loop = true
	_walk.stream = walk_stream
	add_child(_walk)
	_speak = AudioStreamPlayer.new()
	_speak.bus = "Master"
	_speak.volume_db = -6.0
	var speak_stream: AudioStream = load(SPEAK_PATH)
	if speak_stream is AudioStreamMP3:
		(speak_stream as AudioStreamMP3).loop = true
	_speak.stream = speak_stream
	add_child(_speak)
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)
	for key in SFX.keys():
		_sfx_cache[key] = load(SFX[key])

func play_music() -> void:
	if not _music.playing:
		_music.play()

func stop_music() -> void:
	_music.stop()

func play_walk() -> void:
	if not _walk.playing:
		_walk.play()

func stop_walk() -> void:
	if _walk.playing:
		_walk.stop()

func start_speak() -> void:
	if not _speak.playing:
		_speak.play()

func stop_speak() -> void:
	if _speak.playing:
		_speak.stop()

func play_sfx(name: String, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _sfx_cache.get(name)
	if stream == null:
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			return
	# All busy — reuse the first slot.
	var p0: AudioStreamPlayer = _sfx_pool[0]
	p0.stream = stream
	p0.volume_db = volume_db
	p0.play()
