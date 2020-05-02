//! Corresponds to `Engine::Element`.

pub mod header;
pub mod cookie;

pub fn initialize() {
    header::initialize();
    cookie::initialize();
}
