# Assert families

Every entry point takes the value under test and returns an assert object. Methods
chain. All of them are read from gdUnit4 6.2.1 source.

Shared by every family: `is_null`, `is_not_null`, `is_equal`, `is_not_equal`,
`override_failure_message`, `append_failure_message`.

## assert_bool

`is_true` `is_false`

## assert_int

`is_less` `is_less_equal` `is_greater` `is_greater_equal` `is_even` `is_odd`
`is_negative` `is_not_negative` `is_zero` `is_not_zero` `is_in` `is_not_in`
`is_between`

## assert_float

`is_equal_approx` `is_less` `is_less_equal` `is_greater` `is_greater_equal`
`is_negative` `is_not_negative` `is_zero` `is_not_zero` `is_in` `is_not_in`
`is_between`

There is no `is_even`/`is_odd` on floats. `is_equal_approx(value, epsilon)` is the
one to reach for after physics ran.

## assert_str

`is_equal_ignoring_case` `is_not_equal_ignoring_case` `is_empty` `is_not_empty`
`contains` `not_contains` `contains_ignoring_case` `not_contains_ignoring_case`
`starts_with` `ends_with` `has_length`

## assert_array

`is_empty` `is_not_empty` `is_same` `is_not_same` `has_size` `contains`
`contains_exactly` `contains_exactly_in_any_order` `contains_same`
`contains_same_exactly` `contains_same_exactly_in_any_order` `not_contains`
`not_contains_same` `extract` `extractv`

`contains` means "at least these". `contains_exactly` means same elements, same
order, nothing else. The `_same` variants compare by reference instead of value.

`extract` maps a method name over the array before asserting:

```gdscript
	assert_array(enemies).extract("get_name").contains_exactly(["bat", "slime"])
```

## assert_dict

`is_empty` `is_not_empty` `is_same` `is_not_same` `has_size` `contains_keys`
`contains_key_value` `not_contains_keys` `contains_same_keys`
`contains_same_key_value` `not_contains_same_keys`

## assert_vector

`is_equal_approx` `is_less` `is_less_equal` `is_greater` `is_greater_equal`
`is_between` `is_not_between`

Works for every `Vector2/2i/3/3i/4/4i`. Pass `type_check := false` to compare a
`Vector2` against a `Vector2i`.

## assert_object

`is_same` `is_not_same` `is_instanceof` `is_not_instanceof` `is_inheriting`
`is_not_inheriting` `is_valid`

`is_valid` is the freed-object check. `is_same` is reference identity.

## assert_file

`is_file` `exists` `is_script` `contains_exactly`

## assert_result

`is_empty` `is_success` `is_warning` `is_error` `contains_message` `is_value`

For functions returning a `GdUnitResult`.

## assert_signal

`is_emitted` `is_not_emitted` `is_signal_exists` `wait_until`

Always `await` these. `monitor_signals(source)` must be called before the emitting
action. `wait_until(ms)` sets the timeout; the default is 2000ms and
`is_not_emitted` always spends all of it.

## assert_func

`is_true` `is_false` `wait_until`

Polls a method until it answers, instead of waiting on a signal.

```gdscript
	await assert_func(spawner, "is_wave_cleared").wait_until(500).is_true()
```

## assert_error

`is_success` `is_runtime_error` `is_push_warning` `is_push_error`

Wraps a `Callable` and asserts on what Godot reported while it ran.

```gdscript
	await assert_error(func() -> void: node.take_damage(-1)).is_push_error("negative damage")
```

## assert_failure

Asserts that an assertion itself fails. Used to test custom assertions.

```gdscript
	assert_failure(func() -> void: assert_int(1).is_equal(2)) \
		.is_failed().has_message("Expecting:\n '2'\n but was\n '1'")
```

## assert_that

The untyped fallback. It picks a family from the runtime type. Prefer the explicit
family — the failure messages are better and the method set is checked at parse
time.
