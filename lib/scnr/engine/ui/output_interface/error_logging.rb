=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module UI
module OutputInterface

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module ErrorLogging

    def self.initialize
        @@error_log_written_env = false

        @@error_fd ||= nil
        begin
            @@error_fd.close if @@error_fd
        rescue IOError
        end

        @@error_fd      = nil
        @@error_buffer  = []
        @@error_logfile = "#{SCNR::Engine::Options.paths.logs}error-#{Process.pid}.log"
    end

    # @param    [String]    logfile
    #   Location of the error log file.
    def set_error_logfile( logfile )
        @@error_logfile = logfile
    end

    # @return  [String]
    #   Location of the error log file.
    def error_logfile
        @@error_logfile
    end

    def has_error_log?
        File.exist? error_logfile
    end

    private

    def error_log_fd
        return @@error_fd if @@error_fd

        @@error_fd = File.open( error_logfile, 'a' )
        @@error_fd.sync = true

        Kernel.at_exit do
            begin
                @@error_fd.close if @@error_fd
            rescue IOError
            end
        end

        @@error_fd

    # Errno::EMFILE (too many open files) or something, nothing we can do
    # about it except catch it to avoid a crash.
    rescue SystemCallError => e
        $stderr.puts "[#{e.class}] #{e}"
        e.backtrace.each { |line| $stderr.puts line }
        nil
    end

    # Logs an error message to the error log file.
    #
    # @param    [String]    str
    def log_error( str = '' )
        fd = error_log_fd

        if !@@error_log_written_env
            @@error_log_written_env = true

            ['', "#{Time.now} " + ( '-' * 80 )].each do |s|

                if fd
                    fd.puts s
                end

                @@error_buffer << s
            end

            begin
                h = {}
                ENV.each { |k, v| h[k] = v }

                options = SCNR::Engine::Options.to_rpc_data
                if options['http']['authentication_username']
                    options['http']['authentication_username'] = '*****'
                    options['http']['authentication_password'] =
                        options['http']['authentication_username']
                end
                options = options.to_yaml

                ['ENV:', h.to_yaml, '-' * 80, 'OPTIONS:', options].each do |s|

                    if fd
                        fd.puts s
                    end

                    @@error_buffer += s.split("\n")
                end
            rescue
            end

            if fd
                fd.puts '-' * 80
            end

            @@error_buffer << '-' * 80
        end

        msg = "[#{Time.now}] #{str}"
        @@error_buffer << msg

        if fd
            fd.puts msg
        end

        nil
    end

end

end
end
end
