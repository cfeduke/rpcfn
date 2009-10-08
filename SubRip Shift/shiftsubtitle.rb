require 'optparse'
require 'ostruct'
require 'time'

class Time
  def to_s
    self.strftime('%H:%M:%S') + ',' + "%.3d" % (self.usec / 1_000)
  end
end

class ShiftSubtitle

  def initialize(kernel=Kernel,file=File)
    @kernel = kernel
    @file = file
    @options = OpenStruct.new({
                    :operation => :add, 
                    :time => "0,000",
                    :input_file => "",
                    :output_file => ""
            })
  end

  def process_arguments(args)
    opts = OptionParser.new do |opts|
      opts.banner = "Usage: shiftsubtitle.rb --operation ADD|SUB --time [TIME=0,000] INPUT_FILE OUTPUT_FILE"
      opts.separator ""
      opts.on("-o", "--operation OPERATION", [:add, :sub], "Add (add) or subtract (sub) TIME") do |op|
        @options.operation = op
      end

      opts.on("-t", "--time TIME", "Amount of time in SECONDS,MILLISECONDS to shift by") do |time|
        @options.time = time || '0,000'
        if not @options.time =~ /^\d+$|^\d+[,]+\d{1,3}$/
          puts "TIME must be in #,### format."
          @kernel.exit
        end
        @options.time = @options.time.gsub!(/,/, '.').to_f 
      end

      opts.on_tail("-h", "--help", "Shows this message") do
        puts opts
        @kernel.exit
      end
    end

    opts.parse!(args)
    @options.input_file, @options.output_file = args

    if @options.input_file.nil? or
            @options.input_file.length == 0 or
            @options.output_file.nil? or
            @options.output_file.length == 0
      puts "Both INPUT_FILE and OUTPUT_FILE must be specified."
      @kernel.exit
    end

    if not @options.input_file.nil? and not @options.input_file.length == 0 and not @file.exist?(@options.input_file)
      puts "INPUT_FILE must exist."
      @kernel.exit
    end

    @options
  end

  def transform
    count = 0
    @file.open(@options.output_file, 'w') do |outfile|
      @file.open(@options.input_file, 'r') do |infile|
        while !infile.eof
          entry = SubRipEntry.new
          begin
            entry.process infile
          rescue EOFError
            
          end
          entry.adjust @options.operation, @options.time
          entry.output outfile
          outfile.puts
          count += 1
        end #while
      end #infile 
    end #outfile
    count
  end

end

class SubRipEntry
  attr_reader :identifier, :start, :end, :lines

  def process(file)
    @identifier = file.readline.chomp.to_i
    times = file.readline.chomp
    @start, @end = times.split(' --> ', 2).map { |time| Time.parse(time) }
    @lines = Array.new
    while (line = file.readline)
      line.chomp!
      break if line.length == 0
      @lines.push(line)
    end
  end

  def adjust(operation, amount)
    operation = (operation == :add ? :+ : :-)
    @start, @end = [@start, @end].map {|time| time.send(operation, amount)}
  end

  def output(file)
    [@identifier, @start.to_s + ' --> ' + @end.to_s, @lines].each {|line| file.puts(line)}
  end
end

def stopwatch
  start = Time.now
  yield
  Time.now - start
end

# this prevents the block of code within from executing during unit tests
if __FILE__ == $0
  count = 0
  elapsed = stopwatch do
    ss = ShiftSubtitle.new
    ss.process_arguments ARGV
    count = ss.transform
  end
  puts "Processed #{count} entries in #{elapsed} seconds."
end
