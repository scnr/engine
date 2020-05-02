//! Corresponds to `String`.

use std::collections::HashMap;
use ruru::{Class, Object, Boolean, RString};
use regex;
use regex::Regex;
use std::sync::Mutex;

lazy_static! {
    static ref COMPILED: Mutex<HashMap<String, Regex>> = Mutex::new( HashMap::new() );
}

fn compile_and_match( pattern: String, haystack: &str ) -> bool {
    let s            = pattern.clone();
    let mut compiled = COMPILED.lock().unwrap();

    compiled.entry( pattern ).or_insert_with( || Regex::new( &s ).unwrap() );

    compiled[&s].is_match( haystack )
}

unsafe_methods!(
    RString,
    itself,

    fn include_ext( needle: RString ) -> Boolean {
        Boolean::new(
            compile_and_match(
                regex::escape( needle.to_str_unchecked() ),
                itself.to_str_unchecked()
            )
        )
    }

);

/// Adds Ruby hooks for:
///
/// * `String#include_ext?`
pub fn initialize() {
    Class::from_existing( "String" ).define(|itself| {
        itself.def( "include_ext?", include_ext );
    });
}
