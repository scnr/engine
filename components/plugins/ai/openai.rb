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

    THREADS   = 2
    MAX_QUEUE = 10

    class Client
        def initialize( options )
            @apikey = options[:apikey]
        end

        def client
            @client ||= OpenAI::Client.new(
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

        def post( message )
            message message
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
                        return

                    else
                        fail "Unknown status response: #{status}"
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

        def prepare
            files     = self.executed_file_contents
            files_msg = ""
            files.each do |path, contents|
                files_msg << "#{path}\n"
                files_msg << "```ruby\n#{contents}\n```"
            end

            if files.any?
                msg = <<-EOT
                These are #{files.size} Ruby source code files, which contain a '#{@issue.name}' vulnerability of 
                #{@issue.severity} severity.
                EOT
            else
                msg = <<-EOT
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

                The HTTP response for this resource was:
```
#{@issue.response}
```

                The rendered HTML response body for this resource was:
```html
#{@issue.page.body}
```
            EOT

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
                    Identified by this signature: #{@issue.signature}
                    EOT
                end
            else
                msg << <<-EOT
                The vulnerability was found in the '#{@issue.vector.type}'.
                EOT
            end

            if @issue.remarks.any?
                @issue.remarks.each do |component, remark|
                    msg << <<-EOT
                    The '#{component}' component remarked: #{remark}
                    EOT
                end
            end

            if @issue.platform_name
                msg << <<-EOT
                    The identified technology platform for this issue is '#{@issue.platform_name}'.
                EOT
            end

            msg << "\n#{files_msg}"

            # puts msg
            @client.post msg
        end

        def describe!
            @issue.description =
              join_response_contents(
                @client.post(
                  "How would you describe this vulnerability?"
                )
              )
        end

        def remedy_guidance!
            @issue.remedy_guidance =
              join_response_contents(
                @client.post(
                  "How would you remediate this vulnerability?"
                )
              )
        end

        def remedy_code!
            @issue.remedy_code =
              join_response_contents(
                @client.post(
                  "How would you remediate this vulnerability in code?"
                )
              )
        end

        def exploit!
            @issue.exploit =
              join_response_contents(
                @client.post(
                  "How could a malicious hacker exploit this vulnerability?"
                )
              )
        end

        def patch!
            @issue.patch =
              join_response_contents(
                @client.post(
                  "Fix the #{@issue.name} issue found in the source code files and provide a patch file along " <<
                    "with patching instructions."
                )
              )
        end

        def insights!
            @issue.insights =
              join_response_contents(
                @client.post(
                  "Do you have any insights regarding this specific issue?"
                )
              )
        end

        def report!
            @issue.report =
              join_response_contents(
                @client.post(
                  "Can you please write a report for this issue?"
                )
              )
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
            fail 'Response does not include content.' if !response.include?( 'content' )
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
        msg = "[#{issue.digest}] #{issue.name} in #{issue.vector.type}"
        if issue.active?
            msg << " input '#{issue.affected_input_name}'."
        else
            msg << '.'
        end

        print_status "Processing issue: #{msg}"

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
            print_info "Djin: [#{issue.digest}] Getting remedy guidance."
            djin.remedy_guidance!
        rescue => e
            print_exception e
        end

        begin
            print_info "Djin: [#{issue.digest}] Getting remedy code."
            djin.remedy_code!
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
        # Start a pool that:
        #
        # * Has no workers by default;
        # * Can reach up to THREADS workers max;
        # * Once jobs exceed MAX_QUEUE, new jobs will run in the caller thread,
        #   instead of being rejected or letting the queue grow without bounds.
        @thread_pool ||= Concurrent::ThreadPoolExecutor.new(
          min_threads:     0,
          max_threads:     THREADS,
          max_queue:       MAX_QUEUE,
          fallback_policy: :caller_runs
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
                                 description: 'An OpenAI API key with all permissions granted.'
            )
          ]
        }
    end

end
