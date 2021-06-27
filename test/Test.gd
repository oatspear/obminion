extends Node2D

const DATA = preload("res://data/battle/ai_test_1.tres")

onready var battle = $VersusAI

func _ready():
    battle.start_battle(DATA)
