extends Label

const TRAVEL = Vector2(0, -80)
const DURATION = 1
const SPREAD = PI/2

func show_value(value, pos: Vector2, crit=false,
                duration=null, travel=null, spread=null):
    text = value
    rect_global_position = pos
    rect_pivot_offset = rect_size / 2
    rect_position.x -= rect_size.x / 2
    rect_position.y -= rect_size.y
    if duration == null:
        duration = DURATION
    if travel == null:
        travel = TRAVEL
    if spread == null:
        spread = SPREAD
    var movement = travel.rotated(rand_range(-spread/2, spread/2))
    $Tween.interpolate_property(self, "rect_position",
            rect_position, rect_position + movement,
            duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    $Tween.interpolate_property(self, "modulate:a",
            1.0, 0.0, duration,
            Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    if crit:
        modulate = Color(1, 0, 0)
        $Tween.interpolate_property(self, "rect_scale",
            rect_scale*2, rect_scale,
            0.4, Tween.TRANS_BACK, Tween.EASE_IN)
    $Tween.start()
    yield($Tween, "tween_all_completed")
    queue_free()
