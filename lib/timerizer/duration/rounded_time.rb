# frozen_string_literal: true
require 'forwardable'

module Timerizer
  class Duration
    # Wraps rounding a {Timerizer::Duration} to the nearest value by the number
    # of "places", which are customary time units (seconds, minutes, hours,
    # days, months, years, etc; decades and weeks are not included).
    #
    # @private
    class RoundedTime
      extend Forwardable

      # @!method remainder_times
      #   @return (see TermTimes#remainder_times)
      # @!method target_unit
      #   @return (see TermTimes#target_unit)
      # @!method times
      #   @return (see TermTimes#times)
      def_delegators :@tt, :remainder_times, :target_unit, :times

      # Default "places" (units, e.g., hours/minutes) to use for rounding.
      DEFAULT_PLACES = 2
      # Default {Timerizer::Duration::UNITS} *not* to include in rounded value.
      OMITTED_KEYS = [:decades, :weeks]

      # Given an original {Timerizer::Duration} instance, return a new instance
      # that "rounds" the duration to the closest value expressed in a certain
      # number of units (default 2).
      #
      # @param [{Timerizer::Duration}] duration Object encapsulating a duration
      #                     (in hours, minutes, etc) to "round" to a number of
      #                     units specified by `places`.
      # @param [Integer] places Number of units to include in rounded value.
      #                     Default is 2.
      # @param [Array<Symbol>] omitted_keys Units to omit from calculation or
      #                     return value. Default is `[:decades, :weeks]`
      # @return {Timerizer::Duration}
      # @example
      #   t = (12.hours 16.minutes 47.seconds).ago
      #   d = Time.since(t)
      #   d2 = RoundedTime.call(d)
      #   d.to_s  # => "12 hours, 16 minutes, 47 seconds"
      #   d2.to_s # => "12 hours, 17 minutes"
      #
      def self.call(duration, places = DEFAULT_PLACES,
                    omitted_keys = OMITTED_KEYS)
        new(duration, places, omitted_keys).call
      end

      # High-level method to do calculations on component durations.
      #
      # @return {Timerizer::Duration}
      #
      def call
        remainder = sum_of(remainder_times)
        sum_of(times) + offset_from(remainder)
      end

      private

      # Initial value for adding a collection of Duration instances.
      # (see #sum_of)
      ZERO_TIME = Timerizer::Duration.new(seconds: 0)
      private_constant :ZERO_TIME

      # Private initialiser to prevent direct instantiation by client code.
      #
      # @param [{Timerizer::Duration}] duration Object encapsulating a duration
      #                     (in hours, minutes, etc) to "round" to a number of
      #                     units specified by `places`.
      # @param [Integer] places Number of units to include in rounded value.
      #                     Default is 2.
      # @param [Array<Symbol>] omitted_keys Units to omit from calculation or
      #                     return value. Default is `[:decades, :weeks]`
      #
      def initialize(duration, places = DEFAULT_PLACES,
                     omitted_keys = OMITTED_KEYS)
        @tt = TermTimes.new(duration, omitted_keys).call(places).freeze
      end

      # Determine whether returned {Timerizer::Duration} value should be rounded
      # up or down based on a remainder value.
      #
      # If the remainder value is more than half of the {#target_unit}, then
      # this will return a duration of 1 times the target unit, else a duration
      # of {ZERO_TIME}.
      #
      # @return [{Timerizer::Duration}] Either zero or 1 times the `target_unit`
      # @param [{Timerizer::Duration}] remainder Value of input duration less
      #                     than one `target_unit`
      def offset_from(remainder)
        Timerizer::Duration.new((remainder * 2).to_units(target_unit))
      end

      # Add all time (Duration) values in an Array (or other Enumerable).
      #
      # @return [{Timerizer::Duration}] Sum total of input values.
      # @param [Array<{Timerizer::Duration}>] Unit values to add together
      #
      def sum_of(time_values)
        time_values.inject(ZERO_TIME, :+)
      end

      # Convert a single {Timerizer::Duration} instance into an enumeration of
      # per-unit Duration instances (hours, minutes, etc).
      #
      # @private
      class TermTimes
        # Least-significant time unit (e.g., ``:days`) used for rounding.
        # @return [Symbol] Least-significant time unit in the resulting value.
        attr_reader :target_unit
        # Time units to be included in "rounded" result, before rounding.
        # @return [Array<{Timerizer::Duration}>] Base result time-unit values.
        attr_reader :times
        # Time units to be "rounded" to adjust resulting Duration value.
        # @return [Array<{Timerizer::Duration}>] Remaining time-unit values.
        attr_reader :remainder_times

        # Build array of time-part values based on input {Timerizer::Duration}.
        #
        # @param [{Timerizer::Duration}] duration Time differential used as
        #                     input.
        # @param [Array<Symbol>] omitted_keys {Timerizer::Duration::UNITS}
        #                     values to exclude from resulting value.
        #
        def initialize(duration, omitted_keys)
          @part_values = filter_units(duration, omitted_keys)
        end

        # Compute per-unit {Timerizer::Duration} values, split based on unit
        # count
        #
        # @param [Integer] places Number of time units to include in main Array.
        def call(places)
          # Note that `places` may exceed the number of actual units in the
          # value. For example, with a duration of `(10.days)` and a `places`
          # value of 2. Adjust as needed.
          places = @part_values.count - 1 if @part_values.count < places
          # If a zero-time `duration` is passed in, then @part_values will be
          # empty, and the key arithmetic will return `nil`. Adjust as needed.
          @target_unit = @part_values.keys[places - 1] || :seconds
          term_times = unit_times
          @times = term_times[0..places - 1]
          @remainder_times = term_times[@times.count..-1]
          self
        end

        private

        def filter_units(duration, omitted_keys)
          unit_keys = Timerizer::Duration::UNITS.keys - omitted_keys
          duration.to_units(*unit_keys).reject { |_, v| v.zero? }
        end

        def unit_times
          @part_values.map { |unit, val| Timerizer::Duration.new(unit => val) }
        end
      end # class RoundedTime::TermTimes
      private_constant :TermTimes
    end # class RoundedTime
  end
end
