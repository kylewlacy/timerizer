module Timerizer
  # Represents a duration of time. For example, '5 days', '4 years', and
  # '5 years, 4 hours, 3 minutes, 2 seconds' are all durations conceptually.
  #
  # A `Duration` is made up of two different primitive units: seconds and
  # months. The philosphy behind this is this: every duration of time
  # can be broken down into these fundamental pieces, but cannot be simplified
  # further. For example, 1 year always equals 12 months, 1 minute always
  # equals 60 seconds, but 1 month does not always equal 30 days. This
  # ignores some important corner cases (such as leap seconds), but this
  # philosophy should be "good enough" for most use-cases.
  #
  # This extra divide between "seconds" and "months" may seem useless or
  # conter-intuitive at first, but can be useful when applying durations to
  # times. For example, `1.year.after(Time.new(2000, 1, 1))` is guaranteed
  # to return `Time.new(2001, 1, 1)`, which would not be possible if all
  # durations were represented in seconds alone.
  #
  # On top of that, even though 1 month cannot be _exactly_ represented as a
  # certain number of days, it's still useful to often convert between durations
  # made of different base units, especially when converting a `Duration` to a
  # human-readable format. This is the reason for the {#normalize} and
  # {#denormalize} methods. For convenience, most methods perform normalization
  # on the input duration, so that some results or comparisons give more
  # intuitive values.
  class Duration
    include Comparable

    # A hash describing the different base units of a `Duration`. Key represent
    # unit names and values represent a hash describing the scale of that unit.
    UNITS = {
      seconds: {seconds: 1},
      minutes: {seconds: 60},
      hours: {seconds: 60 * 60},
      days: {seconds: 24 * 60 * 60},
      weeks: {seconds: 7 * 24 * 60 * 60},
      months: {months: 1},
      years: {months: 12},
      decades: {months: 12 * 10},
      centuries: {months: 12 * 100},
      millennia: {months: 12 * 1000}
    }

    # A hash describing different names for various units, which allows for,
    # e.g., pluralized unit names, or more obscure units. `UNIT_ALIASES` is
    # guaranteed to also contain all of the entries from {UNITS}.
    UNIT_ALIASES = UNITS.merge(
      second: UNITS[:seconds],
      minute: UNITS[:minutes],
      hour: UNITS[:hours],
      day: UNITS[:days],
      week: UNITS[:weeks],
      month: UNITS[:months],
      year: UNITS[:years],
      decade: UNITS[:decades],
      century: UNITS[:centuries],
      millennium: UNITS[:millennia]
    )

    # The built-in set of normalization methods, usable with {#normalize} and
    # {#denormalize}. Keys are method names, and values are hashes describing
    # how units are normalized or denormalized.
    #
    # The following normalization methods are defined:
    #
    # - `:standard`: 1 month is approximated as 30 days, and 1 year is
    #   approximated as 365 days.
    # - `:minimum`: 1 month is approximated as 28 days (the minimum in any
    #   month), and 1 year is approximated as 365 days (the minimum in any
    #   year).
    # - `:maximum`: 1 month is approximated as 31 days (the maximum in any
    #   month), and 1 year is approximated as 366 days (the maximum in any
    #   year).
    NORMALIZATION_METHODS = {
      standard: {
        months: {seconds: 30 * 24 * 60 * 60},
        years: {seconds: 365 * 24 * 60 * 60}
      },
      minimum: {
        months: {seconds: 28 * 24 * 60 * 60},
        years: {seconds: 365 * 24 * 60 * 60}
      },
      maximum: {
        months: {seconds: 31 * 24 * 60 * 60},
        years: {seconds: 366 * 24 * 60 * 60}
      }
    }

    # The built-in formats that can be used with {#to_s}.
    #
    # The following string formats are defined:
    #
    # - `:long`: The default, long-form string format. Example string:
    #   `"1 year, 2 months, 3 weeks, 4 days, 5 hours"`.
    # - `:short`: A shorter format, which includes 2 significant units by
    #   default. Example string: `"1mo 2d"`
    # - `:micro`: A very terse format, which includes only one significant unit
    #   by default. Example string: `"1h"`
    FORMATS = {
      micro: {
        units: {
          seconds: 's',
          minutes: 'm',
          hours: 'h',
          days: 'd',
          weeks: 'w',
          months: 'mo',
          years: 'y',
        },
        separator: '',
        delimiter: ' ',
        count: 1
      },
      short: {
        units: {
          seconds: 'sec',
          minutes: 'min',
          hours: 'hr',
          days: 'd',
          weeks: 'wk',
          months: 'mo',
          years: 'yr'
        },
        separator: '',
        delimiter: ' ',
        count: 2
      },
      long: {
        units: {
          seconds: ['second', 'seconds'],
          minutes: ['minute', 'minutes'],
          hours: ['hour', 'hours'],
          days: ['day', 'days'],
          weeks: ['week', 'weeks'],
          months: ['month', 'months'],
          years: ['year', 'years']
        }
      },
      min_long: {
        units: {
          seconds: ['second', 'seconds'],
          minutes: ['minute', 'minutes'],
          hours: ['hour', 'hours'],
          days: ['day', 'days'],
          months: ['month', 'months'],
          years: ['year', 'years']
        },
        count: 2
      }
    }

    # Initialize a new instance of {Duration}.
    #
    # @param [Hash<Symbol, Integer>] units A hash that maps from unit names
    #   to the quantity of that unit. See the keys of {UNIT_ALIASES} for
    #   a list of valid unit names.
    #
    # @example
    #   Timerizer::Duration.new(years: 4, months: 2, hours: 12, minutes: 60)
    def initialize(units = {})
      @seconds = 0
      @months = 0

      units.each do |unit, n|
        unit_info = self.class.resolve_unit(unit)
        @seconds += n * unit_info.fetch(:seconds, 0)
        @months += n * unit_info.fetch(:months, 0)
      end
    end

    # Return the number of "base" units in a {Duration}. Note that this method
    # is a lower-level method, and will not be needed by most users. See
    # {#to_unit} for a more general equivalent.
    #
    # @param [Symbol] unit The base unit to return, either
    #   `:seconds` or `:months`.
    #
    # @return [Integer] The requested unit count. Note that this method does
    #   not perform normalization first, so results may not be intuitive.
    #
    # @raise [ArgumentError] The unit requested was not `:seconds` or `:months`.
    #
    # @see #to_unit
    def get(unit)
      if unit == :seconds
        @seconds
      elsif unit == :months
        @months
      else
        raise ArgumentError
      end
    end

    # Returns the time `self` earlier than the given time.
    #
    # @param [Time] time The initial time.
    # @return [Time] The time before this {Duration} has elapsed past the
    #   given time.
    #
    # @example 5 minutes before January 1st, 2000 at noon
    #   5.minutes.before(Time.new(2000, 1, 1, 12, 00, 00))
    #   # => 2000-01-01 11:55:00 -0800
    #
    # @see #ago
    # @see #after
    # @see #from_now
    def before(time)
      (-self).after(time)
    end

    # Return the time `self` later than the current time.
    #
    # @return [Time] The time after this {Duration} has elapsed past the
    #   current system time.
    #
    # @see #before
    def ago
      self.before(Time.now)
    end

    # Returns the time `self` later than the given time.
    #
    # @param [Time] time The initial time.
    # @return [Time] The time after this {Duration} has elapsed past the
    #   given time.
    #
    # @example 5 minutes after January 1st, 2000 at noon
    #   5.minutes.after(Time.new(2000, 1, 1, 12, 00, 00))
    #   # => 2000-01-01 12:05:00 -0800
    #
    # @see #ago
    # @see #before
    # @see #from_now
    def after(time)
      time = time.to_time

      prev_day = time.mday
      prev_month = time.month
      prev_year = time.year

      units = self.to_units(:years, :months, :days, :seconds)

      date_in_month = self.class.build_date(
        prev_year + units[:years],
        prev_month + units[:months],
        prev_day
      )
      date = date_in_month + units[:days]

      Time.new(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.min,
        time.sec
      ) + units[:seconds]
    end

    # Return the time `self` earlier than the current time.
    #
    # @return [Time] The time current system time before this {Duration}.
    #
    # @see #before
    def from_now
      self.after(Time.now)
    end

    # Convert the duration to a given unit.
    #
    # @param [Symbol] unit The unit to convert to. See {UNIT_ALIASES} for a list
    #   of valid unit names.
    #
    # @return [Integer] The quantity of the given unit present in `self`. Note
    #   that, if `self` cannot be represented exactly by `unit`, then the result
    #   will be truncated (rounded toward 0 instead of rounding down, unlike
    #   normal Ruby integer division).
    #
    # @raise ArgumentError if the given unit could not be resolved.
    #
    # @example
    #   1.hour.to_unit(:minutes)
    #   # => 60
    #   121.seconds.to_unit(:minutes)
    #   # => 2
    #
    # @note The duration is normalized or denormalized first, depending on the
    #   unit requested. This means that, by default, the returned unit will
    #   be an approximation if it cannot be represented exactly by the duration,
    #   such as when converting a duration of months to seconds, or vice versa.
    #
    # @see #to_units
    def to_unit(unit)
      unit_details = self.class.resolve_unit(unit)

      if unit_details.has_key?(:seconds)
        seconds = self.normalize.get(:seconds)
        self.class.div(seconds, unit_details.fetch(:seconds))
      elsif unit_details.has_key?(:months)
        months = self.denormalize.get(:months)
        self.class.div(months, unit_details.fetch(:months))
      else
        raise "Unit should have key :seconds or :months"
      end
    end

    # Convert the duration to a hash of units. For each given unit argument,
    # the returned hash will map the unit to the quantity of that unit present
    # in the duration. Each returned unit will be truncated to an integer, and
    # the remainder will "carry" to the next unit down. The resulting hash can
    # be passed to {Duration#initialize} to get the same result, so this method
    # can be thought of as the inverse of {Duration#initialize}.
    #
    # @param [Array<Symbol>] units The units to convert to. Each unit
    #   will correspond with a key in the returned hash.
    #
    # @return [Hash<Symbol, Integer>] A hash mapping each unit to the quantity
    #   of that unit. Note that whether the returned unit is plural, or uses
    #   an alias, depends on what unit was passed in as an argument.
    #
    # @note The duration may be normalized or denormalized first, depending
    #   on the units requested. This behavior is identical to {#to_unit}.
    #
    # @example
    #   121.seconds.to_units(:minutes)
    #   # => {minutes: 2}
    #   121.seconds.to_units(:minutes, :seconds)
    #   # => {minutes: 2, seconds: 1}
    #   1.year.to_units(:days)
    #   # => {days: 365}
    #   (91.days 12.hours).to_units(:months, :hours)
    #   # => {months: 3, hours: 36}
    def to_units(*units)
      sorted_units = self.class.sort_units(units).reverse

      _, parts = sorted_units.reduce([self, {}]) do |(remainder, parts), unit|
        part = remainder.to_unit(unit)
        new_remainder = remainder - Duration.new(unit => part)

        [new_remainder, parts.merge(unit => part)]
      end

      parts
    end

    # Return a new duration that approximates the given input duration, where
    # every "month-based" unit of the input is converted to seconds. Because
    # durations are composed of two distinct units ("seconds" and "months"),
    # two durations need to be normalized before being compared. By default,
    # most methods on {Duration} perform normalization or denormalization, so
    # clients will not usually need to call this method directly.
    #
    # @param [Symbol] method The normalization method to be used. For a list
    #   of normalization methods, see {NORMALIZATION_METHODS}.
    #
    # @return [Duration] The duration after being normalized.
    #
    # @example
    #   1.month.normalize == 30.days
    #   1.month.normalize(method: :standard) == 30.days
    #   1.month.normalize(method: :maximum) == 31.days
    #   1.month.normalize(method: :minimum) == 28.days
    #
    #   1.year.normalize == 365.days
    #   1.year.normalize(method: :standard) == 365.days
    #   1.year.normalize(method: :minimum) == 365.days
    #   1.year.normalize(method: :maximum) == 366.days
    #
    # @see #denormalize
    def normalize(method: :standard)
      normalized_units = NORMALIZATION_METHODS.fetch(method).reverse_each

      initial = [0.seconds, self]
      result = normalized_units.reduce(initial) do |result, (unit, normal)|
        normalized, remainder = result

        seconds_per_unit = normal.fetch(:seconds)
        unit_part = remainder.send(:to_unit_part, unit)

        normalized += (unit_part * seconds_per_unit).seconds
        remainder -= Duration.new(unit => unit_part)
        [normalized, remainder]
      end

      normalized, remainder = result
      normalized + remainder
    end

    # Return a new duration that inverts an approximation made by {#normalize}.
    # Denormalization results in a {Duration} where "second-based" units are
    # converted back to "month-based" units. Note that, due to the lossy nature
    # {#normalize}, the result of calling {#normalize} then {#denormalize} may
    # result in a {Duration} that is _not_ equal to the input.
    #
    # @param [Symbol] method The normalization method to invert. For a list of
    #   normalization methods, see {NORMALIZATION_METHODS}.
    #
    # @return [Duration] The duration after being denormalized.
    #
    # @example
    #   30.days.denormalize == 1.month
    #   30.days.denormalize(method: :standard) == 1.month
    #   28.days.denormalize(method: :minimum) == 1.month
    #   31.days.denormalize(method: :maximum) == 1.month
    #
    #   365.days.denormalize == 1.year
    #   365.days.denormalize(method: :standard) == 1.year
    #   365.days.denormalize(method: :minimum) == 1.year
    #   366.days.denormalize(method: :maximum) == 1.year
    def denormalize(method: :standard)
      normalized_units = NORMALIZATION_METHODS.fetch(method).reverse_each

      initial = [0.seconds, self]
      result = normalized_units.reduce(initial) do |result, (unit, normal)|
        denormalized, remainder = result

        seconds_per_unit = normal.fetch(:seconds)
        remainder_seconds = remainder.get(:seconds)

        num_unit = self.class.div(remainder_seconds, seconds_per_unit)
        num_seconds_denormalized = num_unit * seconds_per_unit

        denormalized += Duration.new(unit => num_unit)
        remainder -= num_seconds_denormalized.seconds

        [denormalized, remainder]
      end

      denormalized, remainder = result
      denormalized + remainder
    end

    # Compare two duartions. Note that durations are compared after
    # normalization.
    #
    # @param [Duration] other The duration to compare.
    #
    # @return [Integer, nil] 0 if the durations are equal, -1 if the left-hand
    #   side is greater, +1 if the right-hand side is greater. Returns `nil` if
    #   the duration cannot be compared ot `other`.
    def <=>(other)
      case other
      when Duration
        self.to_unit(:seconds) <=> other.to_unit(:seconds)
      else
        nil
      end
    end

    # Negates a duration.
    #
    # @return [Duration] A new duration where each component was negated.
    def -@
      Duration.new(seconds: -@seconds, months: -@months)
    end

    # @overload +(duration)
    #   Add together two durations.
    #
    #   @param [Duration] duration The duration to add.
    #
    #   @return [Duration] The resulting duration with each component added
    #     to the input duration.
    #
    #   @example
    #     1.day + 1.hour == 25.hours
    #
    # @overload +(time)
    #   Add a time to a duration, returning a new time.
    #
    #   @param [Time] time The time to add this duration to.
    #
    #   @return [Time] The time after the duration has elapsed.
    #
    #   @example
    #     1.day + Time.new(2000, 1, 1) == Time.new(2000, 1, 2)
    #
    #   @see #after
    def +(other)
      case other
      when 0
        self
      when Duration
        Duration.new(
          seconds: @seconds + other.get(:seconds),
          months: @months + other.get(:months)
        )
      when Time
        self.after(other)
      else
        raise ArgumentError, "Cannot add #{other.inspect} to Duration #{self}"
      end
    end

    # Subtract two durations.
    #
    # @param [Duration] other The duration to subtract.
    #
    # @return [Duration] The resulting duration with each component subtracted
    #   from the input duration.
    #
    # @example
    #   1.day - 1.hour == 23.hours
    def -(other)
      case other
      when 0
        self
      when Duration
        Duration.new(
          seconds: @seconds - other.get(:seconds),
          months: @months - other.get(:months)
        )
      else
        raise ArgumentError, "Cannot subtract #{other.inspect} from Duration #{self}"
      end
    end

    # Multiply a duration by a scalar.
    #
    # @param [Integer] other The scalar to multiply by.
    #
    # @return [Duration] The resulting duration with each component multiplied
    #   by the scalar.
    #
    # @example
    #   1.day * 7 == 1.week
    def *(other)
      case other
      when Integer
        Duration.new(
          seconds: @seconds * other,
          months: @months * other
        )
      else
        raise ArgumentError, "Cannot multiply Duration #{self} by #{other.inspect}"
      end
    end

    # Divide a duration by a scalar.
    #
    # @param [Integer] other The scalar to divide by.
    #
    # @return [Duration] The resulting duration with each component divided by
    #   the scalar.
    #
    # @note A duration can only be divided by an integer divisor. The resulting
    #   duration will have each component divided with integer division, which
    #   will result in truncation.
    #
    # @example
    #   1.week / 7 == 1.day
    #   1.second / 2 == 0.seconds # This is a result of truncation
    def /(other)
      case other
      when Integer
        Duration.new(
          seconds: @seconds / other,
          months: @months / other
        )
      else
        raise ArgumentError, "Cannot divide Duration #{self} by #{other.inspect}"
      end
    end

    # Convert a duration to a {WallClock}.
    #
    # @return [WallClock] `self` as a {WallClock}
    #
    # @example
    #   (17.hours 30.minutes).to_wall
    #   # => 5:30:00 PM
    def to_wall
      raise WallClock::TimeOutOfBoundsError if @months > 0
      WallClock.new(second: @seconds)
    end

    # Convert a duration to a human-readable string.
    #
    # @param [Symbol, Hash] format The format type to format the duration with.
    #   `format` can either be a key from the {FORMATS} hash or a hash with
    #   the same shape as `options`.
    # @param [Hash, nil] options Additional options to use to override default
    #   format options.
    #
    # @option options [Hash<Symbol, String>] :units The full list of unit names
    #   to use. Keys are unit names (see {UNIT_ALIASES} for a full list) and
    #   values are strings to use when converting that unit to a string. Values
    #   can also be an array, where the first item of the array will be used
    #   for singular unit names and the second item will be used for plural
    #   unit names. Note that this option will completely override the input
    #   formats' list of names, so all units that should be used must be
    #   specified!
    # @option options [String] :separator The separator to use between a unit
    #   quantity and the unit's name. For example, the string `"1 second"` uses
    #   a separator of `" "`.
    # @option options [String] :delimiter The delimiter to use between separate
    #   units. For example, the string `"1 minute, 1 second"` uses a separator
    #   of `", "`
    # @option options [Integer, nil, :all] :count The number of significant
    #   units to use in the string, or `nil` / `:all` to use all units.
    #   For example, if the given duration is `1.day 1.week 1.month`, and
    #   `options[:count]` is 2, then the resulting string will only include
    #   the month and the week components of the string.
    #
    # @return [String] The duration formatted as a string.
    def to_s(format = :long, options = nil)
      format =
        case format
        when Symbol
          FORMATS.fetch(format)
        when Hash
          FORMATS.fetch(:long).merge(format)
        else
          raise ArgumentError, "Expected #{format.inspect} to be a Symbol or Hash"
        end

      format = format.merge(options || {})

      count =
        if format[:count].nil? || format[:count] == :all
          UNITS.count
        else
          format[:count]
        end

      format_units = format.fetch(:units)
      units = self.to_units(*format_units.keys).select {|unit, n| n > 0}
      if units.empty?
        units = {seconds: 0}
      end

      separator = format[:separator] || ' '
      delimiter = format[:delimiter] || ', '
      units.take(count).map do |unit, n|
        unit_label = format_units.fetch(unit)

        singular, plural =
          case unit_label
          when Array
            unit_label
          else
            [unit_label, unit_label]
          end

          unit_name =
            if n == 1
              singular
            else
              plural || singular
            end

          [n, unit_name].join(separator)
      end.join(format[:delimiter] || ', ')
    end

    # Convert a Duration to a human-readable string using a rounded value.
    #
    # By 'rounded', we mean that the resulting value is rounded up if the input
    # includes a value of more than half of one of the least-significant unit to
    # be returned. For example, `(17.hours 43.minutes 31.seconds)`, when rounded
    # to two units (hours and minutes), would return "17 hours, 44 minutes". By
    # contrast, `#to_s`, with a `:count` option of 2, would return a value of
    # "17 hours, 43 minutes": truncating, rather than rounding.
    #
    # Note that this method overloads the meaning of the `:count` option value
    # as documented below. If the passed-in option value is numeric, it will be
    # honored, and rounding will take place to that number of units. If the
    # value is either `:all` or the default `nil`, then _rounding_ will be done
    # to two units, and the rounded value will be passed on to `#to_s` with the
    # options specified (which will result in a maximum of two time units being
    # output).
    #
    # @param [Symbol, Hash] format The format type to format the duration with.
    #   `format` can either be a key from the {FORMATS} hash or a hash with
    #   the same shape as `options`. The default is `:min_long`, which strongly
    #   resembles `:long` with the omission of `:weeks` units and a default
    #   `:count` of 2.
    # @param [Hash, nil] options Additional options to use to override default
    #   format options.
    #
    # @option options [Hash<Symbol, String>] :units The full list of unit names
    #   to use. Keys are unit names (see {UNIT_ALIASES} for a full list) and
    #   values are strings to use when converting that unit to a string. Values
    #   can also be an array, where the first item of the array will be used
    #   for singular unit names and the second item will be used for plural
    #   unit names. Note that this option will completely override the input
    #   formats' list of names, so all units that should be used must be
    #   specified!
    # @option options [String] :separator The separator to use between a unit
    #   quantity and the unit's name. For example, the string `"1 second"` uses
    #   a separator of `" "`.
    # @option options [String] :delimiter The delimiter to use between separate
    #   units. For example, the string `"1 minute, 1 second"` uses a separator
    #   of `", "`
    # @option options [Integer, nil, :all] :count The number of significant
    #   units to use in the string, or `nil` / `:all` to use all units.
    #   For example, if the given duration is `1.day 1.week 1.month`, and
    #   `options[:count]` is 2, then the resulting string will only include
    #   the month and the week components of the string.
    #
    # @return [String] The rounded duration formatted as a string.
    def to_rounded_s(format = :min_long, options = nil)
      format =
      case format
      when Symbol
        FORMATS.fetch(format)
      when Hash
        FORMATS.fetch(:long).merge(format)
      else
        raise ArgumentError, "Expected #{format.inspect} to be a Symbol or Hash"
      end

      format = format.merge(Hash(options))
      places = format[:count]
      begin
        places = Integer(places) # raise if nil or `:all` supplied as value
      rescue TypeError
        places = 2
      end
      q = RoundedTime.call(self, places)
      q.to_s(format, options)
    end

    private

    # This method is like {#to_unit}, except it does not perform normalization
    # first. Put another way, this method is essentially the same as {#to_unit}
    # except it does not normalize the value first. It is similar to {#get}
    # except that it can be used with non-primitive units as well.
    #
    # @example
    #   (1.year 1.month 365.days).to_unit_part(:month)
    #   # => 13
    #   # Returns 13 because that is the number of months contained exactly
    #   # within the sepcified duration. Since "days" cannot be translated
    #   # to an exact number of months, they *are not* factored into the result
    #   # at all.
    #
    # (25.months).to_unit_part(:year)
    #   # => 2
    #   # Returns 2 becasue that is the number of months contained exactly
    #   # within the specified duration. Since "years" is essentially an alias
    #   # for "12 months", months *are* factored into the result.
    def to_unit_part(unit)
      unit_details = self.class.resolve_unit(unit)

      if unit_details.has_key?(:seconds)
        seconds = self.get(:seconds)
        self.class.div(seconds, unit_details.fetch(:seconds))
      elsif unit_details.has_key?(:months)
        months = self.get(:months)
        self.class.div(months, unit_details.fetch(:months))
      else
        raise "Unit should have key :seconds or :months"
      end
    end

    def self.resolve_unit(unit)
      UNIT_ALIASES[unit] or raise ArgumentError, "Unknown unit: #{unit.inspect}"
    end

    def self.sort_units(units)
      units.sort_by do |unit|
        unit_info = self.resolve_unit(unit)
        [unit_info.fetch(:months, 0), unit_info.fetch(:seconds, 0)]
      end
    end

    def self.mod_div(x, divisor)
      modulo = x % divisor
      [modulo, (x - modulo).to_i / divisor]
    end

    # Like the normal Ruby division operator, except it rounds towards 0 when
    # dividing `Integer`s (instead of rounding down).
    def self.div(x, divisor)
      (x.to_f / divisor).to_i
    end

    def self.month_carry(month)
      month_offset, year_carry = self.mod_div(month - 1, 12)
      [month_offset + 1, year_carry]
    end

    # Create a date from a given year, month, and date. If the month is not in
    # the range `1..12`, then the month will "wrap around", adjusting the given
    # year accordingly (so a year of 2017 and a month of 0 corresponds with
    # 12/2016, a year of 2017 and a month of 13 correpsonds with 1/2018, and so
    # on). If the given day is out of range of the given month, then the
    # date will be nudged back to the last day of the month.
    def self.build_date(year, month, day)
      new_month, year_carry = self.month_carry(month)
      new_year = year + year_carry

      if Date.valid_date?(new_year, new_month, day)
        Date.new(new_year, new_month, day)
      else
        Date.new(new_year, new_month, -1)
      end
    end

    # @!macro [attach] define_to_unit
    #   @method to_$1
    #
    #   Convert the duration to the given unit. This is a helper that
    #   is equivalent to calling {#to_unit} with `:$1`.
    #
    #   @return [Integer] the quantity of the unit in the duration.
    #
    #   @see #to_unit
    def self.define_to_unit(unit)
      define_method("to_#{unit}") do
        self.to_unit(unit)
      end
    end

    public

    # NOTE: We need to manually spell out each unit with `define_to_unit` to
    # get proper documentation for each method. To ensure that we don't miss
    # any units, there's a test in `duration_spec.rb` to ensure each of these
    # methods actually exist.

    self.define_to_unit(:seconds)
    self.define_to_unit(:minutes)
    self.define_to_unit(:hours)
    self.define_to_unit(:days)
    self.define_to_unit(:weeks)
    self.define_to_unit(:months)
    self.define_to_unit(:years)
    self.define_to_unit(:decades)
    self.define_to_unit(:centuries)
    self.define_to_unit(:millennia)
    self.define_to_unit(:second)
    self.define_to_unit(:minute)
    self.define_to_unit(:hour)
    self.define_to_unit(:day)
    self.define_to_unit(:week)
    self.define_to_unit(:month)
    self.define_to_unit(:year)
    self.define_to_unit(:decade)
    self.define_to_unit(:century)
    self.define_to_unit(:millennium)
  end
end

require_relative './duration/rounded_time'
