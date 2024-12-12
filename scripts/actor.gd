extends "res://scripts/model.gd"

@onready var body: CharacterBody2D = get_node("CharacterBody2D")
@onready var label: Label = get_node("CharacterBody2D/CenterContainer/Label")
@onready var sprite: Sprite2D = get_node("CharacterBody2D/Sprite2D")

var server_position: Vector2
var actor_name: String
var velocity: Vector2 = Vector2.ZERO

var is_player: bool = false
var _player_target: Vector2

var speed: float = 70.0
var rubber_band_radius: float = 200

func _ready():
	var ientity = initial_data['instanced_entity']
	server_position = Vector2(float(ientity['x']), float(ientity['y']))
	body.position = server_position
	if is_player:
		_player_target = server_position
		var camera = Camera2D.new()
		camera.zoom = Vector2(1.5, 1.5)
		body.add_child(camera)
	actor_name = ientity['entity']['name']
	if label:
		label.text = actor_name

func update(new_model: Dictionary):
	super(new_model)
	if new_model.has('instanced_entity'):
		var ientity = new_model['instanced_entity']
		if (ientity.has('x') and ientity.has('y')):
			server_position = Vector2(float(ientity['x']), float(ientity['y']))
			if (body.position - server_position).length() > rubber_band_radius:
				body.position = server_position
		if ientity.has('entity'):
			var entity = ientity['entity']
			if entity.has('name'):
				actor_name = entity['name']
				if label:
					label.text = actor_name

func _physics_process(delta: float) -> void:
	if not body:
		return
	var target: Vector2
	if is_player:
		target = _player_target
	elif server_position:
		target = server_position
	
	velocity = (target - body.position).normalized() * speed
	if (target - body.position).length() > 5:
		body.velocity = velocity
		body.move_and_slide()
		velocity = body.velocity
