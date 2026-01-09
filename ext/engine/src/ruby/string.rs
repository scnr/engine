//! Corresponds to `String`.

use std::collections::HashMap;
use magnus::{class, method, Error, RClass};
use regex;
use regex::Regex;
use std::sync::Mutex;

lazy_static! {
    static ref COMPILED: Mutex<HashMap<String, Regex>> = Mutex::new( HashMap::new() );
}

fn compile_and_match( pattern: String, haystack: &str ) -> bool {
    let s            = pattern.clone();
    let mut compiled = COMPILED.lock().unwrap();

    compiled.entry( pattern ).
        or_insert_with( || Regex::new( &s ).unwrap() ).
        is_match( haystack )
}

fn include_ext(rb_self: String, needle: String) -> bool {
    compile_and_match(
        regex::escape(&needle),
        &rb_self
    )
}

/// Adds Ruby hooks for:
///
/// * `String#include_ext?`
pub fn initialize() -> Result<(), Error> {
    let string_class = class::object().const_get::<_, RClass>("String")?;
    string_class.define_method("include_ext?", method!(include_ext, 1))?;
    Ok(())
}
