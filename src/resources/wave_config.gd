class_name WaveConfig
extends Resource

@export var wave_index: int = 0
@export var enemy_spawns: Array[Dictionary] = []  # [{enemy_scene, count, interval}]
@export var soft_reward: int = 50
@export var is_boss_wave: bool = false
@export var boss_scene: String = ""
