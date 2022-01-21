=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::Stdout

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::Exec < SCNR::Engine::Plugin::Formatter

    def run
        results.each do |stage, data|
            print_status "#{stage}: #{data['executable']}"
            print_info "Status:  #{data['status']}"
            print_info "PID:     #{data['pid']}"
            print_info "Runtime: #{data['runtime']}"
            print_info "STDOUT:  #{data['stdout']}"
            print_info "STDERR:  #{data['stderr']}"
        end
    end

end
end
