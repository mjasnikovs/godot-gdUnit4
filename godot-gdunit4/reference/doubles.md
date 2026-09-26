# Mocks, spies and stubs

Three tools, one job: stop the test from depending on a collaborator's real
behaviour.

| Tool | Real code runs | Calls recorded | Built from |
|---|---|---|---|
| `mock(Weapon)` | no | yes | a class |
| `spy(instance)` | yes | yes | an instance |
| `do_return(v).on(m)` | — | — | stubs one method on a mock or spy |

## Mock

`mock(clazz)` builds a fake. Every method returns the type default: `false`, `0`,
`""`, `null`. Nothing in the real script runs.

```gdscript
	var weapon: Weapon = mock(Weapon)
	turret.weapon = weapon

	assert_bool(turret.engage(ORIGIN, NEAR)).is_false()  # can_fire() answered false
	var checked: Weapon = verify(weapon)
	checked.can_fire()
```

The second argument is the mode:

| Mode | A call on the mock |
|---|---|
| `RETURN_DEFAULTS`, the default | returns the type default |
| `CALL_REAL_FUNC` | runs the real body |
| `RETURN_DEEP_STUB` | returns a mock where the method returns an object |

```gdscript
	var fake: Weapon = mock(Weapon)
	var real_body: Weapon = mock(Weapon, CALL_REAL_FUNC)
	var deep: Weapon = mock(Weapon, RETURN_DEEP_STUB)
```

A mock of a `Node` subclass does not need `auto_free`. gdUnit4 releases doubles
with the test; the suite reports 0 orphans.

## Stub

`do_return` fixes one method's answer. Read it as a sentence.

```gdscript
	var stub: Weapon = do_return(true).on(weapon)
	stub.can_fire()
```

The stub is per mock, not per class. Stubbing does not count as an interaction.

## Spy

`spy(instance)` wraps a live object. The real body runs, so real side effects
happen, and the call is recorded on the way through.

```gdscript
	var real: Weapon = auto_free(Weapon.new())
	add_child(real)
	var weapon: Weapon = spy(real)
	turret.weapon = weapon

	assert_bool(turret.engage(ORIGIN, NEAR)).is_true()
	var checked: Weapon = verify(weapon)
	checked.fire(NEAR)
	# The real fire() ran, so ammo really dropped.
	assert_int(weapon.c_ammo).is_equal(5)
```

Talk to the **spy**, not the original. Calls made straight to `real` are invisible
to `verify`.

## Verify

| Call | Asserts |
|---|---|
| `verify(weapon)` | the method called on its result ran exactly once |
| `verify(weapon, n)` | that method ran exactly `n` times, `0` for never |
| `verify_no_interactions(weapon)` | nothing at all was called |
| `verify_no_more_interactions(weapon)` | nothing is left unverified |
| `reset(weapon)` | nothing; it clears the recorded calls |

`verify` returns the double to call the expected method on, read into a typed
local (below).

`verify_no_more_interactions` counts **every** recorded call. A probe call the code
under test made on the way — `can_fire()` before `fire()` — is an unverified
interaction and fails the assertion. Verify it too, or drop to
verifying `fire(...)` alone.

Measured failure message when `can_fire()` is left unverified:

```
Expecting no more interactions!
But found interactions on:
	'can_fire()'	1 time's
```

## Argument matchers

Use one when the exact value does not matter.

```text
any()            any_bool()       any_int()        any_float()
any_string()     any_color()      any_vector()     any_vector2()
any_vector2i()   any_vector3()    any_vector3i()   any_vector4()
any_vector4i()   any_rect2()      any_plane()      any_quat()
any_aabb()       any_basis()      any_transform_2d()  any_transform_3d()
```

A matcher is not the parameter's type, so it cannot go through a receiver typed
as `Weapon`. `fire(any_vector2())` on a `Weapon` is a parse error: argument 1
should be `Vector2` but is `GdUnitArgumentMatcher`. This is the one call that
stays untyped, with a one-line ignore:

```gdscript
	# A matcher is not a Vector2, so the verify receiver cannot be typed as Weapon.
	@warning_ignore("unsafe_method_access")
	verify(weapon, 2).fire(any_vector2())
```

## Strict typing

`mock`, `spy`, `verify` and `on` all return `Variant`. Assign each one to a typed
local, so the next call is checked like any other:

```gdscript
	var weapon: Weapon = mock(Weapon)
	var stub: Weapon = do_return(true).on(weapon)
	stub.can_fire()
	var checked: Weapon = verify(weapon)
	checked.fire(NEAR)
```

`as Weapon` trips `unsafe_cast`. The typed declaration does not. Measured on
4.7.2: with typed locals, no suite needs `unsafe_method_access` file-wide. Only a
verify with an argument matcher keeps it, on one line.
