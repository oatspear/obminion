extends Node2D

################################################################################
# Constants
################################################################################

const FRAME_PATH = "res://assets/minions/%d/spriteframes.tres"

################################################################################
# Signals
################################################################################

signal animation_finished()

################################################################################
# Internal State
################################################################################

var species_uid: int = 0
var species_name: String = "Minion"
var power: int = 1
var health: int = 1
var movement: int = 1
var player_owner: int = -1
var minion_index: int = -1
var board_location: int = Global.BoardLocation.NONE
var tile_index: int = -1

onready var _sprite: AnimatedSprite = $Sprite
onready var _tween: Tween = $Tween

################################################################################
# Interface
################################################################################

func set_state(state: Reference):
    power = state.power
    health = state.health
    movement = state.movement
    player_owner = state.owner
    minion_index = state.index
    species_uid = state.species.uid
    species_name = state.species.name


func move_to_tile(tile: Node2D):
    tile_index = tile.tile_index
    return move_to(tile.global_position)

func move_to(target_position: Vector2, duration: float = 1.0):
    var err = _tween.connect("tween_all_completed", self,
            "_on_animation_finished", [], CONNECT_ONESHOT)
    assert(not err)
# warning-ignore:return_value_discarded
    _tween.interpolate_property(self, "global_position",
        global_position, target_position, duration,
        Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
# warning-ignore:return_value_discarded
    _tween.start()
    _sprite.flip_h = target_position.x < global_position.x
    if _sprite.animation != "run":
        _sprite.play("run")


func exit_bench():
    _sprite.play("jump")
    yield(_sprite, "animation_finished")
# warning-ignore:return_value_discarded
    _tween.interpolate_property(_sprite, "position:y",
        0, -80, 0.5,
        Tween.TRANS_QUAD, Tween.EASE_OUT)
    #_tween.interpolate_property(self, "modulate:a",
    #    255, 0, 0.5,
    #    Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
# warning-ignore:return_value_discarded
    _tween.start()
    yield(_tween, "tween_all_completed")
    _sprite.position.y = 0
    #self.modulate.a = 255
    visible = false
    call_deferred("emit_signal", "animation_finished")

func enter_battlefield(target_position: Vector2):
    visible = true
    global_position = target_position
    _sprite.position.y = -80
    _sprite.animation = "fall"
    _sprite.stop()
# warning-ignore:return_value_discarded
    _tween.interpolate_property(_sprite, "position:y",
        -80, 0, 0.5,
        Tween.TRANS_QUAD, Tween.EASE_IN)
    #_tween.interpolate_property(self, "modulate:a",
    #    0, 255, 0.5,
    #    Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
# warning-ignore:return_value_discarded
    _tween.start()
    yield(_tween, "tween_all_completed")
# warning-ignore:return_value_discarded
    _sprite.connect("animation_finished", self, "_on_animation_finished", [], CONNECT_ONESHOT)
    _sprite.call_deferred("play")



func damage(dmg: int):
    health -= dmg
    _sprite.play("damage")
# warning-ignore:return_value_discarded
    _sprite.connect("animation_finished", self, "_on_animation_finished", [], CONNECT_ONESHOT)


func can_act():
    if board_location == Global.BoardLocation.NONE:
        return false
    if board_location == Global.BoardLocation.GRAVEYARD:
        return false
    return movement > 0 and health > 0


################################################################################
# Animation
################################################################################

func play_default():
    _sprite.play("default")

func play_idle():
    _sprite.play("idle")

func play_salute():
    _sprite.play("salute")

func play_pre_attack():
    _sprite.play("ready_attack")
    var err = _sprite.connect("animation_finished", self,
            "_on_animation_finished", [], CONNECT_ONESHOT)
    assert(err == OK)

func play_attack():
    _sprite.play("attack")
    var err = _sprite.connect("animation_finished", self,
            "_on_animation_finished", [], CONNECT_ONESHOT)
    assert(err == OK)

func play_attack_full():
    _sprite.play("attack_full")
    var err = _sprite.connect("animation_finished", self,
            "_on_animation_finished", [], CONNECT_ONESHOT)
    assert(err == OK)

func play_defend():
    _sprite.play("defend")
    var err = _sprite.connect("animation_finished", self,
            "_on_animation_finished", [], CONNECT_ONESHOT)
    assert(err == OK)

func play_dead():
    _sprite.play("dead")
    var err = _sprite.connect("animation_finished", self,
            "_on_animation_finished", [], CONNECT_ONESHOT)
    assert(err == OK)


################################################################################
# Event Callbacks
################################################################################

func _ready():
    _sprite.frames = load(FRAME_PATH % species_uid)
    if board_location == Global.BoardLocation.BATTLEFIELD:
        _sprite.play("idle")
    else:
        _sprite.play("default")

func _on_animation_finished():
    emit_signal("animation_finished")
