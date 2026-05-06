class_name SendBar
extends Control

@export var fill_time := 2.0

var t := 0.0
var _filling := false
var fill_complete := false

signal fill_complete_signal
signal send_successful

@onready var bar_blue_original_width = $BarBlue.size.x
@onready var sending_blue_original_width = $SendingBlue.size.x

func _ready():
	$Loading.hide()

func fill():
	$Loading.show()
	$Failure.hide()
	$Success.hide()
	$AnimationPlayer.play("sending")
	fill_time = randf_range(1, 2)
	visible = true
	#$SendingBlue.visible = true
	#$BarRed.visible = false
	#$ErrorWord.visible = false
	#$DoneWord.visible = false

	t = 0
	_filling = true
	fill_complete = false

func success(): 
	$Loading.hide()
	$Success.show()
	send_successful.emit()
	$AnimationPlayer.play("fade_out")
	#$SendingBlue.visible = false
	#$DoneWord.visible = true
	await get_tree().create_timer(1.0).timeout
	visible = false

func fail():
	$Loading.hide()
	$Failure.show()
	$AnimationPlayer.play("fade_out")
	#$SendingBlue.visible = false
	#$BarRed.visible = true
	#$ErrorWord.visible = true
	await get_tree().create_timer(1.0).timeout
	visible = false

func _process(delta: float) -> void:
	if _filling:
		t = clamp(t + delta / fill_time, 0.0, 1.0)
		$BarBlue.size.x = bar_blue_original_width * t
		$SendingBlue.size.x = sending_blue_original_width * t

		if t == 1.0:
			fill_complete_signal.emit()
			_filling = false
			fill_complete = true
	
