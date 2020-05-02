//! Corresponds to `Engine::Parser`.

pub mod sax;
pub mod document;

pub fn initialize() {
    document::initialize();
}
