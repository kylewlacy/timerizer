module Timerizer
  # Represents a time, but not a date. '7:00 PM' would be an example of a WallClock object
  class WallClock
    # Represents an error where an invalid meridiem was passed to WallClock.
    # @see #new
    class InvalidMeridiemError < ArgumentError; end
    # Represents an error where a time beyond 24 hours was passed to WallClock.
    # @see #new
    class TimeOutOfBoundsError < ArgumentError; end

    # Initialize a new instance of WallClock
    # @overload new(hash)
    #   @param [Hash] units The units to initialize with
    #   @option units [Integer] :hour The hour to initialize with
    #   @option units [Integer] :minute The minute to initialize with
    #   @option units [Integer] :second The second to initialize with
    # @overload new(hour, minute, meridiem)
    #   @param [Integer] hour The hour to initialize with
    #   @param [Integer] minute The minute to initialize with
    #   @param [Symbol] meridiem The meridiem to initialize with (`:am` or `:pm`)
    # @overload new(hour, minute, second, meridiem)
    #   @param [Integer] hour The hour to initialize with
    #   @param [Integer] minute The minute to initialize with
    #   @param [Integer] second The second to initialize with
    #   @param [Symbol] meridiem The meridiem to initialize with (`:am` or `:pm`)
    # @overload new(seconds)
    #   @param [Integer] seconds The number of seconds to initialize with (for use with #to_i)
    # @raise InvalidMeridiemError Meridiem is not `:am` or `:pm`
    def initialize(hour = nil, minute = nil, second = 0, meridiem = :am)
      units = nil
      if hour.is_a?(Integer) && minute.nil?
        units = {second: hour}
      elsif hour.is_a?(Hash)
        units = hour
      end

      if !units.nil?
        second = units[:second] || 0
        minute = units[:minute] || 0
        hour = units[:hour] || 0
      else
        if second.is_a?(String) || second.is_a?(Symbol)
          meridiem = second
          second = 0
        end

        meridiem = meridiem.downcase.to_sym
        if !(meridiem == :am || meridiem == :pm)
          raise InvalidMeridiemError
        elsif meridiem == :pm && hour > 12
          raise TimeOutOfBoundsError, "hour must be <= 12 for PM"
        elsif hour >= 24 || minute >= 60 || second >= 60
          raise TimeOutOfBoundsError
        end

        hour += 12 if (meridiem == :pm and !(hour == 12))
      end

      @seconds =
        Duration.new(hour: hour, minute: minute, second: second).to_seconds

      if @seconds >= 1.day.to_seconds
        raise TimeOutOfBoundsError
      end
    end

    # Takes a string and turns it into a WallClock time
    # @param [String] string The string to convert
    # @return [WallClock] The time as a WallClock
    # @example
    #   WallClock.from_string("10:30 PM")
    #     # => 10:30:00 PM
    #   WallClock.from_string("13:01:23")
    #     # => 1:01:23 PM
    # @see #to_s
    def self.from_string(string)
      time, meridiem = string.split(' ', 2)
      hour, minute, second = time.split(':', 3)
      WallClock.new(hour.to_i, minute.to_i, second.to_i || 0, meridiem || :am)
    end

    # Returns the time of the WallClock on a date
    # @param [Date] date The date to apply the time on
    # @return [Time] The time after the given date
    # @example yesterday at 5:00
    #   time = WallClock.new(5, 00, :pm)
    #   time.on(Date.yesterday)
    #     => 2000-1-1 17:00:00 -0800
    def on(date)
      date.to_date.to_time + @seconds
    end

    # Comparse two {WallClock}s.
    # @return [Boolean] True if the WallClocks are identical
    def ==(time)
      if time.is_a? WallClock
        self.in_seconds == time.in_seconds
      else
        false
      end
    end

    # Get the time of the WallClock, in seconds
    # @return [Integer] The total time of the WallClock, in seconds
    def in_seconds
      @seconds
    end

    # Get the time of the WallClock, in minutes
    # @return [Integer] The total time of the WallClock, in minutes
    def in_minutes
      Duration::new(seconds: @seconds).to_minutes
    end

    # Get the time of the WallClock, in hours
    # @return [Integer] The total time of the WallClock, in hours
    def in_hours
      Duration::new(seconds: @seconds).to_hours
    end

    # Get the second of the WallClock.
    # @return [Integer] The second component of the WallClock
    def second
      self.to_duration.to_units(:hour, :minute, :second).fetch(:second)
    end

    # Get the minute of the WallClock.
    # @return [Integer] The minute component of the WallClock
    def minute
      self.to_duration.to_units(:hour, :minute, :second).fetch(:minute)
    end

    # Get the hour of the WallClock.
    # @param [Symbol] system The houring system to use (either `:twelve_hour` or `:twenty_four_hour`; default `:twenty_four_hour`)
    # @return [Integer] The hour component of the WallClock
    def hour(system = :twenty_four_hour)
      hour = self.to_duration.to_units(:hour, :minute, :second).fetch(:hour)
      if system == :twelve_hour
        if hour == 0
          12
        elsif hour > 12
          hour - 12
        else
          hour
        end
      elsif (system == :twenty_four_hour)
        hour
      else
        raise ArgumentError, "system should be :twelve_hour or :twenty_four_hour"
      end
    end

    # Get the meridiem of the WallClock.
    # @return [Symbol] The meridiem (either `:am` or `:pm`)
    def meridiem
      if self.hour > 12 || self.hour == 0
        :pm
      else
        :am
      end
    end

    # Converts self to {WallClock}
    # @see Time#to_wall
    def to_wall
      self
    end

    # Converts `self` to a {Duration}
    # @return [Duration] `self` as a {Duration}
    # @example
    #   time = WallClock.new(5, 30, :pm)
    #   time.to_duration
    #     => 5 hours, 30 minutes
    def to_duration
      @seconds.seconds
    end

    # Get the time of the WallClock in a more portable format (for a database, for example)
    # @see #in_seconds
    def to_i
      self.in_seconds
    end

    # Convert {WallClock} to a human-readable format.
    # @param [Symbol] system The hour system to use (`:twelve_hour` or `:twenty_four_hour`; default `:twelve_hour`)
    # @param [Hash] options Extra options for the string to use
    # @option options [Boolean] :use_seconds Whether or not to include seconds in the conversion to a string
    # @option options [Boolean] :include_meridian Whether or not to include the meridian for a twelve-hour time
    # @example
    #   time = WallClock.new(5, 37, 41, :pm)
    #   time.to_s
    #     => "5:37:41 PM"
    #   time.to_s(:twenty_four_hour, :use_seconds => true)
    #     => "17:37:41"
    #   time.to_s(:twelve_hour, :use_seconds => false, :include_meridiem => false)
    #     => "5:37"
    #   time.to_s(:twenty_four_hour, :use_seconds =>false)
    #     => "17:37"
    # @raise ArgumentError Argument isn't a proper system
    def to_s(system = :twelve_hour, options = {})
      options  = {use_seconds: true, include_meridiem: true}.merge(options)
      pad = "%02d"
      meridiem = self.meridiem.to_s.upcase
      hour = self.hour(system)
      minute = pad % self.minute
      second = pad % self.second

      string = [hour, minute].join(':')
      if options[:use_seconds]
        string = [string, second].join(':')
      end

      case system
      when :twelve_hour
        options[:include_meridiem] ? [string, meridiem].join(' ') : string
      when :twenty_four_hour
        string
      else
        raise ArgumentError, "system should be :twelve_hour or :twenty_four_hour"
      end
    end
  end
end
