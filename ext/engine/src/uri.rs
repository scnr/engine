//! Corresponds to `Engine::URI`.

use std::str::FromStr;
use std::net::Ipv4Addr;
use std::str::pattern::Pattern;

use utilities;
use url::{Url, percent_encoding};
use rutie::{Class, Hash as RHash, Fixnum, Object, RString, AnyObject, Symbol, Boolean, NilClass, VM};
use magnus::{class, define_class, function, method, prelude::*, Error, RClass, RModule};
use std::collections::HashMap;

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
#[derive(Clone)]
struct URI {
    scheme:   Option<String>, // Valid schemes are `http` and `https`.
    userinfo: Option<String>,
    host:     Option<String>,
    port:     Option<u16>,
    path:     Option<String>,
    query:    Option<String>
}

impl URI {
    pub fn fast_parse( u: String ) -> URI {
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
                        MutURI::encode_path( &MutURI::decode( segment.to_string() ) )
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
                    encoded_queries.push( MutURI::encode_query( &MutURI::decode( q.to_string() ) ) );
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
}

#[derive(PartialEq)]
#[derive(Clone)]
#[magnus::wrap(class = "SCNR::Engine::URIExt")]
struct MutURI(std::cell::RefCell<URI>);

impl MutURI {
    fn new( url: String ) -> Self {
        Self(std::cell::RefCell::new(URI::fast_parse( url )))
    }

    fn is_invalid( &self ) -> bool {
        if self.scheme().is_some() { return false }
        if self.userinfo().is_some() { return false }
        if self.port().is_some() && self.port().unwrap() > 0 { return false }
        if self.host().is_some() { return false }
        if self.path().is_some() { return false }
        if self.query().is_some() { return false }

        true
    }

    fn mself( &self ) -> std::cell::Ref<URI> {
        self.0.borrow()
    }

    fn is_absolute( &self ) -> bool {
        self.mself().scheme.is_some()
    }

    fn is_relative( &self ) -> bool {
        !self.is_absolute()
    }

    fn query( &self ) -> Option<String> {
        self.mself().query.clone()
    }

    fn port( &self ) -> Option<u16> {
        self.mself().port
    }

    fn query_parameters( &self ) -> HashMap<String, String> {
        if let Some(ref query) = self.query() {
            let mut params = HashMap::new();
            for pair in query.split( AMP ) {
                let mut pair_iter = pair.splitn( 2, EQUAL );

                if let Some(n) = pair_iter.next() {
                    let name = MutURI::decode( n.to_string() );

                    let value;
                    if let Some(v) = pair_iter.next() {
                        value = MutURI::decode( v.to_string() );
                    } else {
                        value = String::new();
                    }

                    params.insert( name, value );
                    continue
                }
            }

            params
        } else {
            return HashMap::new()
        }
    }

    fn without_query( &self ) -> String {
        let mut string = String::new();

        if let Some(ref scheme) = self.scheme() {
            string.push_str( scheme );
            string.push_str( PROTO );
        }

        if let Some(ref userinfo) = self.userinfo() {
            string.push_str( userinfo );
            string.push( AT );
        }

        if let Some(ref host) = self.host() {
            string.push_str( host );

            if let Some(port) = self.port() {
                if let Some(ref scheme) = self.scheme() {
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

        if let Some(ref path) = self.path() {
            string.push_str( path );
        }

        string
    }

    fn up_to_port( &self ) -> String {
        let mut string = String::new();

        if let Some(ref scheme) = self.scheme() {
            string.push_str( scheme );
            string.push_str( PROTO );
        }

        if let Some(ref userinfo) = self.userinfo() {
            string.push_str( userinfo );
            string.push( AT );
        }

        if let Some(ref host) = self.host() {
            string.push_str( host );

            if let Some(port) = self.port() {
                if let Some(ref scheme) = self.scheme() {
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
        if self.path().is_none() { return self.without_query() }

        if let Some(ref path) = self.path() {
            if path.ends_with( '/' ) { return self.without_query() }

            let mut string = String::new();

            if let Some(ref scheme) = self.scheme() {
                string.push_str( scheme );
                string.push_str( PROTO );
            }

            if let Some(ref userinfo) = self.userinfo() {
                string.push_str( userinfo );
                string.push( AT );
            }

            if let Some(ref host) = self.host() {
                string.push_str( host );

                if let Some(port) = self.port() {
                    if let Some(ref scheme) = self.scheme() {
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

        if let Some(ref scheme) = self.mself().scheme {
            string.push_str( scheme );
            string.push_str( PROTO );
        }

        if let Some(ref userinfo) = self.mself().userinfo {
            string.push_str( userinfo );
            string.push( AT );
        }

        if let Some(ref host) = self.host() {
            string.push_str( host );

            if let Some(port) = self.mself().port {
                if let Some(ref scheme) = self.scheme() {
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

        if let Some(ref path) = self.mself().path {
            string.push_str( path );
        }

        if let Some(ref query) = self.mself().query {
            string.push( QUERY );
            string.push_str( query );
        }

        string
    }

    fn domain( &self ) -> Option<String> {
        if let Some(ref host) = self.mself().host {
            if self.is_ip_address() { return self.host() }

            let mut splits = host.split( DOT ).collect::<Vec<&str>>();

            if splits.len() == 1 { return Some(splits[0].to_string()) }
            if splits.len() == 2 { return self.host() }

            splits.remove( 0 );
            return Some(splits.join( DOT_S ))
        }

        None
    }

    fn is_ip_address( &self ) -> bool {
        if let Some(ref host) = self.host() {
            return Ipv4Addr::from_str( host ).is_ok()
        }

        false
    }

    fn resource_name( &self ) -> Option<String> {
        if let Some(ref path) = self.path() {
            for resource in path.split( SLASH ).rev() {
                if resource.is_empty() { continue }
                return Some( resource.to_string() )
            }
        }

        None
    }

    fn resource_extension( &self ) -> Option<String> {
        if let Some(ref path) = self.path() {
            if !path.contains( DOT ) { return None }

            if let Some(ext) = path.split( DOT ).last() {
                return Some( ext.to_string() )
            }
        }

        None
    }

    fn userinfo( &self ) -> Option<String> {
        self.mself().userinfo.clone()
    }

    fn host( &self ) -> Option<String> {
        self.mself().host.clone()
    }

    fn path( &self ) -> Option<String> {
        self.mself().path.clone()
    }

    fn scheme( &self ) -> Option<String> {
        self.mself().scheme.clone()
    }

    fn user( &self ) -> Option<String> {
        if let Some(ref userinfo) = self.userinfo() {
            if let Some(user) = userinfo.split( COLON ).next() {
                return Some(user.to_string())
            }
        }

        None
    }

    fn password( &self ) -> Option<String> {
        if let Some(ref userinfo) = self.userinfo() {
            if let Some(pass) = userinfo.split( COLON ).last() {
                return Some(pass.to_string())
            }
        }

        None
    }

    fn dup( &self ) -> MutURI {
        MutURI(std::cell::RefCell::new(
            URI {
                scheme:   self.scheme(),
                userinfo: self.userinfo(),
                host:     self.host(),
                port:     self.port(),
                path:     self.path(),
                query:    self.query()
            }
        ))
    }

    fn ahash( &self ) -> u64 {
        hash_obj( &self.to_s() )
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

    pub fn decode( input: String ) -> String {
        let i = input.replace( PLUS, ENCODED_SPACE );
        match percent_encoding::percent_decode( i.as_bytes() ).decode_utf8() {
            Ok(v)  => v.into_owned(),
            Err(_) => i.clone()
        }
    }

    fn is_equal( &self, other: &MutURI ) -> bool {
        self == other
    }

    fn free( &self ) {
        let mut muri = self.0.borrow_mut();
        muri.scheme   = None;
        muri.host     = None;
        muri.port     = None;
        muri.userinfo = None;
        muri.path     = None;
        muri.query    = None;
    }

    fn as_absolute( &self, reference: &MutURI ) {
        // println!( "{:?}", reference.inspect() );

        let mut mself = self.0.borrow_mut();

        // Complicated, delegate the path merge to the url crate.
        if let Some(ref path) = mself.path.clone() {

            let uri = Url::parse( &reference.to_s() );
            if uri.is_err() {
                mself.path = None;
            } else {
                // println!( "{:?}", uri.clone().unwrap().join( path ) );

                let join = uri.clone().unwrap().join( path );
                if join.is_err() {
                    mself.path = None;
                } else {
                    mself.path = Some( join.unwrap().path().to_string())
                }
            }

            // That's an easy one, just use the reference path.
        } else {
            mself.path = reference.path();
        }

        if mself.scheme.is_none() {
            mself.scheme = reference.scheme();
        }

        if mself.userinfo.is_none() {
            mself.userinfo = reference.userinfo();
        }

        if mself.host.is_none() {
            mself.host = reference.host();
        }

        if mself.port.is_none() {
            mself.port = reference.port();
        }
    }

    fn set_query( &self, query: Option<String> ) -> Option<String> {
        let mut mself = self.0.borrow_mut();

        if let Some(ref q) = query {
            mself.query = if q.is_empty() { None } else { query.clone() };
        } else {
            mself.query = query.clone();
        }

        mself.query.clone()
    }

    fn set_port( &self, port: Option<u16> ) -> Option<u16> {
        let mut mself = self.0.borrow_mut();
        mself.port = port;
        port
    }

    fn set_userinfo( &self, userinfo: Option<String> ) -> Option<String> {
        let mut mself = self.0.borrow_mut();

        if let Some(ref ui) = userinfo {
            mself.userinfo = if ui.is_empty() { None } else { userinfo.clone() };
        } else {
            mself.userinfo = userinfo.clone();
        }

        mself.userinfo.clone()
    }

    fn set_host( &self, host: Option<String> ) -> Option<String> {
        let mut mself = self.0.borrow_mut();

        if let Some(ref h) = host {
            mself.host = if h.is_empty() { None } else { host.clone() };
        } else {
            mself.host = host.clone();
        }

        mself.host.clone()
    }

    fn set_path( &self, path: Option<String> ) -> Option<String> {
        let mut mself = self.0.borrow_mut();
        mself.path = path.clone();
        path
    }

    fn set_scheme( &self, scheme: Option<String> ) -> Option<String> {
        let mut mself = self.0.borrow_mut();

        if let Some(ref s) = scheme {
            mself.scheme = if s.is_empty() { None } else { scheme.clone() };
        } else {
            mself.scheme = scheme.clone();
        }

        mself.scheme.clone()
    }
}

#[magnus::init]
pub fn init() -> Result<(), Error> {
    let scnr_ns = class::object().const_get::<_, RModule>("SCNR").unwrap();
    let engine_ns = scnr_ns.const_get::<_, RModule>( "Engine" ).unwrap();
    // let rust_ns = engine_ns.define_class( "Rust", class::object() ).unwrap();

    let class = engine_ns.define_class( "URIExt", class::object() )?;

    class.define_singleton_method( "new", function!(MutURI::new, 1) )?;
    class.define_singleton_method( "decode", function!(MutURI::decode, 1) )?;

    class.define_method( "query", method!(MutURI::query, 0) )?;
    class.define_method( "query=", method!(MutURI::set_query, 1) )?;

    class.define_method( "userinfo", method!(MutURI::userinfo, 0) )?;
    class.define_method( "userinfo=", method!(MutURI::set_userinfo, 1) )?;

    class.define_method( "port", method!(MutURI::port, 0) )?;
    class.define_method( "port=", method!(MutURI::set_port, 1) )?;

    class.define_method( "host", method!(MutURI::host, 0) )?;
    class.define_method( "host=", method!(MutURI::set_host, 1) )?;

    class.define_method( "path", method!(MutURI::path, 0) )?;
    class.define_method( "path=", method!(MutURI::set_path, 1) )?;

    class.define_method( "scheme", method!(MutURI::scheme, 0) )?;
    class.define_method( "scheme=", method!(MutURI::set_scheme, 1) )?;

    class.define_method( "domain", method!(MutURI::domain, 0) )?;
    class.define_method( "user", method!(MutURI::user, 0) )?;
    class.define_method( "password", method!(MutURI::password, 0) )?;

    class.define_method( "ip_address?", method!(MutURI::is_ip_address, 0) )?;

    class.define_method( "up_to_path", method!(MutURI::up_to_path, 0) )?;
    class.define_method( "up_to_port", method!(MutURI::up_to_port, 0) )?;

    class.define_method( "without_query", method!(MutURI::without_query, 0) )?;

    class.define_method( "resource_name", method!(MutURI::resource_name, 0) )?;
    class.define_method( "resource_extension", method!(MutURI::resource_extension, 0) )?;

    class.define_method( "dup", method!(MutURI::dup, 0) )?;
    class.define_method( "to_s", method!(MutURI::to_s, 0) )?;

    class.define_method( "absolute?", method!(MutURI::is_absolute, 0) )?;
    class.define_method( "relative?", method!(MutURI::is_relative, 0) )?;

    class.define_method( "persistent_hash", method!(MutURI::ahash, 0) )?;
    class.define_method( "hash", method!(MutURI::ahash, 0) )?;

    class.define_method( "to_absolute!", method!(MutURI::as_absolute, 1) )?;
    class.define_method( "query_parameters", method!(MutURI::query_parameters, 0) )?;

    class.define_method( "inspect", method!(MutURI::inspect, 0) )?;
    class.define_method( "==", method!(MutURI::is_equal, 1) )?;
    class.define_method( "free", method!(MutURI::free, 0) )?;

    Ok(())
}
