# Changelog

## [0.3.0] - 2017-10-02

### Breaking changes

- **Timerizer now only supports Ruby 2.0+**!
- **`RelativeTime` is now `Timerizer:Duration`**. If you used the explicit
  `RelativeTime` constructor, you will need to update your code accordingly
  when updating to Timerizer 0.3.0+!
- **`WallClock` has moved into the `Timerizer` module**, so if you were using
  `WallClock`, all references will need to be updated to `Timerizer::WallClock`!
- The two-argument constructor of `RelativeTime` has been removed (i.e: `RelativeTime.new(5, :minutes)`). The equivalent with `Duration` now uses a hash: `Timerizer::Duration.new(minutes: 5)`
- `RelativeTime#average`, `RelativeTime#average!`, `RelativeTime#unaverage` and `RelativeTime#unaverage!` are no more. The equivalent methods are now `Duration#denormalize` (replacing `#unaverage`) and `Duration#normalize` (replacing `#average`), and both mutating versions are no more. **Note that `#average`/`#unaverage` do not give the same results as `#denormalize`/`#normalize`**, so be wary if you depended on the exact values.
- Remove `RelativeTime#{unit}` and `RelativeTime#in_{unit}` methods. These methods never really worked as intended (as seen in [issue #6](https://github.com/kylewlacy/timerizer/issues/6)).
  The closest equivalents are `Duration#to_unit` method (which takes a unit
  as a symbol), and the `Duration#to_{unit}` methods (`#to_seconds`,
  `#to_minutes`, etc.) . These methods live under a different name because the
  results differ from the former `#in_{unit}`/`#{unit}` methods.
- The `units`, `units_in_seconds` and `units_in_months` class methods
  from `RelativeTime` have been removed. See the new `Duration::UNITS` and
  `Duration::UNIT_ALIASES` constants for a replacement.
- Comparisons on `Duration` differ from the former comparisons on
  `RelativeTime`. Durations are normalized before comparing, so some equality
  tests may now return `true` (for example, `30.days == 1.month` now returns
  true due to normalization).

### Changed

- Timerizer now depends on Ruby 2.0+
- `RelativeTime` is now `Duration`
- `Duration` and `WallClock` have been moved into the new `Timerizer` module
- `Duration#new` has been reworked. It now takes a single hash mapping units
  to unit quantities. Unlike the old constructor, it takes arbitrary units
  now, not just `:seconds` and `:months`.
- `Duration#to_s` now uses `"mo"` as a shorthand instead of `"mn"`.
- `Duration#to_s` will now never return decades, centuries, or millennia in
  the default string formats. The changes to `Duration#to_s` now accept
  user-defined formatters, so clients can restore the old behavior with a
  custom formatter if needed.
- `Duration#to_s` now normalizes and denormalizes before printing. This means
  `30.days.to_s` will be equivalent to `1.month.to_s` by default.
- `Duration#==` now normalizes before comparison, so some comparions may be
  true that were false previously.

## Added

- Added `Duration#to_unit` to convert a duration to a specific unit. `#to_unit`
  normalizes the duration, so return values are more intuitive than the old
  conversion methods (for example, `1.month.to_unit(:seconds)` returns `30`).
- Added `Duration#to_units` to convert a duration to multiple significant units.
  This is similar to `Duration#to_unit`, except it can return multiple units
  at once. Example: `90.minutes.to_units(:hours, :minutes)` returns
  `{hours: 1, minutes: 30}`. See the docs for more details.
- Add `Duration#to_{unit}` helper methods (`#to_seconds`, `#to_minutes`, etc.).
- Added new `Duration#normalize` and `Duration#denormalize` to convert
  between second-based and month-based units.
- `Duration` now implements `#<=>` and `Comparable` to get all comparison
  operators (instead of just `==` and `!=`).
- `Duration` now supports representing negative durations of time.
- `Duration` now implements `#-@` (unary negation).
- `Duration` now implements `#*` (multiplication) and `#/` (divison) to multiply
  and divide by scalar values (currently only `Integer`s are supported).
- `Duration#to_s` now takes user-defined options. See the docs for more details.

## Fixed

- `Duration#to_s` no longer returns `""` (empty string) for empty durations
  (such as `0.seconds`). If _all_ units are empty, the returned string will
  be `"0 seconds"` (or equivalent based on formatting options).
- The new `Duration#to_{unit}` conversion methods fix conversions between
  second-based and month-based units by normalizing units first. This resolves
  [issue #6](https://github.com/kylewlacy/timerizer/issues/6).

## Removed

- `RelativeTime#average`, `RelativeTime#average!`, `RelativeTime#unaverage`, and
  `RelativeTime#unaverage!` have been removed. `Duration#denormalize` and
  `Duration#normalize` should now be used instead.
- `RelativeTime#in_{unit}` methods (`#in_seconds`, `#in_minutes`, etc.) have
  been removed. `Duration#to_{unit}` should be used instead, but note that
  the replacements may not return the same results as the old `RelativeTime`
  equivalents.
- `RelativeTime#{unit}` methods (`#seconds`, `#minutes`, etc.) have been
  removed. These methods weren't very well defined, but roughly were designed
  to "extract" the given unit from the `RelativeTime`. In general, these can
  be replaced by `Duration#to_units` to break down a duration into multiple
  units, then using `#fetch` or `#[]` on the resulting hash to get the
  specific desired unit (that is, `relative_time.minutes` is roughly equivalent
  to `duration.to_units(:hours, :minutes).fetch(:minutes)`).

## [0.2.1] - 2017-07-03

### Changed

- Relicensed project as MIT! Huge thanks to @cesarfigueroa and @elifoster for
  allowing their patches to be relicensed!
- Fixed metadata in `timerizer.gemspec`. Most previous version showed up as
  published at a different date on [RubyGems](https://rubygems.org/gems/timerizer)
  due to this misconfiguration. This should now be fixed for any future relases.

## [0.2.0] - 2017-07-02

### Changed

- Use `Integer` instead of `Fixnum` (for Ruby 2.4+ compatibility)

## [0.1.4] - 2012-11-20

### Added

- Add `WallClock#from_string` to parse a string into a `WallClock`

### Changed

- Add `:use_seconds` and `:include_meridiem` options to `WallClock#to_s`

## [0.1.3] - 2012-11-19

### Fixed

- `WallClock#new` now works when creating a time representing 12:00PM
- Units are now properly zero-padded in `WallClock#to_s`

## [0.1.2] - 2012-11-19

### Added

- Add `WallClock#to_i`

## [0.1.1] - 2012-11-19

### Changed

- Apply some optimizations to `RelativeTime`

## [0.1.0] - 2012-11-12

### Added

- Add `WallClock` class to represent "wall-clock" times (times without dates)
- Add formatting options to `RelativeTime#to_s`
- Add `Date#at`

## [0.0.3] - 2012-09-22

### Added

- Implement `#==` (equality comparisons) to `RelativeTime`

## [0.0.2] - 2012-09-22

### Added

- Add `#since`, `#until`, and `#between` to `Time`, to compare times and
  return `RelativeTime`s
- Add `#yesterday` and `#tomorrow` to `Date`

## [0.0.1] - 2012-07-17

### Added

- Initial release, which includes the `RelativeTime` class as well as
  `#seconds`, `#minutes`, etc. helpers to create `RelativeTime`s from
  `Fixnum`s
