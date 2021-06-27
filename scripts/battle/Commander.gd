extends Reference

################################################################################
# Internal State
################################################################################

var owner: int = 0
var species: Resource = null
var health: int = 1
var power: int = 1
var location: int = Global.BoardLocation.BATTLEFIELD
var position: int = 0

################################################################################
# Interface
################################################################################

func init(minion_data: Resource):
    species = minion_data
    reset_stats()

func set_active():
    location = Global.BoardLocation.BATTLEFIELD

func set_benched():
    push_error("Invalid operation.")

func set_dead():
    push_error("Invalid operation.")

func set_removed():
    push_error("Invalid operation.")

func is_active():
    return true

func is_benched():
    return false

func is_dead():
    return false

func is_removed():
    return false

func is_hero():
    return true

func reset_stats():
    health = species.health
    power = species.power
