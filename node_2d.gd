extends Node2D

enum button {NONE, IMPLICIT, PREFIX, SUFFIX}

var buttons
var button_pressed: button
var current_item: Item

func _ready():
	self.buttons = $ButtonControl.get_children()
	self.current_item = LightSword.new()
	$ButtonControl/ImplicitHammer.connect("pressed", ImplicitHammer_toggled)
	$ButtonControl/AddPrefixHammer.connect("pressed", AddPrefixHammer_toggled)
	$ButtonControl/AddSuffixHammer.connect("pressed", AddSuffixHammer_toggled)
	$ItemView.connect("gui_input", update_item)

func update_item(event: InputEvent):
	if (event is not InputEventMouseButton) or (not event.button_index == MOUSE_BUTTON_LEFT or not event.pressed):
		return
	print("click")
	if self.button_pressed == button.IMPLICIT:
		self.current_item.implicit.reroll()
	elif self.button_pressed == button.PREFIX:
		self.current_item.add_prefix()
	elif self.button_pressed == button.SUFFIX:
		self.current_item.add_suffix()
	else:
		print("no button selected")
	print(current_item.display())

func untoggle_all_other_buttons(pressed_button: Button):
	for btn in self.buttons:
		if btn != pressed_button:
			btn.button_pressed = false

func ImplicitHammer_toggled():
	self.untoggle_all_other_buttons($ButtonControl/ImplicitHammer)
	if $ButtonControl/ImplicitHammer.button_pressed:
		self.button_pressed = button.IMPLICIT
		print("implicit")

func AddPrefixHammer_toggled():
	self.untoggle_all_other_buttons($ButtonControl/AddPrefixHammer)
	if $ButtonControl/AddPrefixHammer.button_pressed:
		self.button_pressed = button.PREFIX
		print("prefix")

func AddSuffixHammer_toggled():
	self.untoggle_all_other_buttons($ButtonControl/AddSuffixHammer)
	if $ButtonControl/AddSuffixHammer.button_pressed:
		self.button_pressed = button.SUFFIX
		print("suffix")
