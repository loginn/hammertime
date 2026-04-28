extends CanvasLayer

const DISPLAY_DURATION: float = 3.0
const FADE_DURATION: float = 0.5

var _label: Label
var _timer: float = 0.0
var _fading: bool = false


func _ready() -> void:
	layer = 100
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_label.offset_top = -40
	_label.offset_bottom = -8
	_label.add_theme_color_override("font_color", Color(1, 0.9, 0.7, 1))
	_label.add_theme_font_size_override("font_size", 18)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = false
	root.add_child(_label)


func show_message(text: String) -> void:
	_label.text = text
	_label.modulate.a = 1.0
	_label.visible = true
	_timer = 0.0
	_fading = false


func _process(delta: float) -> void:
	if not _label.visible:
		return
	_timer += delta
	if not _fading and _timer >= DISPLAY_DURATION:
		_fading = true
		_timer = 0.0
	if _fading:
		_label.modulate.a = 1.0 - (_timer / FADE_DURATION)
		if _timer >= FADE_DURATION:
			_label.visible = false
			_fading = false
