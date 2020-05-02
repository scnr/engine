//! Corresponds to `Engine::URI`.

use std::str::FromStr;
use std::net::Ipv4Addr;
use std::str::pattern::Pattern;

use utilities;
use url::{Url, percent_encoding};
use ruru::{Class, Hash as RHash, Fixnum, Object, RString, AnyObject, Symbol, Boolean, NilClass, VM};

#[allow(useless_attribute)]
use std::hash::{Hash, Hasher};
// We'll be hashing lots of words and integers and FnvHasher is best for short data.
use fnv::FnvHasher;

const AMP:   char = '&';
const EQUAL: char = '=';
const AT:    char = '@';
const COLON: char = ':';
const DOT:   char = '.';
const SLASH: char = '/';
const QUERY: char = '?';
const PLUS:  char = '+';
const FRAG:  char = '#';
const SEMICOLON: char = ';';

const PTTH:   &str = ":ptth";
const HTTP:   &str = "http";
const HTTPS:  &str = "https";
const PROTO:  &str = "://";
const JS:     &str = "javascript:";
const DATA:   &str = "data:";
const DOT_S:  &str = ".";

const DOUBLE_SLASH:  &str = "//";
const ENCODED_SPACE: &str = "%20";
const HTTP_PORT_S:   &str = "80";
const SLASH_S:       &str = "/";
const AMP_S:         &str = "&";

const HTTP_PORT:  u16 = 80;
const HTTPS_PORT: u16 = 443;

define_encode_set! {
    /// Used to encode path segments.
    pub PATH_SEGMENT_ENCODE_SET = [percent_encoding::PATH_SEGMENT_ENCODE_SET] | { SEMICOLON, '[', ']', '^' }
}

define_encode_set! {
    /// Used to encode query name/value pairs.
    pub QUERY_ENCODE_SET = [percent_encoding::QUERY_ENCODE_SET] | { '[', ']', '^', AMP, PLUS }
}

fn hash_obj<T: Hash>(t: &T) -> u64 {
    let mut hasher = FnvHasher::default();
    t.hash( &mut hasher );
    hasher.finish()
}

/// Splits the string to `limit` pieces at the most, where `delimeter` is found.
fn splitn_to_vector<'a, P: Pattern<'a>>( string: &'a str, delimeter: P, limit: usize ) -> Vec<String> {
    let mut vector:Vec<_> = vec![];

    for split in string.splitn( limit, delimeter ) {
        vector.push( split.to_string() );
    }

    vector
}

fn split_to_vector<'a, P: Pattern<'a>>( string: &'a str, delimeter: P ) -> Vec<String> {
    let mut vector:Vec<_> = vec![];

    for split in string.split( delimeter ) {
        vector.push( split.to_string() );
    }

    vector
}

/// URL representation.
#[derive(Hash)]
#[derive(PartialEq)]
pub struct URI {
    scheme:   Option<String>, // Valid schemes are `http` and `https`.
    userinfo: Option<String>,
    host:     Option<String>,
    port:     Option<u16>,
    path:     Option<String>,
    query:    Option<String>
}

impl URI {

    fn new( url: &str ) -> Self {
        URI::fast_parse( url )
    }

    fn is_invalid( &self ) -> bool {
        if self.scheme.is_some() { return false }
        if self.userinfo.is_some() { return false }
        if self.port.is_some() && self.port.unwrap() > 0 { return false }
        if self.host.is_some() { return false }
        if self.path.is_some() { return false }
        if self.query.is_some() { return false }

        true
    }

    fn is_absolute( &self ) -> bool {
        self.scheme.is_some()
    }

    fn is_relative( &self ) -> bool {
        !self.is_absolute()
    }

    fn query_parameters( &self ) -> Vec<Vec<String>>{
        if let Some(ref query) = self.query {
            let mut params = vec![];
            for pair in query.split( AMP ) {
                let mut pair_iter = pair.splitn( 2, EQUAL );

                if let Some(n) = pair_iter.next() {
                    let name = URI::decode( n );

                    let value;
                    if let Some(v) = pair_iter.next() {
                        value = URI::decode( v );
                    } else {
                        value = String::new();
                    }

                    params.push( vec![ name, value ]);
                    continue
                }
            }

            params
        } else {
            return vec![]
        }
    }

    fn as_absolute( &mut self, reference: &URI ) -> &Self {
        // Complicated, delegate the path merge to the url crate.
        if let Some(ref path) = self.path.clone() {

            self.path = Some(
                Url::parse( &reference.to_s() ).unwrap().join( path ).unwrap().path().to_string()
            );

        // That's an easy one, just use the reference path.
        } else {
            self.path = reference.path.clone();
        }

        if self.scheme.is_none() {
            self.scheme = reference.scheme.clone();
        }

        if self.userinfo.is_none() {
            self.userinfo = reference.userinfo.clone();
        }

        if self.host.is_none() {
            self.host = reference.host.clone();
        }

        if self.port.is_none() {
            self.port = reference.port;
        }

        self
    }

    fn without_query( &self ) -> String {
        let mut string = String::new();

        if let Some(ref scheme) = self.scheme {
            string.push_str( scheme );
            string.push_str( PROTO );
        }

        if let Some(ref userinfo) = self.userinfo {
            string.push_str( userinfo );
            string.push( AT );
        }

        if let Some(ref host) = self.host {
            string.push_str( host );

            if let Some(port) = self.port {
                if let Some(ref scheme) = self.scheme {
                    if (scheme == HTTP && port != HTTP_PORT ) || (scheme == HTTPS && port != HTTPS_PORT ) {
                        string.push( COLON );
                        string.push_str( &port.to_string() );
                    }
                } else {
                    string.push( COLON );
                    string.push_str( &port.to_string() );
                }
            }
        }

        if let Some(ref path) = self.path {
            string.push_str( path );
        }

        string
    }

    fn up_to_port( &self ) -> String {
        let mut string = String::new();

        if let Some(ref scheme) = self.scheme {
            string.push_str( scheme );
            string.push_str( PROTO );
        }

        if let Some(ref userinfo) = self.userinfo {
            string.push_str( userinfo );
            string.push( AT );
        }

        if let Some(ref host) = self.host {
            string.push_str( host );

            if let Some(port) = self.port {
                if let Some(ref scheme) = self.scheme {
                    if (scheme == HTTP && port != HTTP_PORT ) || (scheme == HTTPS && port != HTTPS_PORT ) {
                        string.push( COLON );
                        string.push_str( &port.to_string() );
                    }
                } else {
                    string.push( COLON );
                    string.push_str( &port.to_string() );
                }
            }
        }

        string
    }

    fn up_to_path( &self ) -> String {
        if self.path.is_none() { return self.without_query() }

        if let Some(ref path) = self.path {
            if path.ends_with( '/' ) { return self.without_query() }

            let mut string = String::new();

            if let Some(ref scheme) = self.scheme {
                string.push_str( scheme );
                string.push_str( PROTO );
            }

            if let Some(ref userinfo) = self.userinfo {
                string.push_str( userinfo );
                string.push( AT );
            }

            if let Some(ref host) = self.host {
                string.push_str( host );

                if let Some(port) = self.port {
                    if let Some(ref scheme) = self.scheme {
                        if (scheme == HTTP && port != HTTP_PORT ) || (scheme == HTTPS && port != HTTPS_PORT ) {
                            string.push( COLON );
                            string.push_str( &port.to_string() );
                        }
                    } else {
                        string.push( COLON );
                        string.push_str( &port.to_string() );
                    }
                }
            }

            let mut splits = split_to_vector( path, SLASH );
            splits.pop();

            string.push_str( &splits.join( SLASH_S ) );
            string.push( SLASH );

            string
        } else {
            self.without_query()
        }
    }

    fn to_s( &self ) -> String {
        let mut string = String::new();

        if let Some(ref scheme) = self.scheme {
            string.push_str( scheme );
            string.push_str( PROTO );
        }

        if let Some(ref userinfo) = self.userinfo {
            string.push_str( userinfo );
            string.push( AT );
        }

        if let Some(ref host) = self.host {
            string.push_str( host );

            if let Some(port) = self.port {
                if let Some(ref scheme) = self.scheme {
                    if (scheme == HTTP && port != HTTP_PORT ) || (scheme == HTTPS && port != HTTPS_PORT) {
                        string.push( COLON );
                        string.push_str( &port.to_string() );
                    }
                } else {
                    string.push( COLON );
                    string.push_str( &port.to_string() );
                }
            }
        }

        if let Some(ref path) = self.path {
            string.push_str( path );
        }

        if let Some(ref query) = self.query {
            string.push( QUERY );
            string.push_str( query );
        }

        string
    }

    fn domain( &self ) -> Option<String> {
        if let Some(ref host) = self.host {
            if self.is_ip_address() { return self.host.clone() }

            let mut splits = host.split( DOT ).collect::<Vec<&str>>();

            if splits.len() == 1 { return Some(splits[0].to_string()) }
            if splits.len() == 2 { return self.host.clone() }

            splits.remove( 0 );
            return Some(splits.join( DOT_S ))
        }

        None
    }

    fn is_ip_address( &self ) -> bool {
        if let Some(ref host) = self.host {
            return Ipv4Addr::from_str( host ).is_ok()
        }

        false
    }

    fn resource_name( &self ) -> Option<String> {
        if let Some(ref path) = self.path {
            for resource in path.split( SLASH ).rev() {
                if resource.is_empty() { continue }
                return Some( resource.to_string() )
            }
        }

        None
    }

    fn resource_extension( &self ) -> Option<String> {
        if let Some(ref path) = self.path {
            if !path.contains( DOT ) { return None }

            if let Some(ext) = path.split( DOT ).last() {
                return Some( ext.to_string() )
            }
        }

        None
    }

    fn user( &self ) -> Option<String> {
        if let Some(ref userinfo) = self.userinfo {
            if let Some(user) = userinfo.split( COLON ).next() {
                return Some(user.to_string())
            }
        }

        None
    }

    fn password( &self ) -> Option<String> {
        if let Some(ref userinfo) = self.userinfo {
            if let Some(pass) = userinfo.split( COLON ).last() {
                return Some(pass.to_string())
            }
        }

        None
    }

    fn dup( &self ) -> URI {
        URI {
            scheme:   self.scheme.clone(),
            userinfo: self.userinfo.clone(),
            host:     self.host.clone(),
            port:     self.port,
            path:     self.path.clone(),
            query:    self.query.clone()
        }
    }

    fn ahash( &self ) -> u64 {
        hash_obj( &self )
    }

    fn inspect( &self ) -> String {
        format!( "#<SCNR::Engine::URIExt {}>", self.to_s() )
    }

    /// URL encodes `input` based on `PATH_SEGMENT_ENCODE_SET` rules.
    fn encode_path( input: &str ) -> String {
        percent_encoding::percent_encode(
            input.as_bytes(),
            PATH_SEGMENT_ENCODE_SET
        ).collect::<String>()
    }

    /// URL encodes `input` based on `QUERY_ENCODE_SET` rules.
    fn encode_query( input: &str ) -> String {
        percent_encoding::percent_encode(
            input.as_bytes(),
            QUERY_ENCODE_SET
        ).collect::<String>()
    }

    pub fn decode( input: &str ) -> String {
        let i = input.replace( PLUS, ENCODED_SPACE );
        match percent_encoding::percent_decode( i.as_bytes() ).decode_utf8() {
            Ok(v)  => v.into_owned(),
            Err(_) => i.clone()
        }
    }

    pub fn fast_parse( u: &str ) -> URI {
        let mut result = URI {
            scheme:   None,
            userinfo: None,
            host:     None,
            port:     None,
            path:     None,
            query:    None
        };

        let mut url = u.to_string();

        if url.is_empty() { return result }
        if url.starts_with( FRAG ) { return result }

        let lowercase_url = url.to_lowercase();
        if lowercase_url.starts_with( JS ) { return result }
        if lowercase_url.starts_with( DATA ) { return result }

        // Decode HTML entities:
        url = utilities::html_decode( &url );

        // One to rip apart.
        url = url.clone();
        url = url.split( FRAG ).next().unwrap().to_string();

        // One for reference.
        let c_url = url.clone();

        let mut schemeless = false;
        if url.starts_with( DOUBLE_SLASH ) {
            schemeless = true;
            for char in PTTH.chars() {
                url.insert( 0, char );
            }
        }

        let mut has_path   = true;
        let mut has_scheme = false;
        let splits: Vec<_> = splitn_to_vector( &url, COLON, 2 );

        // Make sure we've got a valid scheme, if not then we can't tell much from the string,
        // other than possibly a path, but we'll get to that later.
        if !splits.is_empty() {

            let scheme = splits[0].to_lowercase();
            if scheme == HTTP || scheme == HTTPS {
                // Split the url in 2, scheme/rest.
                let mut splits = splitn_to_vector( &url, PROTO, 2 );

                // Got the scheme, we're off to a good start.
                has_scheme = true;
                splits.remove(0);
                result.scheme = Some(scheme);

                if !splits.is_empty() {
                    // Get the rest of the url.
                    url = splits.remove(0);

                    // Next up, we're going for the user info and the host, ignore any query or path.
                    splits = splitn_to_vector(
                        &splitn_to_vector( &url, QUERY, 2 )[0],
                        SLASH,
                        2
                    );

                    let userinfo_host = splits.remove(0);

                    // The rest is the path, save it for later.
                    if !splits.is_empty() {
                        url = splits.remove(0);
                    } else {
                        url = "".to_string();
                    }

                    // Extract the username and password if there are any.
                    let mut splits = splitn_to_vector( &userinfo_host.to_string(), AT, 2 );
                    if splits.len() > 1 {
                        result.userinfo = Some(splits.remove(0));
                    }

                    // Go for the host and port.
                    if !splits.is_empty() {
                        let splits = splitn_to_vector( &splits.remove(0), COLON, 2 );

                        result.host = Some(splits[0].to_lowercase());

                        if splits.len() == 2 {
                            let port = &splits[1];
                            if !port.is_empty() && port != HTTP_PORT_S {
                                if let Ok(port_number) = port.parse::<u16>() {
                                    result.port = Some( port_number );
                                }
                            }
                        }

                    } else {
                        has_path = false;
                    }
                } else {
                    has_path = false;
                }
            } else {
                schemeless = true;
            }
        }

        if has_path {
            let mut splits = splitn_to_vector( &url, QUERY, 2 );
            let mut path = splits.remove(0);
            splits = splitn_to_vector( &path, SEMICOLON, 2 );
            path = splits.remove(0);

            if !path.is_empty() {
                let had_root_slash = path.starts_with( SLASH );
                let had_end_slash  = path.ends_with( SLASH );

                let mut encoded_path_segments = vec![];
                for segment in path.split( SLASH ) {
                    if segment.is_empty() { continue }

                    encoded_path_segments.push(
                        URI::encode_path( &URI::decode( segment ) )
                    )
                }
                path = encoded_path_segments.join( SLASH_S );

                // If there's a scheme then this is an absolute URL, make sure there's a / in from
                // of the path. If this is a relative one, don't.
                if had_root_slash || has_scheme {
                    path.insert( 0, SLASH );
                }

                if had_end_slash && !path.ends_with( SLASH ) {
                    path.push( SLASH );
                }

                // Normalize path, convert multiple sequential / with only one.
                result.path = Some(path);
            } else {
                has_path = false;
            }

            splits = splitn_to_vector( &c_url, QUERY, 2 );
            if splits.len() > 1 {
                let query = splits.pop().unwrap();
                let mut encoded_queries:Vec<String> = vec![];

                for q in query.split( AMP ) {
                    encoded_queries.push( URI::encode_query( &URI::decode( q ) ) );
                }

                result.query = Some(encoded_queries.join( AMP_S ));
            }
        }

        if schemeless {
            result.scheme = None;
        } else if !has_path {
            result.path = Some(SLASH.to_string());
        }

        result
    }

    fn free( &mut self ) {
        self.scheme   = None;
        self.host     = None;
        self.port     = None;
        self.userinfo = None;
        self.path     = None;
        self.query    = None;
    }

}

fn string_option_to_any( option: &Option<String> ) -> AnyObject {
    if let Some(ref string) = *option {
        RString::new( string ).to_any_object()
    } else {
        NilClass::new().to_any_object()
    }
}

fn u16_option_to_any( option: Option<u16> ) -> AnyObject {
    if option.is_none() {
        NilClass::new().to_any_object()
    } else {
        Fixnum::new( i64::from( option.unwrap() ) ).to_any_object()
    }
}

fn rstring_to_option( option: &RString ) -> Option<String> {
    if option.is_nil() {
        None
    } else {
        let string = option.to_string_unchecked();

        if string.is_empty() {
            None
        } else {
            Some( string )
        }
    }
}

fn fixnum_to_option( option: &AnyObject ) -> Option<u16> {
    if option.is_nil() {
        return None
    } else if let Ok(port) = option.try_convert_to::<Fixnum>() {
        return Some( port.to_i64() as u16 )
    } else if let Ok(sport) = option.try_convert_to::<RString>() {
        return Some( sport.to_str_unchecked().parse::<u16>().unwrap() )
    }

    VM::raise( Class::from_existing( "ArgumentError" ), "Invalid argument." );
    None
}

wrappable_struct!( URI, URIWrapper, URI_WRAPPER );

class!( URIExt );
unsafe_methods!(
    URIExt,
    _itself,

    fn uri_new_ext( data: RString ) -> AnyObject {
        let uri = URI::new( data.to_str_unchecked() );

        if uri.is_invalid() {
            VM::raise(
                Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
                    get_nested_class( "URI" ).get_nested_class( "Error" ),
                "Failed to parse URL."
            );
        }

        Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
            get_nested_class( "URIExt" ).wrap_data( uri, &*URI_WRAPPER )
    }

    fn uri_free_ext() -> NilClass {
        _itself.get_data( &*URI_WRAPPER ).free();
        NilClass::new()
    }

    fn fast_parse_ext( input: RString ) -> RHash {
        let url = URI::fast_parse( input.to_str_unchecked() );

        let mut result = RHash::new();

        if let Some(scheme) = url.scheme {
            result.store( Symbol::new( "scheme" ), RString::new( &scheme ) );
        }

        if let Some(userinfo) = url.userinfo {
            result.store( Symbol::new( "userinfo" ), RString::new( &userinfo ) );
        }

        if let Some(host) = url.host {
            result.store( Symbol::new( "host" ), RString::new( &host ) );
        }

        if let Some(port) = url.port {
            result.store( Symbol::new( "port" ), Fixnum::new( i64::from( port ) ) );
        }

        if let Some(path) = url.path {
            result.store( Symbol::new( "path" ), RString::new( &path ) );
        }

        if let Some(query) = url.query {
            result.store( Symbol::new( "query" ), RString::new( &query ) );
        }

        result
    }

    fn uri_query_ext() -> AnyObject {
        string_option_to_any( &_itself.get_data( &*URI_WRAPPER ).query )
    }

    fn uri_query_parameters_ext() -> RHash {
        let mut params = RHash::new();
        for param in &_itself.get_data( &*URI_WRAPPER ).query_parameters() {
            params.store( RString::new( &param[0] ), RString::new( &param[1] ) );
        }
        params
    }

    fn uri_to_absolute_bang_ext( reference: AnyObject ) -> AnyObject {
        _itself.get_data( &*URI_WRAPPER ).as_absolute( reference.get_data( &*URI_WRAPPER ) );
        _itself.to_any_object()
    }

    fn uri_set_query_ext( data: RString ) -> RString {
        _itself.get_data( &*URI_WRAPPER ).query = rstring_to_option( &data );
        data
    }

    fn uri_userinfo_ext() -> AnyObject {
        string_option_to_any( &_itself.get_data( &*URI_WRAPPER ).userinfo )
    }

    fn uri_set_userinfo_ext( data: RString ) -> RString {
        _itself.get_data( &*URI_WRAPPER ).userinfo = rstring_to_option( &data );
        data
    }

    fn uri_port_ext() -> AnyObject {
        u16_option_to_any( _itself.get_data( &*URI_WRAPPER ).port )
    }

    fn uri_set_port_ext( data: AnyObject ) -> AnyObject {
        _itself.get_data( &*URI_WRAPPER ).port = fixnum_to_option( &data );
        data.to_any_object()
    }

    fn uri_host_ext() -> AnyObject {
        string_option_to_any( &_itself.get_data( &*URI_WRAPPER ).host )
    }

    fn uri_set_host_ext( data: RString ) -> RString {
        _itself.get_data( &*URI_WRAPPER ).host = rstring_to_option( &data );
        data
    }

    fn uri_path_ext() -> AnyObject {
        string_option_to_any( &_itself.get_data( &*URI_WRAPPER ).path )
    }

    fn uri_set_path_ext( data: RString ) -> RString {
        _itself.get_data( &*URI_WRAPPER ).path = rstring_to_option( &data );
        data
    }

    fn uri_scheme_ext() -> AnyObject {
        string_option_to_any( &_itself.get_data( &*URI_WRAPPER ).scheme )
    }

    fn uri_set_scheme_ext( data: RString ) -> RString {
        _itself.get_data( &*URI_WRAPPER ).scheme = rstring_to_option( &data );
        data
    }

    fn uri_user_ext() -> AnyObject {
        string_option_to_any( &_itself.get_data( &*URI_WRAPPER ).user() )
    }

    fn uri_password_ext() -> AnyObject {
        string_option_to_any( &_itself.get_data( &*URI_WRAPPER ).password() )
    }

    fn uri_domain_ext() -> AnyObject {
        string_option_to_any( &_itself.get_data( &*URI_WRAPPER ).domain() )
    }

    fn uri_is_ip_address_ext() -> Boolean {
        Boolean::new( _itself.get_data( &*URI_WRAPPER ).is_ip_address() )
    }

    fn uri_up_to_path_ext() -> RString {
//        println!( "{:?}", _itself.get_data( &*URI_WRAPPER ).up_to_path() );
        RString::new( &_itself.get_data( &*URI_WRAPPER ).up_to_path() )
    }

    fn uri_up_to_port_ext() -> RString {
        RString::new( &_itself.get_data( &*URI_WRAPPER ).up_to_port() )
    }

    fn uri_without_query_ext() -> RString {
        RString::new( &_itself.get_data( &*URI_WRAPPER ).without_query() )
    }

    fn uri_resource_name_ext() -> AnyObject {
        string_option_to_any( &_itself.get_data( &*URI_WRAPPER ).resource_name() )
    }

    fn uri_resource_extension_ext() -> AnyObject {
        string_option_to_any( &_itself.get_data( &*URI_WRAPPER ).resource_extension() )
    }

    fn uri_to_s_ext() -> RString {
        RString::new( &_itself.get_data( &*URI_WRAPPER ).to_s() )
    }

    fn uri_is_absolute_ext() -> Boolean {
        Boolean::new( _itself.get_data( &*URI_WRAPPER ).is_absolute() )
    }

    fn uri_is_relative_ext() -> Boolean {
        Boolean::new( _itself.get_data( &*URI_WRAPPER ).is_relative() )
    }

    fn uri_dup_ext() -> AnyObject {
        Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
            get_nested_class( "URIExt" ).
                wrap_data( _itself.get_data( &*URI_WRAPPER ).dup(),
                &*URI_WRAPPER
            )
    }

    fn uri_is_equal_ext( other: AnyObject ) -> Boolean {
        Boolean::new( _itself.get_data( &*URI_WRAPPER ) == other.get_data( &*URI_WRAPPER ) )
    }

    fn uri_decode_ext( input: RString ) -> RString {
        RString::new( &URI::decode( input.to_str_unchecked() ) )
    }

    fn uri_hash_ext() -> Fixnum {
        Fixnum::new( _itself.get_data( &*URI_WRAPPER ).ahash() as i64 )
    }

    fn uri_inspect_ext() -> RString {
        RString::new( &_itself.get_data( &*URI_WRAPPER ).inspect() )
    }
);

pub fn initialize() {

    Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
        define_nested_class(
            "URIExt",
            Some( &Class::from_existing( "Data" ) )
        ).define( |_itself| {

        _itself.def_self( "new", uri_new_ext );
        _itself.def_self( "fast_parse", fast_parse_ext );
        _itself.def_self( "_decode_ext", uri_decode_ext );

        _itself.def( "free", uri_free_ext );
        _itself.def( "to_absolute!", uri_to_absolute_bang_ext );
        _itself.def( "query_parameters", uri_query_parameters_ext );

        _itself.def( "query", uri_query_ext );
        _itself.def( "query=", uri_set_query_ext );

        _itself.def( "userinfo", uri_userinfo_ext );
        _itself.def( "userinfo=", uri_set_userinfo_ext );

        _itself.def( "port", uri_port_ext );
        _itself.def( "port=", uri_set_port_ext );

        _itself.def( "host", uri_host_ext );
        _itself.def( "host=", uri_set_host_ext );

        _itself.def( "path", uri_path_ext );
        _itself.def( "path=", uri_set_path_ext );

        _itself.def( "scheme", uri_scheme_ext );
        _itself.def( "scheme=", uri_set_scheme_ext );

        _itself.def( "domain", uri_domain_ext );
        _itself.def( "user", uri_user_ext );
        _itself.def( "password", uri_password_ext );

        _itself.def( "ip_address?", uri_is_ip_address_ext );
        _itself.def( "up_to_path", uri_up_to_path_ext );
        _itself.def( "up_to_port", uri_up_to_port_ext );
        _itself.def( "without_query", uri_without_query_ext );
        _itself.def( "resource_name", uri_resource_name_ext );
        _itself.def( "resource_extension", uri_resource_extension_ext );
        _itself.def( "dup", uri_dup_ext );
        _itself.def( "to_s", uri_to_s_ext );
        _itself.def( "absolute?", uri_is_absolute_ext );
        _itself.def( "relative?", uri_is_relative_ext );
        _itself.def( "persistent_hash", uri_hash_ext );
        _itself.def( "hash", uri_hash_ext );
        _itself.def( "==", uri_is_equal_ext );
        _itself.def( "hash", uri_hash_ext );
        _itself.def( "inspect", uri_inspect_ext );

    });

}
