extends VBoxContainer

const TEXTURE_HEART_FULL: Texture = preload("res://assets/icons/player_heart_full.png")
const TEXTURE_HEART_EMPTY: Texture = preload("res://assets/icons/player_heart_spent.png")

const TEXTURE_RESOURCE_FULL: Texture = preload("res://assets/icons/player_resource_full.png")

const TEXTURE_SUPPLY_FREE: Texture = preload("res://assets/icons/player_supplies_free.png")
const TEXTURE_SUPPLY_USED: Texture = preload("res://assets/icons/player_supplies_used.png")
const TEXTURE_SUPPLY_OVER: Texture = preload("res://assets/icons/player_supplies_over.png")

onready var this_player_hearts: Array = [
    $PlayerPanels/Left/HBox/VBox/Indicators/HeartContainer/Heart1,
    $PlayerPanels/Left/HBox/VBox/Indicators/HeartContainer/Heart2,
    $PlayerPanels/Left/HBox/VBox/Indicators/HeartContainer/Heart3
]

onready var this_player_resources: Array = [
    $PlayerPanels/Left/HBox/VBox/Indicators/ResourceContainer/Resource1,
    $PlayerPanels/Left/HBox/VBox/Indicators/ResourceContainer/Resource2
]

onready var this_player_supplies: Array = [
    $PlayerPanels/Left/HBox/VBox/Indicators/SupplyContainer1/Supply1,
    $PlayerPanels/Left/HBox/VBox/Indicators/SupplyContainer1/Supply2,
    $PlayerPanels/Left/HBox/VBox/Indicators/SupplyContainer1/Supply3,
    $PlayerPanels/Left/HBox/VBox/Indicators/SupplyContainer1/Supply4,
    $PlayerPanels/Left/HBox/VBox/Indicators/SupplyContainer2/Supply1,
    $PlayerPanels/Left/HBox/VBox/Indicators/SupplyContainer2/Supply2,
    $PlayerPanels/Left/HBox/VBox/Indicators/SupplyContainer2/Supply3,
    $PlayerPanels/Left/HBox/VBox/Indicators/SupplyContainer2/Supply4
]

onready var enemy_player_hearts: Array = [
    $PlayerPanels/Right/HBox/VBox/Indicators/HeartContainer/Heart1,
    $PlayerPanels/Right/HBox/VBox/Indicators/HeartContainer/Heart2,
    $PlayerPanels/Right/HBox/VBox/Indicators/HeartContainer/Heart3
]

onready var enemy_player_resources: Array = [
    $PlayerPanels/Right/HBox/VBox/Indicators/ResourceContainer/Resource1,
    $PlayerPanels/Right/HBox/VBox/Indicators/ResourceContainer/Resource2
]

onready var enemy_player_supplies: Array = [
    $PlayerPanels/Right/HBox/VBox/Indicators/SupplyContainer1/Supply1,
    $PlayerPanels/Right/HBox/VBox/Indicators/SupplyContainer1/Supply2,
    $PlayerPanels/Right/HBox/VBox/Indicators/SupplyContainer1/Supply3,
    $PlayerPanels/Right/HBox/VBox/Indicators/SupplyContainer1/Supply4,
    $PlayerPanels/Right/HBox/VBox/Indicators/SupplyContainer2/Supply1,
    $PlayerPanels/Right/HBox/VBox/Indicators/SupplyContainer2/Supply2,
    $PlayerPanels/Right/HBox/VBox/Indicators/SupplyContainer2/Supply3,
    $PlayerPanels/Right/HBox/VBox/Indicators/SupplyContainer2/Supply4
]


func update_this_player_indicators(nh: int, nr: int, nsa: int, nsu: int):
    _update_hearts(this_player_hearts, nh)
    _update_resources(this_player_resources, nr)
    _update_supplies(this_player_supplies, nsa, nsu)

func update_enemy_player_indicators(nh: int, nr: int, nsa: int, nsu: int):
    _update_hearts(enemy_player_hearts, nh)
    _update_resources(enemy_player_resources, nr)
    _update_supplies(enemy_player_supplies, nsa, nsu)



func _update_hearts(hearts: Array, n: int):
    assert(n <= len(hearts))
    var i = 0
    while i < n:
        hearts[i].texture = TEXTURE_HEART_FULL
        i += 1
    while i < len(hearts):
        hearts[i].texture = TEXTURE_HEART_EMPTY
        i += 1

func _update_resources(resources: Array, n: int):
    assert(n <= len(resources))
    var i = 0
    while i < n:
        resources[i].texture = TEXTURE_RESOURCE_FULL
        i += 1
    while i < len(resources):
        resources[i].texture = null
        i += 1

func _update_supplies(supplies: Array, n: int, u: int):
    assert(n <= len(supplies))
    assert(u <= len(supplies))
    var i = 0
    if u <= n:
        while i < u:
            supplies[i].texture = TEXTURE_SUPPLY_USED
            i += 1
        while i < n:
            supplies[i].texture = TEXTURE_SUPPLY_FREE
            i += 1
    else:
        while i < n:
            supplies[i].texture = TEXTURE_SUPPLY_USED
            i += 1
        while i < u:
            supplies[i].texture = TEXTURE_SUPPLY_OVER
            i += 1
    while i < len(supplies):
        supplies[i].texture = null
        i += 1
