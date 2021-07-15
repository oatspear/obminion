extends CenterContainer

################################################################################
# Signals
################################################################################

signal player_graveyard_tile_selected(tile_index)
signal enemy_graveyard_tile_selected(tile_index)
signal player_bench_tile_selected(tile_index)
signal enemy_bench_tile_selected(tile_index)
signal battlefield_tile_selected(tile_index)

################################################################################
# Internal State
################################################################################

onready var enemy_bench = $HBox/Center/VBox/EnemyBench
onready var enemy_graveyard = $HBox/Right/EnemyGraveyard
onready var player_bench = $HBox/Center/VBox/PlayerBench
onready var player_graveyard = $HBox/Right/PlayerGraveyard
onready var battlefield = $HBox/Center/VBox/Battlefield

################################################################################
# Event Callbacks
################################################################################

func _on_Battlefield_battlefield_tile_selected(i):
    emit_signal("battlefield_tile_selected", i)

func _on_EnemyBench_bench_tile_selected(i):
    emit_signal("enemy_bench_tile_selected", i)

func _on_PlayerBench_bench_tile_selected(i):
    emit_signal("player_bench_tile_selected", i)

func _on_EnemyGraveyard_graveyard_tile_selected(i):
    emit_signal("enemy_graveyard_tile_selected", i)

func _on_PlayerGraveyard_graveyard_tile_selected(i):
    emit_signal("player_graveyard_tile_selected", i)
