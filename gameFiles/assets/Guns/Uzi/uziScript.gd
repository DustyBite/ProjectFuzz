extends GunScript

@export_enum("Armor-Piercing", "Hollow Point", "Full Metal Jacket") var ammoType: String = "Hollow Point"

@export var apSpread := 3.5
@export var apDamage := 10
@export var hpSpread := 2.5
@export var hpDamage := 18
@export var fmjSpread := 3
@export var fmjDamage := 12

func _ready():
	super._ready()
	LocalPosTEMP = Vector3(0.228, 1.196,-0.48)

func shoot():
	match ammoType:
		"Armor-Piercing":
			shootSingle(true, apSpread, apDamage)
		"Hollow Point":
			shootSingle(false, hpSpread, hpDamage)
		"Full Metal Jacket":
			shootSingle(true, fmjSpread, fmjDamage)

func changeAmmo():
	clearAmmo()
	match ammoType:
		"Armor-Piercing":
			vest.apAmmo = vest.nineMilAmmo
			vest.nineMilAmmo = vest.hpAmmo
			ammoType = "Hollow Point"
		"Hollow Point":
			vest.hpAmmo = vest.nineMilAmmo
			vest.nineMilAmmo = vest.fmjAmmo
			ammoType = "Full Metal Jacket"
		"Full Metal Jacket":
			vest.fmjAmmo = vest.nineMilAmmo
			vest.nineMilAmmo = vest.apAmmo
			ammoType = "Armor-Piercing"
	getAmmo()

func updateAmmo():
	vest.nineMilAmmo = ammoTotal
	match ammoType:
		"Armor-Piercing":
			vest.apAmmo = vest.nineMilAmmo
		"Hollow Point":
			vest.hpAmmo = vest.nineMilAmmo
		"Full Metal Jacket":
			vest.fmjAmmo = vest.nineMilAmmo

func getAmmoType():
	match ammoType:
		"Armor-Piercing":
			ammoTotal = vest.apAmmo
		"Hollow Point":
			ammoTotal = vest.hpAmmo
		"Full Metal Jacket":
			ammoTotal = vest.fmjAmmo
