extends Node2D

const NetworkClient = preload("res://scripts/websocket_client.gd")
const Packet = preload("res://scripts/packet.gd")
const Chatbox = preload("res://chatbox.tscn")
const Actor = preload("res://actor.tscn")

@onready var _login_screen = get_node("Login")
@onready var _network_client = NetworkClient.new()

var state: Callable
var _chatbox = null
var _username: String
var _player_actor = null

var _actors: Dictionary = {}

func _ready():
	_network_client.connect("connected", _handle_client_connected)
	_network_client.connect("disconnected", _handle_client_disconnected)
	_network_client.connect("error", _handle_network_error)
	_network_client.connect("data", _handle_network_data)
	add_child(_network_client)
	_network_client.connect_to_server("mmo.zidlasmrdi.com", 80)
	
	_login_screen.connect("login", _handle_login_button)
	_login_screen.connect("register", _handle_register_button)
	
	state = Callable(self, "")

func PLAY(p):
	match p.action:
		"Chat":
			var sender: String = p.payloads[0]
			var message: String = p.payloads[1]
			_chatbox.add_message(sender, message)
		"ModelDelta":
			var model_data: Dictionary = p.payloads[0]
			_update_models(model_data)
		"Logout":
			var actor_id: int = p.payloads[0]
			var removed_actor = _actors[actor_id]
			remove_child(removed_actor)
			_actors.erase(actor_id)
			

func REGISTER(p):
	match p.action:
		"Ok":
			OS.alert("Registration successful")
		"Deny":
			var reason: String = p.payloads[0]
			OS.alert(reason)

func LOGIN(p):
	match p.action:
		"Ok":
			_enter_game()
		"Deny":
			var reason: String = p.payloads[0]
			OS.alert(reason)

func _enter_game():
	state = Callable(self, "PLAY")
	
	remove_child(_login_screen)
	
	_chatbox = Chatbox.instantiate()
	_chatbox.connect("message_sent", send_chat)
	add_child(_chatbox)

func _update_models(model_data: Dictionary):
	print('Received model data: ', JSON.stringify(model_data))
	var model_id: int = model_data["id"]
	var func_name: String = "_update_"  + model_data["model_type"].to_lower()
	var f: Callable = Callable(self, func_name)
	f.call(model_id, model_data)

func _update_actor(model_id: int, model_data: Dictionary):
	if model_id in _actors:
		_actors[model_id].update(model_data)
	else:
		var new_actor
		if not _player_actor:
			_player_actor = Actor.instantiate().init(model_data)
			_player_actor.is_player = true
			new_actor = _player_actor
		else:
			new_actor = Actor.instantiate().init(model_data)
		_actors[model_id] = new_actor
		add_child(new_actor)
func _handle_client_connected():
	print("Client connected to server")

func _handle_client_disconnected(was_clean: bool):
	OS.alert("Disconnected %s" % ["cleanly" if was_clean else "unexpectedly"])
	get_tree().quit()

func _handle_network_data(data: String):
	print("Received server data: ", data)
	var action_payloads: Array = Packet.json_to_action_payloads(data)
	var p = Packet.new(action_payloads[0], action_payloads[1])
	state.call(p)

func _handle_network_error():
	OS.alert("There was an error")

func _handle_login_button(username: String, password: String):
	_username = username
	state = Callable(self, "LOGIN")
	var p: Packet = Packet.new("Login", [username, password])
	_network_client.send_packet(p)

func _handle_register_button(username: String, password: String):
	state = Callable(self, "REGISTER")
	var p: Packet = Packet.new("Register", [username, password])
	_network_client.send_packet(p)

func send_chat(text: String):
	var p: Packet = Packet.new("Chat", [_username, text])
	_network_client.send_packet(p)
	_chatbox.add_message(_username, text)

func _input(event):
	if _player_actor and event.is_action_pressed("click"):
		var target = _player_actor.body.get_global_mouse_position()
		_player_actor._player_target = target
		var p: Packet = Packet.new("Target", [target.x, target.y])
		_network_client.send_packet(p)
