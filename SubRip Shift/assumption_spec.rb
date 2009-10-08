require 'time'

class Assumption
end

# have to validate my assumptions, new language and all
describe Assumption do
	# does parse work without a date?
	it "should parse 01:31:51,210 correctly" do
		time = Time.parse("01:31:51,210")
		time.hour.should == 1
		time.min.should == 31
		time.sec.should == 51
		time.usec.should == 210000
	end
	
	# the RPCFN example
	it "should add 2,500 to 01:23:04,283 correctly" do
		time = Time.parse("01:23:04,283")
		time += 2.500
		time.hour.should == 1
		time.min.should == 23
		time.sec.should == 6
		time.usec.should == 783000
	end
	
	# cross the second boundary with milliseconds
	it "should cross the second boundary" do
		time = Time.parse("00:00:00,999")
		time += 0.1
		time.min.should == 0
		time.sec.should == 1
		time.usec.should == 99000
	end
end