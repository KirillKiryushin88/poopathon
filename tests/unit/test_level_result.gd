extends GutTest


func test_three_stars_when_hp_above_80_pct() -> void:
	var result: LevelResult = LevelResult.new()
	result.won = true
	result.throne_hp_pct = 0.9
	result.compute_stars()
	assert_eq(result.stars, 3)


func test_two_stars_when_hp_between_40_and_80_pct() -> void:
	var result: LevelResult = LevelResult.new()
	result.won = true
	result.throne_hp_pct = 0.6
	result.compute_stars()
	assert_eq(result.stars, 2)


func test_one_star_when_hp_above_zero() -> void:
	var result: LevelResult = LevelResult.new()
	result.won = true
	result.throne_hp_pct = 0.1
	result.compute_stars()
	assert_eq(result.stars, 1)


func test_zero_stars_when_lost() -> void:
	var result: LevelResult = LevelResult.new()
	result.won = false
	result.compute_stars()
	assert_eq(result.stars, 0)
