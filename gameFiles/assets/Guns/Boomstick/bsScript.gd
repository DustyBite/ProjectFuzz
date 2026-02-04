extends GunScript

@export_enum("buck", "bird", "slug") var ammoType: String = "buck"

@export var buckPellets := 8
@export var buckSpread := 10
@export var buckDamage := 10
@export var birdPellets := 14
@export var birdSpread := 18
@export var birdDamage := 2
@export var slugSpread := 1
@export var slugDamage := 60


func shoot():
	match ammoType:
		"slug":
			shootSingle(true, slugSpread, slugDamage)
		"buck":
			shootSpread(buckPellets, buckSpread, buckDamage)
		"bird":
			shootSpread(birdPellets, birdSpread, birdDamage)
