//! Corresponds to `Engine::HTTP`.

pub mod headers;

pub fn initialize() {
    headers::initialize();
}
