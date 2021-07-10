extends Control



func _on_Control_gui_input(event):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT and event.pressed:
            print("Clicked hidden Control")
