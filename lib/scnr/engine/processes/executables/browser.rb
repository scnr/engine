require 'childprocess'
require 'fileutils'

def print_exception( e )
    puts_stderr "#{Process.pid}: [#{e.class}] #{e}"
    e.backtrace.each do |line|
        puts_stderr "#{Process.pid}: #{line}"
    end
rescue
end

def exit?
    $stdin.read_nonblock( 1 )
    false
rescue Errno::EWOULDBLOCK
    false
# Parent dead or willfully closed STDIN as a signal.
rescue EOFError, Errno::EPIPE => e
    print_exception( e )
    true
end

ENV['LD_LIBRARY_PATH'] = ''
ENV['LIBRARY_PATH']    = ''

# Get a clean slate every time.
ENV['TMPDIR'] = "#{$options[:tmpdir]}/#{File.basename( $options[:executable] )}_#{Process.pid}"

# MS Windows
ENV['TEMP']                 = ENV['TMPDIR']
ENV['TMP']                  = ENV['TMPDIR']
ENV['APPDATA']              = ENV['TMPDIR']
ENV['LOCALAPPDATA']         = ENV['TMPDIR']

# *nix
ENV['XDG_CONFIG_HOME']      = ENV['TMPDIR']
ENV['XDG_CACHE_HOME']       = ENV['TMPDIR']
ENV['CHROME_USER_DATA_DIR'] = ENV['TMPDIR']

FileUtils.mkdir_p ENV['TMPDIR']

process = ChildProcess.build(
    *([$options[:executable]] + $options[:args].map { |k, v| "--#{k}=#{v}" })
)

handle_exit = proc do
    next if @called
    @called = true

    puts_stderr "#{Process.pid}: Exiting"

    begin
        process.stop
    rescue => e
        print_exception( e )
    end

    FileUtils.rm_rf ENV['TMPDIR']
end

at_exit( &handle_exit )

# Try our best to terminate cleanly if some external entity tries to kill us.
%w(EXIT TERM QUIT INT KILL).each do |signal|
    next if !Signal.list.include?( signal )
    trap( signal, &handle_exit ) rescue Errno::EINVAL
end

# Break out of the process group in order to ignore signals sent to the parent.
process.leader = true

# Forward output.
process.io.stdout = $stdout
process.io.stdout.sync = true
process.io.stderr = $stdout
process.io.stderr.sync = true

process.start
puts_stderr "#{Process.pid}: Started"

$stdout.puts "PID: #{process.pid}"

while !exit?
    begin
        break if !process.alive?

    # If for whatever reason we can't get a status on the browser consider it
    # dead.
    rescue => e
        print_exception( e )
        break
    end

    sleep 0.03
end

puts_stderr "#{Process.pid}: EOF"
