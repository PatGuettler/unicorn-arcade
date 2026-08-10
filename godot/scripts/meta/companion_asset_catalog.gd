class_name CompanionAssetCatalog
extends RefCounted

## Paths deliberately remain strings.  Preloading the GLBs here causes Godot to
## deserialize every companion (and its textures) before the player can reach
## the first interactive screen.
const MODEL_PATHS := {
	"sparkle": "res://assets/characters/unicorns/unicorn_sparkle_v1.glb",
	"rainbow": "res://assets/characters/unicorns/unicorn_rainbow_v1.glb",
	"star": "res://assets/characters/unicorns/unicorn_star_v1.glb",
	"cloud": "res://assets/characters/unicorns/unicorn_cloud_v1.glb",
	"dream": "res://assets/characters/unicorns/unicorn_dreamer_v1.glb",
	"mystic": "res://assets/characters/unicorns/unicorn_mystic_v1.glb",
}

const SCALES := {"sparkle": 1.28, "rainbow": 1.28, "star": 1.28, "cloud": 1.28, "dream": 1.28, "mystic": 1.12}

const THUMBNAIL_PATHS := {
	"sparkle": "res://assets/characters/unicorns/thumbnails/sparkle.png",
	"rainbow": "res://assets/characters/unicorns/thumbnails/rainbow.png",
	"star": "res://assets/characters/unicorns/thumbnails/star.png",
	"cloud": "res://assets/characters/unicorns/thumbnails/cloud.png",
	"dream": "res://assets/characters/unicorns/thumbnails/dream.png",
	"mystic": "res://assets/characters/unicorns/thumbnails/mystic.png",
}


static func normalized_id(companion_id: String) -> String:
	return companion_id if MODEL_PATHS.has(companion_id) else "sparkle"


static func model_path(companion_id: String) -> String:
	return str(MODEL_PATHS[normalized_id(companion_id)])


static func scale_for(companion_id: String) -> float:
	return float(SCALES.get(normalized_id(companion_id), 1.28))


static func thumbnail_path(companion_id: String) -> String:
	return str(THUMBNAIL_PATHS[normalized_id(companion_id)])
