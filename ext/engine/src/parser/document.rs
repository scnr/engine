use rutie::{Class, Object, RString, Boolean, AnyObject, Proc, Symbol, Hash};
use parser::sax::*;

lazy_static! {
    static ref DOCUMENT: String = "document".to_string();
    static ref ELEMENT:  String = "element".to_string();
    static ref TEXT:     String = "text".to_string();
    static ref COMMENT:  String = "comment".to_string();
}

pub struct Node {
    pub native: Option<node::Handle>
}

impl Node {
    fn new( native: Option<node::Handle> ) -> Self {
        Node {
            native: native
        }
    }

    pub fn name( &self ) -> String {
        if let Some( ref handle ) = self.native {
            if let node::Enum::Element { ref name, .. } = handle.borrow().node {
                return name.to_string()
            }
            return String::new()
        }

        panic!( "Use after free." );
    }

    pub fn attributes( &self ) -> Hash {
        let mut hash = Hash::new();

        if let Some( ref handle ) = self.native {
            if let node::Enum::Element { ref attributes, .. } = handle.borrow().node {
                for attribute in attributes {
                    hash.store(
                        RString::new_utf8( &attribute.name.local.to_lowercase() ),
                        RString::new_utf8( &attribute.value )
                    );
                }
            }
        } else {
            panic!( "Use after free." );
        }

        hash
    }

    pub fn kind( &self ) -> &String {
        if let Some( ref handle ) = self.native {
            return match handle.borrow().node {
                node::Enum::Document => {
                    &*DOCUMENT
                }

                node::Enum::Element { .. } => {
                    &*ELEMENT
                }

                node::Enum::Text( .. ) => {
                    &*TEXT
                }

                node::Enum::Comment( .. ) => {
                    &*COMMENT
                }
            }
        }

        panic!( "Use after free." );
    }

    pub fn parent( &self ) -> AnyObject {
        if let Some( ref handle ) = self.native {
            let cloned     = handle.clone();
            let parent_ref = &cloned.borrow().parent;
            let cloned_parent_ref = parent_ref.clone();

            if let Some( ref parent_handle ) = cloned_parent_ref {
                return Node::handle_to_ruby( &node::Handle( parent_handle.upgrade().unwrap() ) );
            } else {
                panic!( "Node has no parent, is it the root?" );
            }
        } else {
            panic!( "Use after free." );
        }
    }

    pub fn is_root( &self ) -> bool {
        if let Some( ref handle ) = self.native {
            return handle.borrow().parent.is_none()
        }

        panic!( "Use after free." );
    }

    pub fn nodes_by_name( &self, tag_name: &str, cb: &Proc ) {
        if let Some( ref handle ) = self.native {
            handle.nodes_by_name( tag_name, |h| {
                cb.call( &vec![Node::handle_to_ruby( h ) ] );
            });
            return
        }

        panic!( "Use after free." );
    }

    pub fn nodes_by_attribute_name_and_value( &self, n: &str, v: &str, cb: &Proc ) {
        if let Some( ref handle ) = self.native {
            handle.nodes_by_attribute_name_and_value( n, v, |h| {
                cb.call( &vec![Node::handle_to_ruby( h ) ] );
            });
            return
        }

        panic!( "Use after free." );
    }

    pub fn traverse_comments( &self, cb: &Proc ) {
        if let Some( ref handle ) = self.native {
            handle.traverse_comments( |h| {
                cb.call( &vec![Node::handle_to_ruby( h ) ] );
            });
            return
        }

        panic!( "Use after free." );
    }

    pub fn traverse( &self, cb: &Proc ) {
        if let Some( ref handle ) = self.native {
            handle.traverse( |h| {
                cb.call( &vec![Node::handle_to_ruby( h ) ] );
            });
            return
        }

        panic!( "Use after free." );
    }

    pub fn text( &self ) -> String {
        if let Some( ref handle ) = self.native {
            return handle.text()
        }

        panic!( "Use after free." );
    }

    pub fn to_html( &self, indentation: usize, level: usize ) -> String {
        if let Some( ref handle ) = self.native {
            return handle.to_html( indentation, level )
        }

        panic!( "Use after free." );
    }

    pub fn free( &mut self ) {
        self.native = None;
    }

    fn handle_to_ruby( handle: &node::Handle ) -> AnyObject {
        Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
            get_nested_class( "Rust" ).get_nested_class( "Parser" ).
            get_nested_class( "Node" ).
            wrap_data( Node::new( Some( handle.clone() ) ), &*NODE_WRAPPER )
    }
}

fn _parse( html: &RString, filter: &Boolean ) -> AnyObject {
    let node    = Node::new(
        Some( parser::parse( html.to_str(), filter.to_bool() ) )
    );

    Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
        get_nested_class( "Rust" ).get_nested_class( "Parser" ).
        get_nested_class( "Node" ).
        wrap_data( node, &*NODE_WRAPPER )
}

wrappable_struct!( Node, NodeWrapper, NODE_WRAPPER );
class!( NodeExt );
unsafe_methods!(
    NodeExt,
    _itself,

    fn parse( html: RString, filter: Boolean ) -> AnyObject {
        _parse( &html, &filter )
    }

    fn traverse_comments( cb: Proc ) -> Boolean {
        _itself.get_data( &*NODE_WRAPPER ).traverse_comments( &cb );
        Boolean::new(true)
    }

    fn nodes_by_name( name: RString, cb: Proc ) -> Boolean {
        _itself.get_data( &*NODE_WRAPPER ).nodes_by_name( name.to_str(), &cb );
        Boolean::new(true)
    }

    fn nodes_by_attribute_name_and_value( name: RString, value: RString, cb: Proc ) -> Boolean {
        _itself.get_data( &*NODE_WRAPPER ).
            nodes_by_attribute_name_and_value(
                name.to_str(),
                value.to_str(),
                &cb
            );

        Boolean::new(true)
    }

    fn traverse( cb: Proc ) -> Boolean {
        _itself.get_data( &*NODE_WRAPPER ).traverse( &cb );
        Boolean::new(true)
    }

    fn is_root() -> Boolean {
        Boolean::new( _itself.get_data( &*NODE_WRAPPER ).is_root() )
    }

    fn text() -> RString {
        RString::new_utf8( &_itself.get_data( &*NODE_WRAPPER ).text() )
    }

    fn name() -> Symbol {
        Symbol::new( &_itself.get_data( &*NODE_WRAPPER ).name() )
    }

    fn attributes() -> Hash {
        _itself.get_data( &*NODE_WRAPPER ).attributes()
    }

    fn kind() -> Symbol {
        Symbol::new( _itself.get_data( &*NODE_WRAPPER ).kind() )
    }

    fn parent() -> AnyObject {
        _itself.get_data( &*NODE_WRAPPER ).parent()
    }

    fn free() -> Boolean {
        _itself.get_data_mut( &*NODE_WRAPPER ).free();
        Boolean::new(true)
    }

    fn to_html() -> RString {
        let parser   = &_itself.get_data( &*NODE_WRAPPER );
        let document = &parser.native.clone().unwrap();

        RString::new_utf8( &document.to_html( 4, 0 ) )
    }
);

pub fn initialize() {

    Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
        define_nested_class( "Rust", None ).define_nested_class( "Parser", None ).
        define_nested_class( "Node", None ).define( |_itself| {

        _itself.def_self( "parse", parse );

        _itself.def( "nodes_by_name", nodes_by_name );
        _itself.def( "nodes_by_attribute_name_and_value", nodes_by_attribute_name_and_value );
        _itself.def( "traverse_comments", traverse_comments );
        _itself.def( "traverse", traverse );
        _itself.def( "parent", parent );
        _itself.def( "text", text );
        _itself.def( "type", kind );
        _itself.def( "attributes", attributes );
        _itself.def( "name", name );
        _itself.def( "root?", is_root );
        _itself.def( "free", free );
        _itself.def( "to_html", to_html );

    });

}
