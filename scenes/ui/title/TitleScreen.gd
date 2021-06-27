extends PanelContainer

signal start_game()

onready var tween = $Tween
onready var title_label = $Panel/CenterContainer/VBoxContainer/TitleLabel
onready var click_label = $Panel/CenterContainer/VBoxContainer/PressButtonLabel
onready var l_particles = $ParticlesLeft
onready var r_particles = $ParticlesRight

func _ready():
    var y = title_label.rect_global_position.y
    y += title_label.rect_size.y / 2
    var x1 = title_label.rect_global_position.x
    var x2 = x1 + title_label.rect_size.x
    l_particles.global_position.x = x1
    l_particles.global_position.y = y
    r_particles.global_position.x = x2
    r_particles.global_position.y = y
    tween.repeat = true
    tween.interpolate_property(click_label, "modulate",
        Color(1, 1, 1, 1), Color(1, 1, 1, 0.2),
        1, Tween.TRANS_CIRC, Tween.EASE_IN_OUT)
    tween.start()


func _on_TitleScreen_gui_input(event):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT and event.pressed:
            emit_signal("start_game")
        else:
            print("Other mouse button [%d, %s]" % [event.button, event.pressed])
    if event is InputEventScreenTouch:
        if event.index == 0 and event.pressed:
            emit_signal("start_game")
        else:
            print("Other touch event [%d, %s]" % [event.index, event.pressed])
