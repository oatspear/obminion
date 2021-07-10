extends "res://scenes/uiboard/Tile.gd"

################################################################################
# Constants
################################################################################

const TEXTURE_NORMAL = preload("res://assets/board/tile-normal.png")
const TEXTURE_RED = preload("res://assets/board/tile-normal-red.png")
const TEXTURE_BLUE = preload("res://assets/board/tile-normal-blue.png")
const TEXTURE_HIGHLIGHT = preload("res://assets/board/tile-normal-highlight.png")

################################################################################
# Overloads
################################################################################

func highlight_tile(pi: int):
    if minion == null:
        texture = TEXTURE_HIGHLIGHT
    elif minion.player_owner == pi:
        texture = TEXTURE_BLUE
    else:
        texture = TEXTURE_RED

func highlight_friend():
    if minion == null:
        texture = TEXTURE_HIGHLIGHT
    else:
        texture = TEXTURE_BLUE

func highlight_enemy():
    if minion == null:
        texture = TEXTURE_HIGHLIGHT
    else:
        texture = TEXTURE_RED

func enable_selection(data=null):
    ui_enabled = true
    ui_data = data
    highlight_friend()

func enable_inspection(data=null):
    ui_enabled = true
    ui_data = data
    texture = TEXTURE_HIGHLIGHT

func enable_targeting(data=null):
    ui_enabled = true
    ui_data = data
    highlight_enemy()

func disable_tile():
    ui_enabled = false
    ui_data = null
    texture = TEXTURE_NORMAL
