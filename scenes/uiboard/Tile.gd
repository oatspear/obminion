extends TextureRect

################################################################################
# Constants
################################################################################

const NORMAL_PACK: Resource = preload("res://data/ui/tile-normal.tres")
const RESOURCE_PACK: Resource = preload("res://data/ui/tile-resource.tres")
const SPAWN_PACK: Resource = preload("res://data/ui/tile-spawn.tres")
const BASE_PACK: Resource = preload("res://data/ui/tile-base.tres")

################################################################################
# Signals
################################################################################

signal tile_selected(i)

################################################################################
# Internal State
################################################################################

var minion: Node2D = null
var tile_index: int = 0
# export (Array, int)
var adjacent: Array = []
export (Global.TileType) var tile_type = Global.TileType.NORMAL
export (int) var player_owner: int = -1
export (bool) var ui_enabled: bool = false

var ui_data = null
var _texture_pack: Resource = null


################################################################################
# Interface
################################################################################

func global_x():
    return rect_global_position.x + rect_size.x / 2

func global_y():
    return rect_global_position.y + rect_size.y / 2

func is_empty():
    return minion == null

func set_normal():
    tile_type = Global.TileType.NORMAL
    _texture_pack = NORMAL_PACK
    texture = _texture_pack.texture_default

func set_spawn(pi: int = -1):
    tile_type = Global.TileType.SPAWN
    player_owner = pi
    _texture_pack = SPAWN_PACK
    texture = _texture_pack.texture_default

func set_base(pi: int = -1):
    tile_type = Global.TileType.BASE
    player_owner = pi
    _texture_pack = BASE_PACK
    texture = _texture_pack.texture_default

func is_normal_tile():
    return tile_type == Global.TileType.NORMAL

func is_spawn_tile():
    return tile_type == Global.TileType.SPAWN

func is_base_tile():
    return tile_type == Global.TileType.BASE

func highlight_friend():
    if minion == null:
        texture = _texture_pack.texture_highlight
    else:
        texture = _texture_pack.texture_friend

func highlight_enemy():
    if minion == null:
        texture = _texture_pack.texture_highlight
    else:
        texture = _texture_pack.texture_enemy

func enable_selection(data=null):
    ui_enabled = true
    ui_data = data
    highlight_friend()

func enable_inspection(data=null):
    ui_enabled = true
    ui_data = data
    texture = _texture_pack.texture_highlight

func enable_targeting(data=null):
    ui_enabled = true
    ui_data = data
    texture = _texture_pack.texture_enemy

func disable_tile():
    ui_enabled = false
    ui_data = null
    texture = _texture_pack.texture_default


################################################################################
# Event Callbacks
################################################################################

func _ready():
    match tile_type:
        Global.TileType.NORMAL:
            _texture_pack = NORMAL_PACK
        Global.TileType.BASE:
            _texture_pack = BASE_PACK
        Global.TileType.SPAWN:
            _texture_pack = SPAWN_PACK
        _:
            assert(false)
    texture = _texture_pack.texture_default

func _on_Tile_gui_input(event):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT and event.pressed:
            if ui_enabled:
                print("Clicked tile %d; contains %s" % [tile_index, minion])
                emit_signal("tile_selected", tile_index)
