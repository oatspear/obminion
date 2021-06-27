extends Sprite

################################################################################
# Constants
################################################################################

const HIGHLIGHT_COLOR_FRIEND: Color = Color(0, 1, 0)
const HIGHLIGHT_COLOR_EMPTY: Color = Color(1, 1, 0)
const HIGHLIGHT_COLOR_BATTLE: Color = Color(1, 0, 0)
const NORMAL_COLOR: Color = Color(1, 1, 1)

################################################################################
# Signals
################################################################################

signal tile_selected()

################################################################################
# Internal State
################################################################################

var minion: Node2D = null
var tile_index: int = 0
export (Array, int) var adjacent = []
export (Global.TileType) var tile_type = Global.TileType.NORMAL
export (int) var player_owner: int = -1
export (bool) var ui_enabled: bool = false

var ui_data = null


################################################################################
# Interface
################################################################################

func is_empty():
    return minion == null

func set_normal():
    tile_type = Global.TileType.NORMAL

func set_spawn(pi: int = -1):
    tile_type = Global.TileType.SPAWN
    player_owner = pi

func set_base(pi: int = -1):
    tile_type = Global.TileType.BASE
    player_owner = pi

func is_normal_tile():
    return tile_type == Global.TileType.NORMAL

func is_spawn_tile():
    return tile_type == Global.TileType.SPAWN

func is_base_tile():
    return tile_type == Global.TileType.BASE

func highlight_friend():
    if minion == null:
        modulate = HIGHLIGHT_COLOR_EMPTY
    else:
        modulate = HIGHLIGHT_COLOR_FRIEND

func highlight_enemy():
    if minion == null:
        modulate = HIGHLIGHT_COLOR_EMPTY
    else:
        modulate = HIGHLIGHT_COLOR_BATTLE

func enable_selection(data=null):
    ui_enabled = true
    ui_data = data
    if minion == null:
        modulate = HIGHLIGHT_COLOR_EMPTY
    else:
        modulate = HIGHLIGHT_COLOR_FRIEND

func enable_inspection(data=null):
    ui_enabled = true
    ui_data = data
    modulate = HIGHLIGHT_COLOR_EMPTY

func enable_targeting(data=null):
    ui_enabled = true
    ui_data = data
    modulate = HIGHLIGHT_COLOR_BATTLE

func disable_tile():
    ui_enabled = false
    ui_data = null
    modulate = NORMAL_COLOR


################################################################################
# Event Callbacks
################################################################################

func _on_Area2D_input_event(_viewport, event, _shape_idx):
    if (event is InputEventMouseButton and event.button_index == BUTTON_LEFT
            and event.pressed and ui_enabled):
        print("Clicked %s; contains %s" % [name, minion])
        emit_signal("tile_selected")
