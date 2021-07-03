extends Reference

################################################################################
# Internal State
################################################################################

var index: int = 0
var owner: int = 0
var species: Resource = null
var health: int = 1
var power: int = 1
var movement: int = 1
var supply_cost: int = 1
var location: int = Global.BoardLocation.BENCH
var position: int = 0
var is_token: bool = false

################################################################################
# Interface
################################################################################

func init(minion_data: Resource):
    species = minion_data
    reset_stats()

func set_active():
    location = Global.BoardLocation.BATTLEFIELD

func set_benched():
    location = Global.BoardLocation.BENCH

func set_dead():
    location = Global.BoardLocation.GRAVEYARD

func set_removed():
    location = Global.BoardLocation.NONE

func is_active():
    return location == Global.BoardLocation.BATTLEFIELD

func is_benched():
    return location == Global.BoardLocation.BENCH

func is_dead():
    return location == Global.BoardLocation.GRAVEYARD

func is_removed():
    return location == Global.BoardLocation.NONE

func is_hero():
    return false

func reset_stats():
    health = species.health
    power = species.power
    movement = species.movement
    supply_cost = species.supply_cost
