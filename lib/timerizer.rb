require 'date'

# Represents a relative amount of time. For example, '`5 days`', '`4 years`', and '`5 years, 4 hours, 3 minutes, 2 seconds`' are all RelativeTimes.
class RelativeTime
  @@units = {
    :second     => :seconds,
    :minute     => :minutes,
    :hour       => :hours,
    :day        => :days,
    :week       => :weeks,
    :month      => :months,
    :year       => :years,
    :decade     => :decades,
    :century    => :centuries,
    :millennium => :millennia
  }

  @@in_seconds = {
      :second => 1,
      :minute => 60,
      :hour   => 3600,
      :day    => 86400,
      :week   => 604800
  }

  @@in_months = {
    :month      => 1,
    :year       => 12,
    :decade     => 120,
    :century    => 1200,
    :millennium => 12000
  }

  # Average amount of time in a given unit. Used internally within the {#average} and {#unaverage} methods.
  @@average_seconds = {
    :month => 2629746,
    :year  => 31556952
  }

  # Default syntax formats that can be used with #to_s
  # @see #to_s
  @@syntaxes = {
    :micro => {
      :units => {
        :seconds => 's',
        :minutes => 'm',
        :hours => 'h',
        :days => 'd',
        :weeks => 'w',
        :months => 'mn',
        :years => 'y',
      },
      :separator => '',
      :delimiter => ' ',
      :count => 1
    },
    :short => {
      :units => {
        :seconds => 'sec',
        :minutes => 'min',
        :hours => 'hr',
        :days => 'd',
        :weeks => 'wk',
        :months => 'mn',
        :years => 'yr',
        :centuries => 'ct',
        :millenia => 'ml'
      },
      :separator => '',
      :delimiter => ' ',
      :count => 2
    },
    :long => {
      :units => {
        :seconds => ['second', 'seconds'],
        :minutes => ['minute', 'minutes'],
        :hours => ['hour', 'hours'],
        :days => ['day', 'days'],
        :weeks => ['week', 'weeks'],
        :months => ['month', 'months'],
        :years => ['year', 'years'],
        :centuries => ['century', 'centuries'],
        :millennia => ['millenium', 'millenia'],
      }
    }
  }

  # All potential units. Key is the unit name, and the value is its plural form.
  def self.units
    @@units
  end

  # Unit values in seconds. If a unit is not present in this hash, it is assumed to be in the {@@in_months} hash.
  def self.units_in_seconds
    @@in_seconds
  end

  # Unit values in months. If a unit is not present in this hash, it is assumed to be in the {@@in_seconds} hash.
  def self.units_in_months
    @@in_months
  end

  # Initialize a new instance of RelativeTime.
  # @overload new(hash)
  #   @param [Hash] units The base units to initialize with
  #   @option units [Integer] :seconds The number of seconds
  #   @option units [Integer] :months The number of months
  # @overload new(count, unit)
  #   @param [Integer] count The number of units to initialize with
  #   @param [Symbol] unit The unit to initialize. See {RelativeTime#units}
  def initialize(count = 0, unit = :second)
    if count.is_a? Hash
      units = count
      units.default = 0
      @seconds, @months = units.values_at(:seconds, :months)
    else
      @seconds = @months = 0

      if @@in_seconds.has_key?(unit)
        @seconds = count * @@in_seconds.fetch(unit)
      elsif @@in_months.has_key?(unit)
        @months = count * @@in_months.fetch(unit)
      end
    end
  end

  # Compares two RelativeTimes to determine if they are equal
  # @param [RelativeTime] time The RelativeTime to compare
  # @return [Boolean] True if both RelativeTimes are equal
  # @note Be weary of rounding; this method compares both RelativeTimes' base units
  def ==(time)
    if time.is_a?(RelativeTime)
      @seconds == time.get(:seconds) && @months == time.get(:months)
    else
      false
    end
  end

  # Return the number of base units in a RelativeTime.
  # @param [Symbol] unit The unit to return, either :seconds or :months
  # @return [Integer] The requested unit count
  # @raise [ArgumentError] Unit requested was not :seconds or :months
  def get(unit)
    if unit == :seconds
      @seconds
    elsif unit == :months
      @months
    else
      raise ArgumentError
    end
  end

  # Determines the time between RelativeTime and the given time.
  # @param [Time] time The initial time.
  # @return [Time] The difference between the current RelativeTime and the given time
  # @example 5 hours before January 1st, 2000 at noon
  #   5.minutes.before(Time.new(2000, 1, 1, 12, 00, 00))
  #     => 2000-01-01 11:55:00 -0800
  # @see #ago
  # @see #after
  # @see #from_now
  def before(time)
    time = time.to_time - @seconds

    new_month = time.month - self.months
    new_year = time.year - self.years
    while new_month < 1
      new_month += 12
      new_year -= 1
    end
    if Date.valid_date?(new_year, new_month, time.day)
      new_day = time.day
    else
      new_day = Date.new(new_year, new_month).days_in_month
    end

    new_time = Time.new(
      new_year, new_month, new_day,
      time.hour, time.min, time.sec
    )
    Time.at(new_time.to_i, time.nsec/1000)
  end

  # Return the time between the RelativeTime and the current time.
  # @return [Time] The difference between the current RelativeTime and Time#now
  # @see #before
  def ago
    self.before(Time.now)
  end

  # Return the time after the given time according to the current RelativeTime.
  # @param [Time] time The starting time
  # @return [Time] The time after the current RelativeTime and the given time
  # @see #before
  def after(time)
    time = time.to_time + @seconds

    new_year = time.year + self.years
    new_month = time.month + self.months
    while new_month > 12
      new_year += 1
      new_month -= 12
    end
    if Date.valid_date?(new_year, new_month, time.day)
      new_day = time.day
    else
      new_day = Date.new(new_year, new_month).days_in_month
    end


    new_time = Time.new(
      new_year, new_month, new_day,
      time.hour, time.min, time.sec
    )
    Time.at(new_time.to_i, time.nsec/1000.0)
  end

  # Return the time after the current time and the RelativeTime.
  # @return [Time] The time after the current time
  def from_now
    self.after(Time.now)
  end

  @@units.each do |unit, plural|
    in_method = "in_#{plural}"
    count_method = plural
    superior_unit = @@units.keys.index(unit) + 1

    if @@in_seconds.has_key? unit
      class_eval "
        def #{in_method}
          @seconds / #{@@in_seconds[unit]}
        end
      "
    elsif @@in_months.has_key? unit
      class_eval "
        def #{in_method}
          @months / #{@@in_months[unit]}
        end
      "
    end

    in_superior = "in_#{@@units.values[superior_unit]}"
    count_superior = @@units.keys[superior_unit]


    class_eval "
      def #{count_method}
        time = self.#{in_method}
        if @@units.length > #{superior_unit}
          time -= self.#{in_superior}.#{count_superior}.#{in_method}
        end
        time
      end
    "
  end

  # Average second-based units to month-based units.
  # @return [RelativeTime] The averaged RelativeTime
  # @example
  #   5.weeks.average
  #     => 1 month, 4 days, 13 hours, 30 minutes, 54 seconds
  # @see #average!
  # @see #unaverage
  def average
    if @seconds > 0
      months = (@seconds / @@average_seconds[:month])
      seconds = @seconds - months.months.unaverage.get(:seconds)
      RelativeTime.new(
        :seconds => seconds,
        :months => months + @months
      )
    else
      self
    end
  end

  # Destructively average second-based units to month-based units.
  # @see #average
  def average!
    averaged = self.average
    @seconds = averaged.get(:seconds)
    @months = averaged.get(:months)
    self
  end

  # Average month-based units to second-based units.
  # @return [RelativeTime] the unaveraged RelativeTime.
  # @example
  #   1.month.unaverage
  #     => 4 weeks, 2 days, 10 hours, 29 minutes, 6 seconds
  # @see #average
  # @see #unaverage!
  def unaverage
    seconds = @@average_seconds[:month] * @months
    seconds += @seconds
    RelativeTime.new(:seconds => seconds)
  end

  # Destructively average month-based units to second-based units.
  # @see #unaverage
  def unaverage!
    unaveraged = self.average
    @seconds = unaverage.get(:seconds)
    @months = unaverage.get(:months)
    self
  end

  # Add two {RelativeTime}s together.
  # @raise ArgumentError Argument isn't a {RelativeTime}
  # @see #-
  def +(time)
    raise ArgumentError unless time.is_a?(RelativeTime)
    RelativeTime.new({
      :seconds => @seconds + time.get(:seconds),
      :months => @months + time.get(:months)
    })
  end

  # Find the difference between two {RelativeTime}s.
  # @raise ArgumentError Argument isn't a {RelativeTime}
  # @see #+
  def -(time)
    raise ArgumentError unless time.is_a?(RelativeTime)
    RelativeTime.new({
      :seconds => @seconds - time.get(:seconds),
      :months => @months - time.get(:months)
    })
  end

  # Converts {RelativeTime} to {WallClock}
  # @return [WallClock] {RelativeTime} as {WallClock}
  # @example
  #   (17.hours 30.minutes).to_wall
  #     # => 5:30:00 PM
  def to_wall
    raise WallClock::TimeOutOfBoundsError if @months > 0
    WallClock.new(:second => @seconds)
  end

  # Convert {RelativeTime} to a human-readable format.
  # @overload to_s(syntax)
  #   @param [Symbol] syntax The syntax from @@syntaxes to use
  # @overload to_s(hash)
  #   @param [Hash] hash The custom hash to use
  #   @option hash [Hash] :units The unit names to use. See @@syntaxes for examples
  #   @option hash [Integer] :count The maximum number of units to output. `1` would output only the unit of greatest example (such as the hour value in `1.hour 3.minutes 2.seconds`).
  #   @option hash [String] :separator The separator to use in between a unit and its value
  #   @option hash [String] :delimiter The delimiter to use in between different unit-value pairs
  # @example
  #   (14.months 49.hours).to_s
  #     => 2 years, 2 months, 3 days, 1 hour
  #   (1.day 3.hours 4.minutes).to_s(:short)
  #     => 1d 3hr
  # @raise KeyError Symbol argument isn't in @@syntaxes
  # @raise ArgumentError Argument isn't a hash (if not a symbol)
  # @see @@syntaxes
  def to_s(syntax = :long)
    if syntax.is_a? Symbol
      syntax = @@syntaxes.fetch(syntax)
    end

    raise ArgumentError unless syntax.is_a? Hash
    times = []

    if syntax[:count].nil? || syntax[:count] == :all
      syntax[:count] = @@units.count
    end
    units = syntax.fetch(:units)

    count = 0
    units = Hash[units.to_a.reverse]
    units.each do |unit, (singular, plural)|
      if count < syntax.fetch(:count)
        time = self.respond_to?(unit) ? self.send(unit) : 0

        if time > 1 && !plural.nil?
          times << [time, plural]
          count += 1
        elsif time > 0
          times << [time, singular]
          count += 1
        end
      end
    end

    times.map do |time|
      time.join(syntax[:separator] || ' ')
    end.join(syntax[:delimiter] || ', ')
  end
end

# Represents a time, but not a date. '`7:00 PM`' would be an example of a WallClock object
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
      units = {:second => hour}
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
      RelativeTime.units_in_seconds.fetch(:hour) * hour +
      RelativeTime.units_in_seconds.fetch(:minute) * minute +
      second

    if @seconds >= RelativeTime.units_in_seconds.fetch(:day)
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
    @seconds / RelativeTime.units_in_seconds[:minute]
  end

  # Get the time of the WallClock, in hours
  # @return [Integer] The total time of the WallClock, in hours
  def in_hours
    @seconds / RelativeTime.units_in_seconds[:hour]
  end

  # Get the second of the WallClock.
  # @return [Integer] The second component of the WallClock
  def second
    self.to_relative.seconds
  end

  # Get the minute of the WallClock.
  # @return [Integer] The minute component of the WallClock
  def minute
    self.to_relative.minutes
  end

  # Get the hour of the WallClock.
  # @param [Symbol] system The houring system to use (either `:twelve_hour` or `:twenty_four_hour`; default `:twenty_four_hour`)
  # @return [Integer] The hour component of the WallClock
  def hour(system = :twenty_four_hour)
    hour = self.to_relative.hours
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

  # Converts {WallClock} to {RelativeTime}
  # @return [RelativeTime] {WallClock} as {RelativeTime}
  # @example
  #   time = WallClock.new(5, 30, :pm)
  #   time.to_relative
  #     => 5 hours, 30 minutes
  def to_relative
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
    options  = {:use_seconds => true, :include_meridiem => true}.merge(options)
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

# {Time} class monkeywrenched with {RelativeTime} support.
class Time
  # Represents an error where two times were expected to be in the future, but were in the past.
  # @see #until
  class TimeIsInThePastError < ArgumentError; end
  # Represents an error where two times were expected to be in the past, but were in the future.
  # @see #since
  class TimeIsInTheFutureError < ArgumentError; end

  class << self
    alias_method :classic_new, :new

    def new(*args)
      begin
        Time.classic_new(*args)
      rescue ArgumentError
        if args.empty?
          Time.new
        else
          Time.local(*args)
        end
      end
    end
  end

  # def initialize(*args)
  #   self.classic_new(args)
  #   # if args.count == 0

  #   # else
  #   # end
  # end

  alias_method :add, :+
  def +(time)
    if time.is_a? RelativeTime
      time.after(self)
    else
      self.add(time)
    end
  end

  alias_method :subtract, :-
  def -(time)
    if time.is_a? RelativeTime
      time.before(self)
    else
      self.subtract(time)
    end
  end

  # Calculates the time until a given time
  # @param [Time] time The time until now to calculate
  # @return [RelativeTime] The time until the provided time
  # @raise[TimeIsInThePastException] The provided time is in the past
  # @example
  #   Time.until(Time.new(2012, 12, 25))
  #     => 13 weeks, 2 days, 6 hours, 31 minutes, 39 seconds
  # @see Time#since
  # @see Time#between
  def self.until(time)
    raise TimeIsInThePastError if Time.now > time.to_time

    Time.between(Time.now, time)
  end

  # Calculates the time since a given time
  # @param [Time] time The time to calculate since now
  # @return [RelativeTime] The time since the provided time
  # @raise[TimeIsInTheFutureException] The provided time is in the future
  # @example
  #   Time.since(Time.new(2011, 10, 31))
  #     => 46 weeks, 5 days, 18 hours, 26 minutes, 10 seconds
  # @see Time#since
  # @see Time#between
  def self.since(time)
    raise TimeIsInTheFutureError if time.to_time > Time.now

    Time.between(Time.now, time)
  end

  # Calculate the amount of time between two times.
  # @param [Time] time1 The initial time
  # @param [Time] time2 The final time
  # @return [RelativeTime] Calculated time between time1 and time2
  # @example
  #   Time.between(1.minute.ago, 1.hour.ago)
  #     => 59.minutes
  # @note The two times are interchangable; which comes first doesn't matter
  # @see Time#until
  # @see Time#since
  def self.between(time1, time2)
    time_between = (time2.to_time - time1.to_time).abs

    RelativeTime.new(time_between.round)
  end

  # Convert {Time} to {Date}.
  # @return [Date] {Time} as {Date}
  # @example
  #   Time.new(2000, 1, 1, 12, 30).to_date
  #     => #<Date: 2000-01-01 ((2451545j,0s,0n),+0s,2299161j)>
  def to_date
    Date.new(self.year, self.month, self.day)
  end

  # Convert self to {Time}.
  # @see Date#to_time
  def to_time
    self
  end

  # Converts {Time} to {WallClock}
  # @return [WallClock] {Time} as {WallClock}
  # @example
  #   time = Time.now.to_wall
  #   Date.tomorrow.at(time)
  #     => 2000-1-2 13:13:27 -0800
  #     # "Same time tomorrow?"
  def to_wall
    WallClock.new(self.hour, self.min, self.sec)
  end
end

# {Date} class monkeywrenched with {RelativeTime} helpers.
class Date
  # Return the number of days in a given month.
  # @return [Integer] Number of days in the month of the {Date}.
  # @example
  #   Date.new(2000, 2).days_in_month
  #     => 29
  def days_in_month
    days_in_feb = (not self.leap?) ? 28 : 29
    number_of_days = [
      31,  days_in_feb,  31,  30,  31,  30,
      31,  31,           30,  31,  30,  31
    ]

    number_of_days.fetch(self.month - 1)
  end

  # Return self as {Date}.
  # @see Time#to_date
  def to_date
    self
  end

  # Apply a time to a date
  # @example yesterday at 5:00
  #   Date.yesterday.at(WallClock.new(5, 00, :pm))
  #     => 2000-1-1 17:00:00 -0800
  def at(time)
    time.to_wall.on(self)
  end

  # Return tomorrow as {Date}.
  # @see Date#yesterday
  def self.tomorrow
    1.day.from_now.to_date
  end

  # Return yesterday as {Date}.
  # @see Date#tomorrow
  def self.yesterday
    1.day.ago.to_date
  end
end

# Monkeywrenched {Integer} class enabled to return {RelativeTime} objects.
# @example
#   5.minutes
#     => 5 minutes
# @see {RelativeTime#units}
class Integer
  RelativeTime.units.each do |unit, plural|
    class_eval "
      def #{unit}(added_time = RelativeTime.new)
        time = RelativeTime.new(self, :#{unit})
        time + added_time unless added_time.nil?
      end
    "
    alias_method(plural, unit)
  end
end
