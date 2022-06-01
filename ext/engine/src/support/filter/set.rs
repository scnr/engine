//! Corresponds to `Engine::Support::SetExt`.

use std::collections::HashSet;
use rutie::{Fixnum, AnyObject, Class, Object, Boolean, RString, Array};

#[derive(PartialEq)]
pub struct Set {
    collection: HashSet<i64>
}

impl Set {

    fn new() -> Self {
        Set {
            collection: HashSet::new()
        }
    }

    fn push( &mut self, entry: i64 ) -> &mut Set {
        self.collection.insert( entry );
        self
    }

    fn includes( &mut self, entry: &i64 ) -> bool {
        self.collection.contains( entry )
    }

    fn dup( &self ) -> Set {
        Set {
            collection: self.collection.clone()
        }
    }

    fn is_empty( &self ) -> bool {
        self.collection.is_empty()
    }

    fn clear( &mut self ) {
        self.collection.clear();
    }

    fn size( &mut self ) -> i64 {
        self.collection.len() as i64
    }

    fn inspect( &self ) -> String {
        format!( "Set {:?}", self.collection )
    }

}

fn _set_new_ext( ) -> AnyObject {
    Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
        get_nested_class( "Rust" ).get_nested_class( "Support" ).
        get_nested_class( "Filter" ).get_nested_class( "Set" ).wrap_data(
        Set::new(), &*SET_WRAPPER
    )
}

fn _set_push_ext( _itself: &mut SetExt, entry: Fixnum ) -> AnyObject {
    _itself.get_data_mut( &*SET_WRAPPER ).push( entry.to_i64() );
    _itself.to_any_object()
}

fn _set_include_ext( _itself: &mut SetExt, entry: &Fixnum ) -> Boolean {
    Boolean::new(
        _itself.get_data_mut( &*SET_WRAPPER ).includes( &entry.to_i64() )
    )
}

wrappable_struct!( Set, SetWrapper, SET_WRAPPER );

class!( SetExt );
unsafe_methods!(
    SetExt,
    _itself,

    fn set_new_ext() -> AnyObject {
        _set_new_ext( )
    }

    fn set_clear_ext() -> AnyObject {
        _itself.get_data_mut( &*SET_WRAPPER ).clear();
        _itself.to_any_object()
    }

    fn set_size_ext() -> Fixnum {
        Fixnum::new( _itself.get_data_mut( &*SET_WRAPPER ).size() )
    }

    fn set_collection_ext() -> Array {
        let mut array = Array::new();

        for entry in _itself.get_data( &*SET_WRAPPER ).collection.clone() {
            array.push( Fixnum::new( i64::from( entry ) ) );
        }

        array
    }

    fn set_dup_ext() -> AnyObject {
        Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
        get_nested_class( "Rust" ).get_nested_class( "Support" ).
            get_nested_class( "Filter" ).get_nested_class( "Set" ).wrap_data(
                _itself.get_data( &*SET_WRAPPER ).dup(),
                &*SET_WRAPPER
            )
    }

    fn set_push_ext( entry: Fixnum ) -> AnyObject {
        _set_push_ext( &mut _itself, entry )
    }

    fn set_include_ext( entry: Fixnum ) -> Boolean {
        _set_include_ext( &mut _itself, &entry )
    }

    fn set_is_empty_ext() -> Boolean {
        Boolean::new(
            _itself.get_data( &*SET_WRAPPER ).is_empty()
        )
    }

    fn set_inspect_ext() -> RString {
        RString::new_utf8( &_itself.get_data( &*SET_WRAPPER ).inspect() )
    }
);

pub fn initialize() {
    Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
        define_nested_class( "Rust", None ).
        define_nested_class( "Support", None ).
        define_nested_class( "Filter", None ).
        define_nested_class(
            "Set",
            None
        ).define( |_itself| {

        _itself.def_self( "new", set_new_ext );

        _itself.def( "clear", set_clear_ext );
        _itself.def( "size", set_size_ext );
        _itself.def( "collection", set_collection_ext );
        _itself.def( "empty?", set_is_empty_ext );
        _itself.def( "dup", set_dup_ext );
        _itself.def( "include?", set_include_ext );
        _itself.def( "<<", set_push_ext );
        _itself.def( "inspect", set_inspect_ext );

    });
}
