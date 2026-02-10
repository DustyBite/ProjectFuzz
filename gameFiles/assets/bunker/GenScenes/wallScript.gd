extends Node

@onready var light1 := $leftLight
@onready var light2 := $centerLight
@onready var light3 := $rightLight
@onready var wallMesh := $wallMesh

var wallMeshEmission

func _ready() -> void:
	wallMeshEmission = wallMesh.get_active_material(2)

func _process(_delta: float) -> void:
	light1.light_color = Global.worldColor
	light2.light_color = Global.worldColor
	light3.light_color = Global.worldColor
	wallMeshEmission.emission = Global.worldColor
