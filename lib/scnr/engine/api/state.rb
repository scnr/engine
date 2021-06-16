child :state, :State do
    UnsafeFramework = SCNR::Engine::Framework.unsafe

    define :on

    def_on :change do |&block|
        UnsafeFramework.state.on_state_change( &block )
    end

end
