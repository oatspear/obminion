extends Node2D

################################################################################
# Signals
################################################################################

signal tile_selected(i)

################################################################################
# Internal State
################################################################################

onready var tiles = get_children()

################################################################################
# Interface
################################################################################

func enqueue_minion(minion):
    var n = len(tiles)
    var i = 0
    while i < n:
        if tiles[i].minion == null:
            break
        i += 1
    if i < n:
        tiles[i].minion = minion
        minion.global_position.x = tiles[i].global_position.x
        minion.global_position.y = tiles[i].global_position.y
        return null
    else:
        var first = tiles[0].minion
        i = 1
        while i < n:
            tiles[i-1].minion = tiles[i].minion
            tiles[i-1].minion.global_position.x = tiles[i-1].global_position.x
            tiles[i-1].minion.global_position.y = tiles[i-1].global_position.y
            i += 1
        tiles[i-1].minion = minion
        minion.global_position.x = tiles[i-1].global_position.x
        minion.global_position.y = tiles[i-1].global_position.y
        return first

func place_minion(minion, i: int):
    var tile = tiles[i]
    assert(tile.minion == null, "tile is not empty")
    tile.minion = minion
    minion.global_position.x = tile.global_position.x
    minion.global_position.y = tile.global_position.y


func find_minion(minion: Node2D):
    for tile in tiles:
        if tile.minion == minion:
            return tile
    return null


func enable_minion_tiles(data=null):
    for tile in tiles:
        if tile.minion != null and tile.minion.can_act():
            tile.enable_selection(data)

func disable_all_tiles():
    for tile in tiles:
        tile.disable_tile()


################################################################################
# Event Callbacks
################################################################################

func _ready():
    for i in range(0, len(tiles)):
        var tile = tiles[i]
        tile.connect("tile_selected", self, "_on_tile_selected", [i])
        tile.tile_index = i


func _on_tile_selected(i: int):
    emit_signal("tile_selected", i)

