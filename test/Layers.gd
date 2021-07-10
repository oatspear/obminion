extends Node2D

onready var guy = $CanvasLayer3/AnimatedSprite
onready var board = $CanvasLayer2/CenterContainer/PanelContainer/TextureRect

func _ready():
    var x = board.rect_global_position.x + board.rect_size.x / 2
    var y = board.rect_global_position.y + board.rect_size.y / 2
    guy.global_position.x = x
    guy.global_position.y = y
    guy.animation = "run"
    guy.play()


var desloc = 0.5
var fwd = true

func _xprocess(delta):
    desloc += delta
    if desloc > 1.0:
        desloc = 0.0
        fwd = not fwd
    var s = -1 if not fwd else 1
    guy.position.x += 120 * delta * s


func _on_TextureRect_gui_input(event):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT:
            if event.pressed:
                print("Clicked Control")


func _on_Area2D_input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT:
            if event.pressed:
                print("Clicked Sprite")
