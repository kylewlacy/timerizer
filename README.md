Timerizer
=========
A simple Ruby time helper, just like the Rails ones. You know, without the Rails.

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

Requirements
------------
Currently, Timerizer only works in Ruby version 1.9.2 and 1.9.3

Building and Installation
-------------------------
To build and install Timerizer, do the following:

    git clone git://github.com/kylewlacy/timerizer.git
    cd timerizer
    rake make
    gem install ./timerizer-{verion}.gem

Documentation
-------------
Documentation can be found on [RubyDoc.info](http://rdoc.info/github/kylewlacy/timerizer/master/frames)
