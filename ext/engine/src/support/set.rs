//! Corresponds to `Engine::Support::Lookup::Hash::Collection`.

#[allow(useless_attribute)]
use std::hash::{Hash};

use std::collections::BTreeSet;
use std::panic;
use ruru::types::Value;
use ruru::{Array, Class, Fixnum, Object, AnyObject, Boolean};

#[derive(Hash)]
#[derive(PartialEq)]
pub struct Set {
    collection: BTreeSet<usize>
}

impl Set {

    fn new() -> Self {
        Set {
            collection: BTreeSet::new()
        }
    }

    fn insert( &mut self, item: usize ) -> &mut Set {
        self.collection.insert( item );
        self
    }

    fn merge( &mut self, other: &mut Set ) -> &mut Set {
        for item in other.collection.clone() {
            self.collection.insert( item );
        }
        self
    }

    fn contains( &mut self, item: &usize ) -> bool {
        self.collection.contains( item )
    }

    fn clear( &mut self ) -> &mut Self {
        self.collection.clear();
        self
    }

}

fn _set_new_ext() -> AnyObject {
    Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
        get_nested_class( "Rust" ). get_nested_class( "Support" ).
        get_nested_class( "Filter" ).
        get_nested_class( "SetExt" ).wrap_data( Set::new(), &*SET_WRAPPER )
}

fn _set_insert_ext( _itself: &SetExt, item: usize ) -> AnyObject {
    _itself.get_data( &*SET_WRAPPER ).insert( item );
    _itself.to_any_object()
}

fn _set_merge_ext( _itself: &SetExt, other: SetExt ) -> AnyObject {
    _itself.get_data( &*SET_WRAPPER ).merge( other.get_data( &*SET_WRAPPER ) );
    _itself.to_any_object()
}

fn _set_include_ext( _itself: &SetExt, item: usize ) -> Boolean {
    Boolean::new( _itself.get_data( &*SET_WRAPPER ).contains( &item ) )
}

fn _set_clear_ext( _itself: &SetExt ) -> AnyObject {
    _itself.get_data( &*SET_WRAPPER ).clear();
    _itself.to_any_object()
}

fn _set_to_a_ext( _itself: &SetExt ) -> Array {
    let mut a = Array::new();
    for item in _itself.get_data( &*SET_WRAPPER ).collection.clone() {
        a.push( Fixnum::from( Value::from( item ) ) );
    }
    a
}

wrappable_struct!( Set, SetWrapper, SET_WRAPPER );

class!( SetExt );
unsafe_methods!(
    SetExt,
    _itself,

    fn set_new_ext() -> AnyObject {
        _set_new_ext()
    }

    fn set_insert_ext( item: Fixnum ) -> AnyObject  {
        _set_insert_ext( &_itself, item.value().value  )
    }

    fn set_merge_ext( other: SetExt ) -> AnyObject  {
        _set_merge_ext( &_itself, other )
    }

    fn set_include_ext( item: Fixnum ) -> Boolean  {
        _set_include_ext( &_itself, item.value().value  )
    }

    fn set_clear_ext() -> AnyObject {
        _set_clear_ext( &_itself )
    }

    fn set_to_a_ext() -> Array {
        _set_to_a_ext( &_itself )
    }

);

pub fn initialize() {
    Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
        define_nested_class( "Rust", None ).define_nested_class( "Support", None ).
        define_nested_class( "Filter", None ).
        define_nested_class(
        "Set",
        Some( &Class::from_existing( "Data" ) )
    ).define( |_itself| {

        _itself.def_self( "new", set_new_ext );

        _itself.def( "<<",       set_insert_ext );
        _itself.def( "merge",    set_merge_ext );
        _itself.def( "include?", set_include_ext );
        _itself.def( "clear",    set_clear_ext );
        _itself.def( "to_a",     set_to_a_ext );

    });
}
