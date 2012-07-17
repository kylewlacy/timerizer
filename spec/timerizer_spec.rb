require_relative '../lib/timerizer'

describe RelativeTime do
  context "given an existing time" do
    before :all do
      @time = Time.new(2000, 1, 1, 3, 45, 00)
    end

    it "calculates a new time before itself" do
      5.minutes.before(@time).should == Time.new(2000, 1, 1, 3, 40, 00)
      5.months.before(@time).should == Time.new(1999, 8, 1, 3, 45, 00)
    end

    it "calculates a new time after itself" do
      5.minutes.after(@time).should == Time.new(2000, 1, 1, 3, 50, 00)
      5.months.after(@time).should == Time.new(2000, 6, 1, 3, 45, 00)
    end
  end

  context "given an odd time case" do
    it "properly calculates the time before it" do
      end_of_march = Time.new(2000, 3, 31, 3, 45, 00)
      1.month.before(end_of_march).should == Time.new(2000, 2, 29, 3, 45, 00)
    end

    it "properly calculates the time after it" do
      end_of_january = Time.new(2000, 1, 31, 3, 45, 00)
      1.month.after(end_of_january).should == Time.new(2000, 2, 29, 3, 45, 00)
    end
  end
end

describe Time do
  
end

describe Date do
end

describe Fixnum do
end
