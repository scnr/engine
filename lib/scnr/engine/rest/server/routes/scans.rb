=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Rest
class Server
module Routes

module Scans

    def self.registered( app )

        # List scans.
        app.get '/scans' do
            update_from_queue

            json instances.keys.inject({}){ |h, k| h.merge! k => {} }
        end

        # Create
        app.post '/scans' do
            max_utilization! if !dispatcher && System.max_utilization?

            options = ::JSON.load( request.body.read ) || {}

            instance = get_instance
            max_utilization! if !instance

            handle_error proc { instance.shutdown } do
                instance.scan( options )
            end

            instances[instance.token] = instance

            json id: instance.token
        end

        # Progress
        app.get '/scans/:scan' do
            ensure_scan!

            session[params[:scan]] ||= {
                seen_issues:  [],
                seen_errors:  0,
                seen_sitemap: 0
            }

            data = instance_for( params[:scan] ) do |instance|
                instance.progress(
                    with:    [
                                 :issues,
                                 errors:  session[params[:scan]][:seen_errors],
                                 sitemap: session[params[:scan]][:seen_sitemap]
                             ],
                    without: [
                                 issues: session[params[:scan]][:seen_issues]
                             ]
                )
            end

            data[:issues].each do |issue|
                session[params[:scan]][:seen_issues] << issue['digest']
            end

            session[params[:scan]][:seen_errors]  += data[:errors].size
            session[params[:scan]][:seen_sitemap] += data[:sitemap].size

            json data
        end

        app.put '/scans/:scan/queue' do |scan|
            ensure_queue!
            ensure_scan!

            handle_error do
                instance = instances.delete( scan )
                instance.close

                json queue.attach( instance.url, instance.token )
            end
        end

        app.get '/scans/:scan/summary' do
            ensure_scan!

            instance_for( params[:scan] ) do |instance|
                json instance.progress
            end
        end

        app.get '/scans/:scan/report.afr' do
            ensure_scan!
            content_type 'application/octet-stream'

            instance_for( params[:scan] ) do |instance|
                instance.native_report.to_afr
            end
        end

        app.get '/scans/:scan/report.html.zip' do
            ensure_scan!
            content_type 'zip'

            instance_for( params[:scan] ) do |instance|
                instance.report_as( 'html' )
            end
        end

        app.get '/scans/:scan/report.?:format?' do
            ensure_scan!

            params[:format] ||= 'json'

            if !VALID_REPORT_FORMATS.include?( params[:format] )
                halt 400, "Invalid report format: #{h params[:format]}."
            end

            content_type params[:format]

            instance_for( params[:scan] ) do |instance|
                instance.report_as( params[:format] )
            end
        end

        app.put '/scans/:scan/pause' do
            ensure_scan!

            instance_for( params[:scan] ) do |instance|
                json instance.pause
            end
        end

        app.put '/scans/:scan/resume' do
            ensure_scan!

            instance_for( params[:scan] ) do |instance|
                json instance.resume
            end
        end

        # Abort/shutdown
        app.delete '/scans/:scan' do
            ensure_scan!
            id = params[:scan]

            instance = instances[id]
            handle_error { instance.shutdown }

            instances.delete( id ).close

            session.delete params[:scan]

            json nil
        end

    end

end

end
end
end
end
