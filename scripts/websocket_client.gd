extends Node

const Packet = preload("res://scripts/packet.gd")

signal connected
signal data
signal disconnected
signal error

# Our WebSocketPeer instance
var _client = WebSocketPeer.new()
func _ready():
	_client.connect("connection_closed", _closed)
	_client.connect("connection_error", _closed)
	_client.connect("connection_established", _connected)
	_client.connect("data_received", _on_data)

func connect_to_server(hostname: String, port: int) -> void:
	var websocket_url = "ws://%s:%d" % [hostname, port]
	var err = _client.connect_to_url(websocket_url)
	if err:
		print("Unable to connect")
		set_process(false)
		emit_signal('error')

func send_packet(packet: Packet) -> void:
	_send_string(packet.toString())

func _closed(was_clean = false):
	print("Closed, clean: ", was_clean)
	set_process(false)
	emit_signal('disconnected', was_clean)

func _connected(proto = ""):
	print("Connected with protocol: ", proto)
	emit_signal("connected")

func _on_data():
	var data: String = _client.get_packet().get_string_from_utf8()
	print("Got data from server: ", data)
	emit_signal("data", data)

func _process(delta):
	_client.poll()
	var state = _client.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while _client.get_available_packet_count():
			_on_data()
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = _client.get_close_code()
		var reason = _client.get_close_reason()
		_closed()
func _send_string(string: String) -> void:
	_client.put_packet(string.to_utf8_buffer())
	print("Sent string ", string)
