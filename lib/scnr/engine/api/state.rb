child :state, :State do

    def_on :change do |&block|
        SCNR::Engine::UnsafeFramework.state.on_state_change( &block )
    end

end
