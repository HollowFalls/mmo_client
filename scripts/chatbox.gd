extends Control


@onready var chat_log = get_node("CanvasLayer/PanelContainer/VBoxContainer/RichTextLabel")
@onready var input_field = get_node("CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer/LineEdit")

signal message_sent(message)

func _ready():
	input_field.connect("text_submitted", text_entered)
	chat_log.connect("meta_clicked", chatbox_clicked)

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER:
				input_field.grab_focus()
			KEY_ESCAPE:
				input_field.release_focus()

func add_message(sender, message: String):
	chat_log.text += "[" + sender + "]: " + message + "\n "

func text_entered(text: String):
	if (len(text) > 0):
		input_field.text = ""

		emit_signal("message_sent", text)
		input_field.release_focus()

func chatbox_clicked():
	input_field.release_focus()
