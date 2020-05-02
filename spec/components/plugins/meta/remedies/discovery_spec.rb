require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before do
        options.url          = url
        options.paths.checks = nil

        framework.checks.lib = options.paths.checks
        framework.checks.load :common_files
    end

    context 'when issues have similar response bodies' do
        it 'marks them as untrusted and adds remarks' do
            run

            expect(framework.report.issues).to be_any

            framework.report.issues.each do |issue|
                expect(issue).to be_untrusted
                expect(issue.remarks).to include :meta_analysis
            end
        end
    end

end
