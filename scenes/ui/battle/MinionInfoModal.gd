extends MarginContainer

onready var _popup = $Center/Popup
onready var minion_name = $Center/Popup/Margin/VBox/MinionName
onready var movement = $Center/Popup/Margin/VBox/Stats/MoveLabel
onready var power = $Center/Popup/Margin/VBox/Stats/PowerLabel
onready var health = $Center/Popup/Margin/VBox/Stats/HealthLabel

func show_minion(minion):
    minion_name.text = minion.species_name
    movement.text = String(minion.movement)
    power.text = String(minion.power)
    health.text = String(minion.health)
    visible = true
    _popup.popup()

func _on_Popup_popup_hide():
    visible = false
