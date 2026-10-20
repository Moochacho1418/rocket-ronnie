extends CanvasLayer

@onready var rockets_label = $Margin/Rows/Rockets
@onready var health_bar = $Margin/Rows/Health


func _process(_delta):
	var ronnie = get_tree().get_first_node_in_group("player")
	if ronnie == null:
		return
	rockets_label.text = "Rockets %d/%d" % [ronnie.rockets, Game.tuning.rocket_count]
	health_bar.max_value = Game.tuning.max_health
	health_bar.value = ronnie.health
