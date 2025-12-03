=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'openai'

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class SCNR::Engine::Plugins::OpenAI < SCNR::Engine::Plugin::Base

    THREADS = 1

    def self.rate_limit_reached?
        !!@rate_limited
    end

    def self.rate_limit_reached!
        @rate_limited = true
    end

    class Client
        def initialize( options )
            @apikey = options[:apikey]

            @rate_limited = false
        end

        def client
            @client ||= ::OpenAI::Client.new(
              access_token: @apikey,
              # log_errors:   true
            )
        end

        def assistant_id
            return @assistant_id if @assistant_id

            response = client.assistants.create(
              parameters: {
                model: "gpt-4o",
                name:  "Codename SCNR assistant.",
                "metadata": { my_internal_version_id: "1.0.0" }
              }
            )
            @assistant_id = response["id"]
        end

        def post( m )
            fail 'Rate limit reached.' if @rate_limited

            message m
            think
        end

        def thread_id
            return @thread_id if @thread_id

            response = client.threads.create
            @thread_id = response["id"]
        end

        def message( content, options = {} )
            client.messages.create(
              thread_id: thread_id,
              parameters: {
                role: "user",
                content: content
              }
            )
        end

        def think
            response = client.runs.create(
              thread_id: thread_id,
              parameters: {
                assistant_id: assistant_id,
                # max_prompt_tokens: 256,
                # max_completion_tokens: 16
              }
            )

            run_id = response['id']

            while true do
                response = client.runs.retrieve( id: run_id, thread_id: thread_id )
                status = response['status']

                case status
                    when 'queued', 'in_progress', 'cancelling'
                        sleep 1

                    when 'completed'
                        break

                    when 'requires_action'
                        return

                    when 'cancelled', 'failed', 'expired'
                        if response['last_error']['code'] == 'rate_limit_exceeded'
                            @rate_limited = true
                            SCNR::Engine::Plugins::OpenAI.rate_limit_reached!
                        end

                        fail "Status response: #{status} -- #{response['last_error']}"

                    else
                        fail "Unknown status response: #{status} -- #{response['last_error']}"
                end
            end

            client.messages.list( thread_id: thread_id, parameters: { order: 'asc' } )['data'].last
        end
    end

    class Djin

        def initialize( issue, options )
            @issue  = issue
            @client = Client.new( options )

            prepare
        end

        def describe!
          @issue.description = post(
              "How would you describe this vulnerability? Keep the server side and client side separate."
          )
        end

        def remedy_guidance!
            @issue.remedy_guidance = post(
              "How would you remediate this vulnerability? Keep the server side and client side separate."
            )
        end

        def remedy_code!
            @issue.remedy_code = post(
              "How would you remediate this vulnerability in code? Keep the server side and client side separate."
            )
        end

        def exploit!
            @issue.exploit = post( "How could a malicious hacker exploit this vulnerability?" )
        end

        def patch!
            @issue.patch = post(
                "Fix the #{@issue.name} issue found in the source code files and provide a patch file along " <<
                "with patching instructions. Keep the server side and client side separate. Also, provide a " <<
                "holistic approach as well."
          )
        end

        def dissect!
            @issue.dissect = post(
              "Dissect this issue. Keep the server side and client side separate as much as possible."
            )
        end

        def insights!
            @issue.insights = post(
              "Write any insights regarding this issue. Keep the server side and client side separate. " <<
                "Also provide a holistic view."
            )
        end

        def report!
            @issue.report = post( "Write a report for this issue." )
        end

        def post( message )
            join_response_contents( @client.post( "Without greeting: #{message}" ) )
        end

        private

        def prepare
            files_msg = ""

            server_files = self.executed_file_contents
            if server_files.any?
                files_msg << "On the Server side these files:\n"

                server_files.each do |path, contents|
                    next if contents.to_s.empty?
                    files_msg << "#{path} :\n"
                    files_msg << "\n```\n#{contents}\n```\n"
                end
            end

            if (sinks = (@issue.page.dom.execution_flow_sinks + @issue.page.dom.data_flow_sinks)).any?
                files_msg << "\nOn the Client side these files:\n"

                client_files = {}
                sinks.each do |sink|
                    sink.trace.each do |frame|
                        next if client_files.include? frame.url
                        next if frame.url.empty?
                        next if frame.url.start_with? 'http://javascript.browser.scnr.engine/'

                        client_files[frame.url] = SCNR::Engine::HTTP::Request.new( url: frame.url ).run.body
                    end
                end

                client_files.each do |url, contents|
                    files_msg << "#{url} :\n"
                    files_msg << "\n```\n#{contents}\n```\n"
                end
            end

            msg = "You are an expert web application security engineer and expert web developer.\n"
            if !files_msg.empty?
                msg << <<-EOT
                These are source code files, which contain a '#{@issue.name}' vulnerability of #{@issue.severity} severity.
                EOT
            else
                msg << <<-EOT
                There is a '#{@issue.name}' vulnerability of #{@issue.severity} severity.
                EOT
            end

            msg << "\n"
            msg << <<-EOT
                The vulnerability was found in the following resource: #{@issue.page.dom.url}

                The HTTP request for this resource was:
```
#{@issue.request}
```
            EOT

            if !@issue.response.body.binary?
                msg << <<-EOT
                    The HTTP response for this resource was:
    ```
    #{@issue.response}
    ```
    
                    The rendered HTML body for this resource was:
    ```html
    #{@issue.page.body}
    ```
                EOT
            end

            if @issue.active?
                msg << <<-EOT
                The vulnerability was found via a '#{@issue.vector.type}' input named '#{@issue.affected_input_name}',
                using this payload: #{@issue.affected_input_value}.
                EOT

                if @issue.proof
                    msg << <<-EOT
                    Proof of this vulnerability is: #{@issue.proof}
                    EOT
                end

                if @issue.signature
                    msg << <<-EOT
                    It was identified by this signature: #{@issue.signature}
                    EOT
                end
            else
                msg << <<-EOT
                The vulnerability was found in the '#{@issue.vector.type}'.
                EOT
            end

            if @issue.remarks.any?
                @issue.remarks.each do |component, remarks|
                    msg << <<-EOT
                    The '#{component}' component remarked:
                    EOT

                    remarks.each do |remark|
                        msg << "* #{remark}\n"
                    end
                end
            end

            if @issue.platform_name
                msg << <<-EOT
                    The identified technology platform for this issue is '#{@issue.platform_name}'.
                EOT
            end

            if !files_msg.empty?
                msg << "\nThe web application source code files are:\n\n"
                msg << "\n#{files_msg}"
            end

            # puts msg
            post msg
        end

        def executed_file_contents
            files = {}
            return files if !@issue.request.execution_flow

            @issue.request.execution_flow.points.each do |point|
                files[point.path] = point.file_contents
            end
            files
        end

        def join_response_contents( response )
            fail 'Response does not include content.' if !response.to_s.include?( 'content' )
            response['content'].map { |c| c['text']['value'] }.join( "\n" )
        end
    end

    def prepare
        Data.issues.do_not_store
        Data.issues.on_new { |issue| thread_pool.post { process issue } }
    end

    def run
        wait_while_framework_running
        sleep 0.1 while thread_pool.scheduled_task_count != thread_pool.completed_task_count
    end

    def process( issue )
        return if self.class.rate_limit_reached?

        msg = "[#{issue.digest}] #{issue.name} in #{issue.vector.type}"
        if issue.active?
            msg << " input '#{issue.affected_input_name}'."
        else
            msg << '.'
        end

        print_status "Processing issue: #{msg}"

        djin = nil
        begin
            print_info "Initialising the Djin."
            djin = Djin.new( issue, @options )
        rescue => e
           print_exception e
           return
        end

        begin
            print_info "Djin: [#{issue.digest}] Getting description."
            djin.describe!
        rescue => e
            print_exception e
        end
        begin
            print_info "Djin: [#{issue.digest}] Getting patch."
            djin.patch!
        rescue => e
            print_exception e
        end

        begin
            print_info "Djin: [#{issue.digest}] Getting exploit."
            djin.exploit!
        rescue => e
            print_exception e
        end

        begin
            print_info "Djin: [#{issue.digest}] Getting insights."
            djin.insights!
        rescue => e
            print_exception e
        end

        begin
            print_info "Djin: [#{issue.digest}] Getting remediation guidance."
            djin.remedy_guidance!
        rescue => e
            print_exception e
        end

        begin
            print_info "Djin: [#{issue.digest}] Getting remediation code."
            djin.remedy_code!
        rescue => e
            print_exception e
        end

        begin
            print_info "Djin: [#{issue.digest}] Getting dissect."
            djin.dissect!
        rescue => e
            print_exception e
        end

        begin
            print_info "Djin: [#{issue.digest}] Getting report."
            djin.report!
        rescue => e
            print_exception e
        end

        # ap 'DESCRIBE'
        # puts issue.description
        # ap 'PATCH'
        # puts issue.patch
        # ap 'EXPLOIT'
        # puts issue.exploit
        # ap 'DISSECT'
        # puts issue.dissect
        # ap 'INSIGHTS'
        # puts issue.insights
        # ap 'REMEDY GUIDANCE'
        # puts issue.remedy_guidance
        # ap 'REMEDY CODE'
        # puts issue.remedy_code
        # ap 'REPORT'
        # puts issue.report
    ensure
        Data.issues._push issue
    end

    def thread_pool
        @thread_pool ||= Concurrent::ThreadPoolExecutor.new(
          min_threads: 0,
          max_threads: THREADS
        )
    end

    def self.info
        {
          name:        'OpenAI',
          description: %q{This plugin provides context and insights to identified issues using OpenAI.},
          author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
          version:     '0.1',
          options:     [
            Options::String.new( :apikey, required: true,
                                 description: 'An OpenAI API key with all permissions granted. ' <<
                                   'Tier 2 and higher, to avoid token rate limiting errors. '
            )
          ]
        }
    end

end
