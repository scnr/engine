child :state, :State do
    define :on

    def_on :change do |&block|
        SCNR::Engine::Framework.unsafe.state.on_state_change( &block )
    end
end
