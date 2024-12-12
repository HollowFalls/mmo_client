extends Control

@onready var username_field: LineEdit = get_node("CanvasLayer/VBoxContainer/GridContainer/LineEdit_username")
@onready var password_field: LineEdit = get_node("CanvasLayer/VBoxContainer/GridContainer/LineEdit_password")
@onready var login_button: Button = get_node("CanvasLayer/VBoxContainer/CenterContainer/HBoxContainer/Button_login")
@onready var register_button: Button = get_node("CanvasLayer/VBoxContainer/CenterContainer/HBoxContainer/Button_register")

signal login(username, password)
signal register(username, password)

var password_field_secret: bool

func _ready():
	password_field_secret = true
	login_button.connect("pressed", _login)
	register_button.connect("pressed", _register)

func _login():
	emit_signal("login", username_field.text, password_field.text)
func _register():
	emit_signal("register", username_field.text, password_field.text)
