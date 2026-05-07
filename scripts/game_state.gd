extends Node

# Singleton autoload — persists across scene changes.

var encounter_index: int = 0
var hope: int = 0
# Tracks the player's choices after each encounter. Read by the boss fight
# to branch dialog and ending: high = the cries reached you, low = you didn't listen.
var compassion: int = 0
var ran_from_boss: bool = false
var beat_boss: bool = false

const PLAYER_MAX_HP := 20
var player_hp: int = PLAYER_MAX_HP

func reset_run() -> void:
	encounter_index = 0
	hope = 0
	compassion = 0
	player_hp = PLAYER_MAX_HP
	ran_from_boss = false
	beat_boss = false

# Encounter sizes per the design doc: 1, 2, 2, 4, then boss.
const ENCOUNTER_SIZES := [1, 2, 2, 4]
const BOSS_INDEX := 4

func enemies_for_current_encounter() -> int:
	if encounter_index < ENCOUNTER_SIZES.size():
		return ENCOUNTER_SIZES[encounter_index]
	if encounter_index == BOSS_INDEX:
		return 1
	return 0

func is_boss_next() -> bool:
	return encounter_index == BOSS_INDEX

func is_run_finished() -> bool:
	return encounter_index > BOSS_INDEX
