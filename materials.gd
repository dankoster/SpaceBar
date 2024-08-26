extends Node

enum MaterialKind { 
	ICE, 
	ROCK, 
	SLURM, 
	EXPLODIUM,
	GOLD
}

const MaterialAmount = {
	Materials.MaterialKind.ICE: 10,
	Materials.MaterialKind.ROCK: 5,
	Materials.MaterialKind.SLURM: 1,
	Materials.MaterialKind.EXPLODIUM: 1,
	Materials.MaterialKind.GOLD: 2
}


func getRandomMaterial(rng: RandomNumberGenerator):
	var randomMaterial = Materials.MaterialKind.keys()[rng.randi_range(0,Materials.MaterialKind.size() - 1)]
	var amount = Materials.MaterialAmount[Materials.MaterialKind[randomMaterial]]
	return { 
		"material": randomMaterial,
		"amount": amount
	}


func _ready():
	print('loaded materials')
