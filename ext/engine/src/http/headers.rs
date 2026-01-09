//! Corresponds to `Engine::HTTP::Headers`.

use magnus::{class, function, Error, RClass, RModule};

const SKIP_SUBSTRING: &str = "--";

/// [Reference](http://stackoverflow.com/a/38406885/1889337)
fn capitalize( s: &str ) -> String {
    let mut c = s.chars();
    match c.next() {
        Some(f) => f.to_uppercase().chain( c ).collect(),
        None    => String::new(),
    }
}

/// Formats header names.
///
/// _Corresponds to `Engine::HTTP::Headers#format_field_name`._
pub fn format_field_name( name: &str ) -> String {
    // If there's a '--' somewhere in there then skip it, it probably is an
    // audit payload.
    if name.contains( SKIP_SUBSTRING ) {
        return name.to_string();
    }

    let n             = name.to_lowercase();
    let mut iter      = n.split( '-' ).peekable();
    let mut formatted = String::with_capacity( name.len() );

    loop {
        formatted.push_str( &capitalize( iter.next().unwrap() ) );
        if iter.peek().is_none() { return formatted }

        formatted.push( '-' );
    }
}

fn format_field_name_ext(data: String) -> String {
    format_field_name(&data)
}

/// Adds Ruby hooks for:
///
/// * `Engine::Support::Signature.format_field_name_ext`
pub fn initialize() -> Result<(), Error> {
    let scnr_ns = class::object().const_get::<_, RModule>("SCNR")?;
    let engine_ns = scnr_ns.const_get::<_, RModule>("Engine")?;
    let rust_ns = engine_ns.define_module("Rust")?;
    let http_ns = rust_ns.define_module("HTTP")?;
    let headers_class = http_ns.define_class("Headers", class::object())?;

    headers_class.define_singleton_method("format_field_name_ext", function!(format_field_name_ext, 1))?;

    Ok(())
}
