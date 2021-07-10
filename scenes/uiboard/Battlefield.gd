extends CenterContainer


func _tile_input(i: int, event):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT and event.pressed:
            print("Clicked Tile %d" % i)


func _on_Tile1_gui_input(event):
    _tile_input(0, event)


func _on_Tile2_gui_input(event):
    _tile_input(1, event)


func _on_Tile3_gui_input(event):
    _tile_input(2, event)


func _on_Tile4_gui_input(event):
    _tile_input(3, event)
