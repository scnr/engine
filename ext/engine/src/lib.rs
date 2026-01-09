//! Engine native extension, used to give the system a performance boost during known Ruby bottlenecks.

#![feature(pattern)]

#[macro_use]
extern crate magnus;

#[macro_use]
extern crate url;

#[macro_use]
extern crate lazy_static;

extern crate regex;

extern crate fnv;

#[macro_use]
extern crate tendril;

#[macro_use]
extern crate html5ever;

pub mod ruby;
pub mod utilities;
pub mod uri;
pub mod support;
pub mod http;
pub mod parser;
pub mod element;
pub mod browser;

use magnus::{Error, define_global_function, function};

/// Initializes all Rust modules and Ruby hooks.
#[magnus::init]
fn init() -> Result<(), Error> {
    ruby::initialize()?;
    utilities::initialize()?;
    uri::initialize()?;
    support::initialize()?;
    http::initialize()?;
    parser::initialize()?;
    element::initialize()?;
    browser::initialize()?;
    Ok(())
}
