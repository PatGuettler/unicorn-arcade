class_name AdBannerRecoveryPolicy
extends RefCounted

static func is_stale(requested: bool, loaded: bool, started_ms: int, now_ms: int, threshold_ms: int) -> bool:
	return requested and not loaded and now_ms - started_ms >= threshold_ms

static func needs_recovery(view_present: bool, requested: bool, loaded: bool, started_ms: int, now_ms: int, threshold_ms: int) -> bool:
	return not view_present or is_stale(requested, loaded, started_ms, now_ms, threshold_ms)
