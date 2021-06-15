child :session, :Session do
    define :to

    def_to :login do |&block|
        SCNR::Engine::Framework.unsafe.session.record_login_sequence &block
    end

    def_to :check do |&block|
        SCNR::Engine::Framework.unsafe.session.record_login_check &block
    end
end
