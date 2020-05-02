//! Corresponds to `Engine::Browser::Parts`.

pub mod http;

pub fn initialize() {
    http::initialize();
}
