extends Node

@onready var light1 := $light1
@onready var light2 := $light2
@onready var light3 := $light3
@onready var light4 := $light4
@onready var skylightMesh1 := $skylightMesh1
@onready var skylightMesh2 := $skylightMesh2

var isEdge = false

var slMeshMain
var slMeshEmission

func _ready() -> void:
	if isEdge == false:
		skylightMesh1.visible = true
		skylightMesh2.visible = false
		slMeshMain = skylightMesh1
	else:
		skylightMesh1.visible = false
		skylightMesh2.visible = true
		slMeshMain = skylightMesh2
	
	slMeshEmission = slMeshMain.get_active_material(2)

func _process(_delta: float) -> void:
	pass
	light1.light_color = Global.worldColor
	light2.light_color = Global.worldColor
	light3.light_color = Global.worldColor
	light4.light_color = Global.worldColor
	slMeshEmission.emission = Global.worldColor
