class_name GameExperienceTutorialPresenter
extends RefCounted

const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")


func build(card: PanelContainer, overlay: Control, tutorial_level: int, lessons: Array[String], advance_cb: Callable) -> void:
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 18)
	card.add_child(stack)
	var heading := Label.new()
	heading.text = "GUIDED LEVEL %d  •  STEP 1 OF 3" % tutorial_level
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 27)
	heading.add_theme_color_override("font_color", Color("9c356d"))
	heading.name = "TutorialHeading"
	stack.add_child(heading)
	var sparkle := Label.new()
	sparkle.text = "✦  🦄  ✦"
	sparkle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sparkle.add_theme_font_size_override("font_size", 42)
	stack.add_child(sparkle)
	var lesson := Label.new()
	lesson.name = "TutorialLesson"
	lesson.text = lessons[0]
	lesson.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lesson.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lesson.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lesson.custom_minimum_size.y = 150
	lesson.add_theme_font_size_override("font_size", 25)
	lesson.add_theme_color_override("font_color", StorybookUI.INK)
	stack.add_child(lesson)
	var next := Button.new()
	next.name = "TutorialNext"
	next.text = "SHOW ME THE NEXT STEP"
	StorybookUI.apply_game_action(next, 280)
	next.pressed.connect(advance_cb.bind(overlay))
	stack.add_child(next)


func advance(overlay: Control) -> bool:
	if not is_instance_valid(overlay):
		return false
	var lessons: Array = overlay.get_meta("lessons")
	var step := int(overlay.get_meta("step")) + 1
	if step >= lessons.size():
		return true
	overlay.set_meta("step", step)
	var heading := overlay.find_child("TutorialHeading", true, false) as Label
	var lesson := overlay.find_child("TutorialLesson", true, false) as Label
	var next := overlay.find_child("TutorialNext", true, false) as Button
	heading.text = "GUIDED LEVEL %d  •  STEP %d OF %d" % [int(overlay.get_meta("tutorial_level")), step + 1, lessons.size()]
	lesson.text = str(lessons[step])
	next.text = "LET ME PLAY" if step == lessons.size() - 1 else "SHOW ME THE NEXT STEP"
	return false
