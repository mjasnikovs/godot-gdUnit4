## Array asserts, parameterized cases and fuzzers on a plain RefCounted.
extends GdUnitTestSuite

@warning_ignore_start("return_value_discarded")
@warning_ignore_start("unsafe_method_access")
# Parameterized and fuzzer parameters must stay inferred; gdUnit4 re-parses the
# default expression from source and a typed fuzzer parameter fails to build.
@warning_ignore_start("inferred_declaration")

var inventory: Inventory


func before_test() -> void:
	# A RefCounted needs no auto_free; it dies with the last reference.
	inventory = Inventory.new()


func test_starts_empty() -> void:
	assert_array(inventory.items()).is_empty()
	assert_bool(inventory.is_full()).is_false()


func test_add_keeps_order() -> void:
	assert_bool(inventory.add("sword")).is_true()
	assert_bool(inventory.add("torch")).is_true()
	assert_array(inventory.items()).contains_exactly(["sword", "torch"])


func test_add_rejects_duplicates() -> void:
	assert_bool(inventory.add("sword")).is_true()
	assert_bool(inventory.add("sword")).is_false()
	assert_array(inventory.items()).has_size(1)


func test_add_rejects_when_full() -> void:
	for item: String in ["a", "b", "c", "d"]:
		assert_bool(inventory.add(item)).is_true()
	assert_bool(inventory.is_full()).is_true()
	assert_bool(inventory.add("e")).is_false()


func test_drop_removes_one() -> void:
	assert_bool(inventory.add("sword")).is_true()
	assert_bool(inventory.add("torch")).is_true()
	assert_bool(inventory.drop("sword")).is_true()
	assert_array(inventory.items()).contains_exactly(["torch"]).not_contains(["sword"])


func test_drop_missing_item_is_false() -> void:
	assert_bool(inventory.drop("ghost")).is_false()


func test_items_returns_a_copy() -> void:
	assert_bool(inventory.add("sword")).is_true()
	var copy: Array[String] = inventory.items()
	copy.append("cheat")
	assert_array(inventory.items()).has_size(1)


## One test, three runs. The last parameter must be named _test_parameters.
func test_capacity_is_reached_after_n_adds(
	count: int, expected_full: bool, _test_parameters := [
		[1, false],
		[3, false],
		[4, true]
	]
) -> void:
	for i: int in count:
		assert_bool(inventory.add("item_%d" % i)).is_true()
	assert_bool(inventory.is_full()).is_equal(expected_full)


## A fuzzer feeds a fresh random value per iteration. 50 runs, filled to capacity.
func test_any_name_fits_until_capacity(
	fuzzer := Fuzzers.rand_str(1, 12), fuzzer_iterations := 50
) -> void:
	# fuzzer_iterations has to be read or unused_parameter rejects the file, and
	# gdUnit4 needs the exact name so it cannot be underscore-prefixed.
	assert_int(fuzzer_iterations).is_equal(50)
	var fresh: Inventory = Inventory.new()
	for i: int in Inventory.CAPACITY:
		# The index prefix keeps names distinct. add() rejects duplicates and two
		# short random strings do collide.
		var item_name: String = "%d_%s" % [i, fuzzer.next_value()]
		assert_bool(fresh.add(item_name)).is_true()
	assert_bool(fresh.is_full()).is_true()
	assert_bool(fresh.add("one_too_many")).is_false()
	assert_array(fresh.items()).has_size(Inventory.CAPACITY)
