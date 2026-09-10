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

	assert_bool(turret.engage(ORIGIN, NEAR)).is_false()   # can_fire() answered false
	verify(weapon).can_fire()
```

Modes:

```gdscript
	mock(Weapon)                       # RETURN_DEFAULTS, the default
	mock(Weapon, CALL_REAL_FUNC)       # runs the real body
	mock(Weapon, RETURN_DEEP_STUB)     # object returns are themselves mocks
```

A mock of a `Node` subclass does not need `auto_free`. gdUnit4 releases doubles
with the test; the suite reports 0 orphans.

## Stub

`do_return` fixes one method's answer. Read it as a sentence.

```gdscript
	do_return(true).on(weapon).can_fire()
	do_return(3).on(weapon).ammo_left()
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
	verify(weapon).fire(NEAR)
	assert_int(weapon.ammo).is_equal(5)     # ammo really dropped
```

Talk to the **spy**, not the original. Calls made straight to `real` are invisible
to `verify`.

## Verify

```gdscript
	verify(weapon).fire(NEAR)               # exactly once, default times = 1
	verify(weapon, 0).fire(FAR)             # never
	verify(weapon, 2).fire(any_vector2())   # exactly twice
	verify_no_interactions(weapon)          # nothing at all was called
	verify_no_more_interactions(weapon)     # nothing left unverified
	reset(weapon)                           # clear the recorded calls
```

`verify_no_more_interactions` counts **every** recorded call. A probe call the code
under test made on the way — `can_fire()` before `fire()` — is an unverified
interaction and fails the assertion. Verify it too, or drop to
`verify(weapon).fire(...)` alone.

Measured failure message when `can_fire()` is left unverified:

```
Expecting no more interactions!
But found interactions on:
	'can_fire()'	1 time's
```

## Argument matchers

Use one when the exact value does not matter.

```gdscript
	any()            any_bool()       any_int()        any_float()
    any_string()     any_color()      any_vector()     any_vector2()
    any_vector2i()   any_vector3()    any_vector3i()   any_vector4()
    any_vector4i()   any_rect2()      any_plane()      any_quat()
    any_aabb()       any_basis()      any_transform_2d()  any_transform_3d()
```

```gdscript
	verify(weapon, 2).fire(any_vector2())
```

## Strict typing

`mock`, `spy` and `verify` all return `Variant`. Assign through a typed variable
so the rest of the test stays checked:

```gdscript
	var weapon: Weapon = mock(Weapon)
```

`as Weapon` also works, but trips `unsafe_cast`. The typed declaration does not.
Calls made on the result still need `@warning_ignore_start("unsafe_method_access")`
at the top of the suite, because `verify(x)` is typed `Variant`.
