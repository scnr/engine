=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::Stdout

# Stdout formatter for the results of the AutoLogin plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::AutoLogin < SCNR::Engine::Plugin::Formatter

    def run
        print_ok results['message']

        return if !results['cookies']
        print_info 'Cookies set to:'
        results['cookies'].each_pair { |name, val| print_info "    * #{name} = #{val}" }
    end

end
end
