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


func _ready():
	super._ready()
	LocalPosTEMP = Vector3(0.19, 1.232,-0.58)

func shoot():
	match ammoType:
		"slug":
			shootSingle(true, slugSpread, slugDamage)
		"buck":
			shootSpread(buckPellets, buckSpread, buckDamage)
		"bird":
			shootSpread(birdPellets, birdSpread, birdDamage)

func changeAmmo():
	clearAmmo()
	match ammoType:
		"slug":
			vest.shotSlug = vest.shotgunAmmo
			vest.shotgunAmmo = vest.shotBuck
			ammoType = "buck"
		"buck":
			vest.shotBuck = vest.shotgunAmmo
			vest.shotgunAmmo = vest.shotBird
			ammoType = "bird"
		"bird":
			vest.shotBird = vest.shotgunAmmo
			vest.shotgunAmmo = vest.shotSlug
			ammoType = "slug"
	getAmmo()

func updateAmmo():
	vest.shotgunAmmo = ammoTotal
	match ammoType:
		"slug":
			vest.shotSlug = vest.shotgunAmmo
		"buck":
			vest.shotBuck = vest.shotgunAmmo
		"bird":
			vest.shotBird = vest.shotgunAmmo

func getAmmoType():
	match ammoType:
		"slug":
			ammoTotal = vest.shotSlug
		"buck":
			ammoTotal = vest.shotBuck
		"bird":
			ammoTotal = vest.shotBird
