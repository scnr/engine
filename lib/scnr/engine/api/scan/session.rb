child :session, :Session do

    def_to :login do |&block|
        SCNR::Engine::UnsafeFramework.session.record_login_sequence &block
    end

    def_to :check do |&block|
        SCNR::Engine::UnsafeFramework.session.record_login_check &block
    end
end
