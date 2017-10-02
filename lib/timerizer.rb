require "date"
require_relative "./timerizer/core"

# {Time} class monkey-patched with {Timerizer::Duration} support.
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
    if time.is_a?(Timerizer::Duration)
      time.after(self)
    else
      self.add(time)
    end
  end

  alias_method :subtract, :-
  def -(time)
    if time.is_a?(Timerizer::Duration)
      time.before(self)
    else
      self.subtract(time)
    end
  end

  # Calculates the time until a given time
  # @param [Time] time The time until now to calculate
  # @return [Duration] The time until the provided time
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
  # @return [Duration] The time since the provided time
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
  # @return [Duration] Calculated time between time1 and time2
  # @example
  #   Time.between(1.minute.ago, 1.hour.ago)
  #     => 59.minutes
  # @note The two times are interchangable; which comes first doesn't matter
  # @see Time#until
  # @see Time#since
  def self.between(time1, time2)
    time_between = (time2.to_time - time1.to_time).abs

    Timerizer::Duration.new(seconds: time_between.round)
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

  # Converts {Time} to {Timerizer::WallClock}
  # @return [Timerizer::WallClock] {Time} as {Timerizer::WallClock}
  # @example
  #   time = Time.now.to_wall
  #   Date.tomorrow.at(time)
  #     => 2000-1-2 13:13:27 -0800
  #     # "Same time tomorrow?"
  def to_wall
    Timerizer::WallClock.new(self.hour, self.min, self.sec)
  end
end

# {Date} class monkey-patched with {Timerizer::Duration} helpers.
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

# Monkey-patched {Integer} class enabled to return {Timerizer::Duration}s.
# @example
#   5.minutes
#   # => 5 minutes
# @see Timerizer::Duration::UNITS
class Integer
  private

  # @!macro [attach] _define_duration_unit
  #   @method $1(other = nil)
  #
  #   Return a {Timerizer::Duration} with `self` of the given unit. This
  #   method is a helper that is equivalent to
  #   `Timerizer::Duration::new($1: self)`.
  #
  #   @param [Timerizer::Duration, nil] other Another duration to add to the
  #     resulting duration, if present. This argument allows "chaining" multiple
  #     durations together, to combine multiple units succiently.
  #
  #   @return [Timerizer::Duration] the quantity of the unit in the duration.
  #
  #   @see Timerizer::Duration#initialize
  #
  #   @example
  #     n.$1 == Timerizer::Duration.new($1: n)
  #     5.minutes == Timerizer::Duration.new(minutes: 5)
  #     (1.week 1.day) == 8.days # "Chaining" multiple units
  #     (n.$1 x.minutes) == (n.$1 + x.minutes)
  def self._define_duration_unit(unit)
    define_method(unit) do |other = nil|
      duration = Timerizer::Duration.new(unit => self)

      if other.nil?
        duration
      else
        duration + other
      end
    end
  end

  public

  self._define_duration_unit(:seconds)
  self._define_duration_unit(:minutes)
  self._define_duration_unit(:hours)
  self._define_duration_unit(:days)
  self._define_duration_unit(:weeks)
  self._define_duration_unit(:months)
  self._define_duration_unit(:years)
  self._define_duration_unit(:decades)
  self._define_duration_unit(:centuries)
  self._define_duration_unit(:millennia)
  self._define_duration_unit(:second)
  self._define_duration_unit(:minute)
  self._define_duration_unit(:hour)
  self._define_duration_unit(:day)
  self._define_duration_unit(:week)
  self._define_duration_unit(:month)
  self._define_duration_unit(:year)
  self._define_duration_unit(:decade)
  self._define_duration_unit(:century)
  self._define_duration_unit(:millennium)
end
