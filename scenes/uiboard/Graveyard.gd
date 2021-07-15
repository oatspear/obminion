extends MarginContainer

################################################################################
# Signals
################################################################################

signal graveyard_tile_selected(i)

################################################################################
# Internal State
################################################################################

onready var tiles = $Center/Frame/Tiles.get_children()

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
        tiles[i].place_minion(minion)
        return null
    else:
        var first = tiles[0].minion
        i = 1
        while i < n:
            tiles[i-1].place_minion(tiles[i].minion)
            i += 1
        tiles[i-1].place_minion(minion)
        return first

func place_minion(minion, i: int):
    return tiles[i].place_minion(minion)


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
        tile.tile_index = i
        tile.connect("tile_selected", self, "_on_tile_selected")


func _on_tile_selected(i: int):
    emit_signal("graveyard_tile_selected", i)
