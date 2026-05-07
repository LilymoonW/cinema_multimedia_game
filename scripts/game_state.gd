extends Node

# Singleton autoload — persists across scene changes.

var encounter_index: int = 0
var hope: int = 0

# Encounter sizes per the design doc: 1, 2, 2, 4, then boss.
const ENCOUNTER_SIZES := [1, 2, 2, 4]

func enemies_for_current_encounter() -> int:
	if encounter_index < ENCOUNTER_SIZES.size():
		return ENCOUNTER_SIZES[encounter_index]
	return 0

func is_boss_next() -> bool:
	return encounter_index >= ENCOUNTER_SIZES.size()
