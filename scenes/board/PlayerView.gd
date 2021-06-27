extends Node2D

################################################################################
# Signals
################################################################################

signal grave_tile_selected(i)
signal bench_tile_selected(i)

################################################################################
# Internal State
################################################################################

onready var bench = $Bench
onready var graveyard = $Graveyard


################################################################################
# Event Callbacks
################################################################################

func _on_Bench_tile_selected(i: int):
    emit_signal("bench_tile_selected", i)

func _on_Graveyard_tile_selected(i: int):
    emit_signal("grave_tile_selected", i)
