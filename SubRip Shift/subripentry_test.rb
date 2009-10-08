# subripentry_test.rb
require 'test/unit'
require 'construct'
require 'shiftsubtitle'

class Pathname
  # windows has problems with temp files created by Ruby
  # http://redmine.ruby-lang.org/issues/show/1494
  def rmtree
    nil
  end
end

class SubRipEntryTest < Test::Unit::TestCase
  include Construct::Helpers 

  def test_process
    entry = SubRipEntry
    within_construct do |construct|
      construct.file('unit_test.srt') do
        <<-EOS
646
01:31:54,928 --> 01:31:57,664
In connection with a dramatic increase
in crime in certain neighbourhoods,
        EOS
      end

      entry = SubRipEntry.new

      file = File.open('unit_test.srt')
      begin
        entry.process file
      rescue EOFError
        file.close
      end

      assert_equal 646, entry.identifier
      assert_equal '01:31:54,928', entry.start.to_s
      assert_equal '01:31:57,664', entry.end.to_s
      assert_equal 2, entry.lines.length
      assert_equal 'In connection with a dramatic increase', entry.lines[0]
      assert_equal 'in crime in certain neighbourhoods,', entry.lines[1]
    end

  end

  def test_adjust
    entry = SubRipEntry
    within_construct do |construct|
      construct.file('unit_test.srt') do
        <<-EOS
646
01:31:54,928 --> 01:31:57,664
In connection with a dramatic increase
in crime in certain neighbourhoods,
        EOS
      end

      entry = SubRipEntry.new

      file = File.open('unit_test.srt')
      begin
        entry.process file
      rescue EOFError
        file.close
      end

      assert_equal '01:31:54,928', entry.start.to_s
      assert_equal '01:31:57,664', entry.end.to_s

      entry.adjust(:add, 2.500)

      assert_equal '01:31:57,428', entry.start.to_s
      assert_equal '01:32:00,164', entry.end.to_s

      entry.adjust(:sub, 2.500)

      assert_equal '01:31:54,928', entry.start.to_s
      assert_equal '01:31:57,664', entry.end.to_s
    end

  end

  def test_output
    src, dst = SubRipEntry
    within_construct do |construct|
      construct.file('unit_test_in.srt') do
        <<-EOS
646
01:31:54,928 --> 01:31:57,664
In connection with a dramatic increase
in crime in certain neighbourhoods,
        EOS
      end      

      src = SubRipEntry.new

      file = File.open('unit_test_in.srt')
      begin
        src.process file
      rescue EOFError
        file.close
      end

      construct.file('unit_test_out.srt')
      File.open('unit_test_out.srt', 'w') do |f|
        src.output(f)
      end
      dst = SubRipEntry.new
      File.open('unit_test_out.srt', 'r') do |f|
        begin
          dst.process f
        rescue EOFError     
          f.close
        end
      end

      assert_equal 646, dst.identifier
      assert_equal '01:31:54,928', dst.start.to_s
      assert_equal '01:31:57,664', dst.end.to_s
      assert_equal 2, dst.lines.length
      assert_equal 'In connection with a dramatic increase', dst.lines[0]
      assert_equal 'in crime in certain neighbourhoods,', dst.lines[1]
    end

  end


end