extends Node

var virtual_cursor := Vector2.ZERO

func set_center(viewport: Viewport):
	virtual_cursor = viewport.get_visible_rect().size * 0.5

func update_from_motion(ev: InputEventMouseMotion, viewport: Viewport):
	virtual_cursor += ev.relative /4
	#virtual_cursor = virtual_cursor.clamp(
		#Vector2.ZERO,
		#viewport.get_visible_rect().size
	#)
	var padding := 90.0
	var screen_size = viewport.get_visible_rect().size

	virtual_cursor = virtual_cursor.clamp(
		Vector2(padding, padding),
		screen_size - Vector2(padding, padding)
	)
