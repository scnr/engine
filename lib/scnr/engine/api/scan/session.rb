child :session, :Session do
    UnsafeFramework = SCNR::Engine::Framework.unsafe

    def_to :login do |&block|
        UnsafeFramework.session.record_login_sequence &block
    end

    def_to :check do |&block|
        UnsafeFramework.session.record_login_check &block
    end
end
