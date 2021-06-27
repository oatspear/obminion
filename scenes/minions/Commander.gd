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
var species_name: String = "Commander"
var power: int = 1
var health: int = 1
var player_owner: int = -1
var tile_index: int = -1

onready var _sprite: AnimatedSprite = $Sprite
onready var _tween: Tween = $Tween

################################################################################
# Interface
################################################################################

func set_state(state: Reference):
    power = state.power
    health = state.health
    player_owner = state.owner
    species_uid = state.species.uid
    species_name = state.species.name

func damage(dmg: int):
    health -= dmg
    _sprite.play("damage")
# warning-ignore:return_value_discarded
    _sprite.connect("animation_finished", self, "_on_animation_finished", [], CONNECT_ONESHOT)

func can_act():
    return false


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
    _sprite.play("idle")

func _on_animation_finished():
    emit_signal("animation_finished")
