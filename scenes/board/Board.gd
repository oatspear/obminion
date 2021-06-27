extends Node2D

################################################################################
# Signals
################################################################################

signal player_grave_tile_selected(tile_index)
signal enemy_grave_tile_selected(tile_index)
signal player_bench_tile_selected(tile_index)
signal enemy_bench_tile_selected(tile_index)
signal field_tile_selected(tile_index)

################################################################################
# Internal State
################################################################################

onready var enemy_player = $Top
onready var this_player = $Bottom
onready var battlefield = $Battlefield

################################################################################
# Event Callbacks
################################################################################

func _on_Top_bench_tile_selected(i):
    emit_signal("enemy_bench_tile_selected", i)

func _on_Top_grave_tile_selected(i):
    emit_signal("enemy_grave_tile_selected", i)

func _on_Bottom_bench_tile_selected(i):
    emit_signal("player_bench_tile_selected", i)

func _on_Bottom_grave_tile_selected(i):
    emit_signal("player_grave_tile_selected", i)

func _on_Battlefield_tile_selected(i):
    emit_signal("field_tile_selected", i)
