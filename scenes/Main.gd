extends Node

func _on_TitleScreen_start_game():
    $TitleScreen.queue_free()
    print("Game started!")
