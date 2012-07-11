# Since the length of months and years aren't constant,
# we use the averages. These also act as sort of 'magic
# numbers' for the relative Time methods
AVERAGE_MONTH = 2628000
AVERAGE_YEAR  = 31540000

class Fixnum
  def seconds
    Time.at(self)
  end

  def minutes
    Time.at(self * 60)
  end

  def hours
    Time.at(self * 3600)
  end

  def days
    Time.at(self * 86400)
  end

  def weeks
    Time.at(self * 604800)
  end

  def months
    Time.at(self * AVERAGE_MONTH)
  end

  def years
    Time.at(self * AVERAGE_YEAR)
  end

  alias_method :second,  :seconds
  alias_method :minute,  :minutes
  alias_method :hour,    :hours
  alias_method :day,     :days
  alias_method :week,    :weeks
  alias_method :month,   :months
  alias_method :year,    :years
end

class Time
  def from_now
    Time.at(self.to_i + Time.now.to_i)
  end

  def ago
    Time.at(Time.now.to_i - self.to_i)
  end
end
