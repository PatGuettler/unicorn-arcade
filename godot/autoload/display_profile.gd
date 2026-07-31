extends Node

## Mobile / tablet layout helpers (mirrors web playArea + safe areas).

const PHONE_BREAKPOINT := 600.0


func is_tablet() -> bool:
	var size := get_viewport().get_visible_rect().size
	return minf(size.x, size.y) >= PHONE_BREAKPOINT


func content_margin() -> int:
	var safe := DisplayServer.get_display_safe_area()
	var vp := get_viewport().get_visible_rect()
	var top := maxi(0, safe.position.y - int(vp.position.y))
	var bottom := maxi(0, int(vp.end.y) - safe.end.y)
	return maxi(top, bottom) + 8


func grid_columns(default_phone: int = 2, default_tablet: int = 3) -> int:
	return default_tablet if is_tablet() else default_phone


func min_touch_size() -> int:
	return 44
