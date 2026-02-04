extends GunScript

@export_enum("Armor-Piercing", "Hollow Point", "Full Metal Jacket") var ammoType: String = "Hollow Point"

@export var apSpread := 3.5
@export var apDamage := 10
@export var hpSpread := 2.5
@export var hpDamage := 18
@export var fmjSpread := 3
@export var fmjDamage := 12


func shoot():
	match ammoType:
		"Armor-Piercing":
			shootSingle(true, apSpread, apDamage)
		"Hollow Point":
			shootSingle(false, hpSpread, hpDamage)
		"Full Metal Jacket":
			shootSingle(true, fmjSpread, fmjDamage)
