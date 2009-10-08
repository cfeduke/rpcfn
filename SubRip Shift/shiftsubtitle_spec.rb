# shiftsubtitle_spec.rb
require 'shiftsubtitle'
require 'construct'

describe ShiftSubtitle do 
  include Construct::Helpers
  
  before :each do
    @mock_kernel = mock(Kernel)
    @mock_kernel.stub!(:exit)
    @mock_file = mock(File)
    @mock_file.stub!(:exist?).and_return(true)
  end

  it "should exit cleanly when -h is used" do
    ss = ShiftSubtitle.new(@mock_kernel)
    @mock_kernel.should_receive(:exit)
    ss.process_arguments(["-h"])    
  end

  it "should throw an exception when operation is not add/sub" do
    ss = ShiftSubtitle.new
    lambda {
      ss.process_arguments(["-o", "blah"])
    }.should raise_error
  end

  it "should only accept the appropriate #,### format for time" do
    ss = ShiftSubtitle.new(@mock_kernel, @mock_file)
    @mock_kernel.should_receive(:exit)
    ss.process_arguments(["-t", "x"])
    ss.process_arguments(["-t", "34,"])
    ss.process_arguments(["-t", "3333."])
    ss.process_arguments(["-t", "22,4444"])
  end

  it "should require that INPUT_FILE and OUTPUT_FILE be specified" do
    ss = ShiftSubtitle.new(@mock_kernel)
    @mock_kernel.should_receive(:exit)
    ss.process_arguments([""])
    ss.process_arguments(["input.txt"])  
  end

  it "should verify the INPUT_FILE exists" do
    ss = ShiftSubtitle.new(@mock_kernel)
    @mock_kernel.should_receive(:exit)
    ss.process_arguments(["input.txt"])
  end

  it "should parse correctly if expected parameters are passed" do
    ss = ShiftSubtitle.new(@mock_kernel, @mock_file)
    options = ss.process_arguments(["-o", "add", "-t", "3,14", "input", "output"])
    options.operation.should == :add
    options = ss.process_arguments(["-o", "sub", "-t", "4.344", "input", "output"])
    options.operation.should == :sub
  end

  it "should correctly process an input file and produce an output file" do
    within_construct do |construct|
      construct.file('unit_test_in.srt') do
         <<-EOS
645
01:31:51,210 --> 01:31:54,893
the government is implementing a new policy...

646
01:31:54,928 --> 01:31:57,664
In connection with a dramatic increase
in crime in certain neighbourhoods,

        EOS
      end
      construct.file('unit_test_out.srt')
      ss = ShiftSubtitle.new
      ss.process_arguments(['-o', 'add', '-t', '0,500', 'unit_test_in.srt', 'unit_test_out.srt'])
      ss.transform

      entries = Array.new
      File.open('unit_test_out.srt', 'r') do |f|
        begin
          while !f.eof do
            entry = SubRipEntry.new
            entry.process f
            entries.push entry
          end
        rescue EOFError
          f.close
        end
      end

      entries[0].identifier.should == 645
      entries[0].start.to_s.should == "01:31:51,710"
      entries[0].end.to_s.should == "01:31:55,393"
      entries[0].lines.length.should == 1
      entries[0].lines[0].should == "the government is implementing a new policy..."

      entries[1].identifier.should == 646
      entries[1].start.to_s.should == "01:31:55,428"
      entries[1].end.to_s.should == "01:31:58,164"
      entries[1].lines.length.should == 2
      entries[1].lines[0].should == "In connection with a dramatic increase"
      entries[1].lines[1].should == "in crime in certain neighbourhoods,"      
    end # within
  end

end

