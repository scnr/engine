//! Corresponds to `Engine::HTTP::Headers`.

use ruru::{Class, Object, RString};

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

class!( Headers );
unsafe_methods!(
    Headers,
    _itself,

    fn format_field_name_ext( data: RString ) -> RString {
        RString::new( &format_field_name( data.to_str_unchecked() ) )
    }
);

/// Adds Ruby hooks for:
///
/// * `Engine::Support::Signature.format_field_name_ext`
pub fn initialize() {
    Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
        get_nested_class( "HTTP" ).
        get_nested_class( "Headers" ).define( |itself| {

        itself.def_self( "format_field_name_ext", format_field_name_ext );

    });
}

