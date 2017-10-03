# Timerizer

A simple Ruby time helper, just like the Rails ones. You know, without the Rails.

```rb
5.minutes.ago
# => 2012-07-17 10:03:03 -0700
5.months.ago
# => 2012-02-17 10:08:03 -0800
1.minute.from_now
# => 2012-07-17 10:09:03 -0700
5.minutes.before(Time.new(2012, 1, 1, 3, 45, 00))
# => 2012-01-01 03:40:00 -0800
1.year.after(Time.new(2012, 1, 1, 3, 45, 00))
# => 2013-01-01 03:45:00 -0800
```

You can create durations `.seconds`, `.minutes`, etc., or with
`Timerizer::Duration`:

```rb
5.minutes == Timerizer::Duration.new(minutes: 5)
# => true
1.hour == Timerizer::Duration.new(hour: 1)
# => true
(1.week 1.day) == Timerizer::Duration.new(weeks: 1, days: 1)
# => true
(2.weeks) == Timerizer::Duration.new(days: 14)
# => true
```

Plus, it can convert these durations to strings:

```rb
Time.since(Date.yesterday).to_s
# => "1 day, 9 hours, 58 minutes, 3 seconds"
(1.year 3.minutes 4.seconds).to_s(:short)
# => "1yr 3min"
(5.hours 3.minutes).to_s(:micro)
# => "5h"
```

It also has this nice syntax for 'wall clock' times:

```rb
time = Timerizer::WallClock.new(5, 45, :pm)
Date.yesterday.at time
# => 2012-07-16 17:45:00 -0700
Date.tomorrow.at(WallClock.new(19, 30, 30))
# => 2012-07-18 19:30:30 -0700
```

## Requirements

Currently, Timerizer works in Ruby 2.0+

## Building and Installation

If you want to install Timerizer:

```
$ gem install timerizer
```

To build and install Timerizer yourself, do the following:

``
$ git clone git://github.com/kylewlacy/timerizer.git
$ cd timerizer
$ rake build
$ gem install ./pkg/timerizer-*.gem
```

## Documentation

Documentation can be found on [RubyDoc.info](http://rdoc.info/github/kylewlacy/timerizer/master/frames)
