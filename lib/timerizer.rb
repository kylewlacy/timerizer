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
  #   @option units [Fixnum] :seconds The number of seconds
  #   @option units [Fixnum] :months The number of months
  # @overload new(count, unit)
  #   @param [Fixnum] count The number of units to initialize with
  #   @param [Symbol] unit The unit to initialize. See {@@units}
  def initialize(count = 0, unit = :second)
    if count.is_a? Hash
      @seconds = count[:seconds] || 0
      @months = count[:months] || 0
    else
      @seconds = 0
      @months = 0

      if(@@in_seconds.has_key?(unit))
        @seconds = count * @@in_seconds.fetch(unit)
      elsif(@@in_months.has_key?(unit))
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
  # @return [Fixnum] The requested unit count
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
  #   5.minutes.before(Time.now(2000, 1, 1, 12, 00, 00))
  #     => 2000-01-01 11:55:00 -0800
  # @see #ago
  # @see #after
  # @see #from_now
  def before(time)
    time = time.to_time - @seconds

    new_month = time.month - @months
    new_year = time.year
    while new_month < 1
      new_month += 12
      new_year -= 1
    end
    if(Date.valid_date?(new_year, new_month, time.day))
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

    new_year = time.year
    new_month = time.month + @months
    while new_month > 12
      new_year += 1
      new_month -= 12
    end
    if(Date.valid_date?(new_year, new_month, time.day))
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

    define_method(in_method) do
      if(@@in_seconds.has_key?(unit))
        @seconds / @@in_seconds[unit]
      elsif(@@in_months.has_key?(unit))
        @months / @@in_months[unit]
      end
    end

    define_method(count_method) do
      in_superior = "in_#{@@units.values[superior_unit]}"
      count_superior = @@units.keys[superior_unit]

      time = self.send(in_method)
      if(@@units.length > superior_unit)
        time -= self.send(in_superior).send(count_superior).send(in_method)
      end
      time
    end
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

  # Convert {RelativeTime} to a human-readable format.
  # @example
  #   (14.months 49.hours).to_s
  #     => 2 years, 2 months, 3 days, 1 hour
  def to_s
    times = []

    @@units.each do |unit, plural|
      time = self.respond_to?(plural) ? self.send(plural) : 0
      times << [time, (time != 1) ? plural : unit] if time > 0
    end

    times.map do |time|
      time.join(' ')
    end.reverse.join(', ')
  end
end

# Represents a time, but not a date. '`7:00 PM`' would be an example of a Wallclock object
class Wallclock
  class InvalidMeridiemError < ArgumentError; end
  class TimeOutOfBoundsError < ArgumentError; end

  # Initialize a new instance of Wallclock
  # @overload new(hash)
  #   @param [Hash] units The units to initialize with
  #   @option units [Fixnum] :hour The hour to initialize with
  #   @option units [Fixnum] :minute The minute to initialize with
  #   @option units [Fixnum] :second The second to initialize with
  # @overload new(hour, minute, meridiem)
  #   @param [Fixnum] hour The hour to initialize with
  #   @param [Fixnum] minute The minute to initialize with
  #   @param [Symbol] meridiem The meridiem to initialize with (AM or PM)
  # @overload new(hour, minute, second, meridiem)
  #   @param [Fixnum] hour The hour to initialize with
  #   @param [Fixnum] minute The minute to initialize with
  #   @param [Fixnum] second The second to initialize with
  #   @param [Symbol] meridiem The meridiem to initialize with (:am or :pm)
  def initialize(hour = 0, minute = 0, second = 0, meridiem = :am)
    if hour.is_a?(Hash)
      second = hour[:second] || 0
      minute = hour[:minute] || 0
      hour = hour[:hour] || 0
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

      hour += 12 if meridiem == :pm
    end

    @seconds =
      RelativeTime.units_in_seconds.fetch(:hour) * hour +
      RelativeTime.units_in_seconds.fetch(:minute) * minute +
      second

    if @seconds > RelativeTime.units_in_seconds.fetch(:day)
      raise TimeOutOfBoundsError
    end
  end

  # Returns the time of the Wallclock on a date
  # @param [Date] The date to apply the time on
  # @return [Time] The time after the given date
  # @example yesterday at 5:00
  #   time = Wallclock.new(5, 00, :pm)
  #   time.on(Date.yesterday)
  #     => 2000-1-1 17:00:00 -0800
  def on(date)
    date.to_date.to_time + @seconds
  end
end

# {Time} class monkeywrenched with {RelativeTime} support.
class Time
  class TimeIsInThePastError < ArgumentError; end
  class TimeIsInTheFutureError < ArgumentError; end

  add = instance_method(:+)
  define_method(:+) do |time|
    if(time.class == RelativeTime)
      time.after(self)
    else
      add.bind(self).(time)
    end
  end

  subtract = instance_method(:-)
  define_method(:-) do |time|
    if(time.class == RelativeTime)
      time.before(self)
    else
      subtract.bind(self).(time)
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
  # @param [Time] since The time to calculate since now
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
end

# {Date} class monkeywrenched with {RelativeTime} helpers.
class Date
  # Return the number of days in a given month.
  # @return [Fixnum] Number of days in the month of the {Date}.
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

# Monkeywrenched {Fixnum} class enabled to return {RelativeTime} objects.
# @example
#   5.minutes
#     => 5 minutes
# @see RelativeTime @@units
class Fixnum
  units  = RelativeTime.class_variable_get(:@@units)
  units.each do |unit, plural|
    define_method(unit) do |added_time = RelativeTime.new|
      time = RelativeTime.new(self, unit)
      time + added_time
    end
    alias_method(plural, unit)
  end
end
