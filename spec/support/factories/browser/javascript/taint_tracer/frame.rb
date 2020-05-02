Factory.define :frame_data do
    {
        function: Factory[:called_function],
        line:     202
    }
end

Factory.define :frame do
    SCNR::Engine::Browser::Javascript::TaintTracer::Frame.new( Factory[:frame_data] )
end
