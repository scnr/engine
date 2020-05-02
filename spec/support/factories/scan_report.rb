Factory.define :report_data do
    issues = SCNR::Engine::Data::Issues.new

    (0..10).map do |i|
        issues << Factory[:passive_issue].tap { |issue| issue.vector.action += i.to_s }
        issues << Factory[:active_issue].tap { |issue| issue.vector.action += i.to_s }
    end

    {
        seed:     SCNR::Engine::Utilities.random_seed,
        options:  SCNR::Engine::Options.to_hash,
        sitemap:  { SCNR::Engine::Options.url => 200 },
        issues:   issues,
        plugins:  {
            plugin_name: {
                results: 'stuff',
                options: [
                    SCNR::Engine::Component::Options::MultipleChoice.new(
                        'some_name',
                        description:  'Some description.',
                        default:      'default_value',
                        choices: %w(available values go here)
                    )
                ]
            }
        },
        start_datetime:  Time.now - 10_000,
        finish_datetime: Time.now
    }
end

Factory.define :report do
    SCNR::Engine::Report.new Factory[:report_data]
end

Factory.define :report_empty do
    SCNR::Engine::Report.new
end
