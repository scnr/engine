use std::rc::Rc;
use std::collections::HashSet;

use html5ever::{LocalName, Attribute};
use parser::sax::node;

const TEXT:       &str = "text";
const ELEMENT:    &str = "element";
const SET_COOKIE: &str = "set-cookie";
const REFRESH:    &str = "refresh";

lazy_static! {
    static ref SELF_CLOSE: HashSet<LocalName> = {
        let mut h = HashSet::new();
        h.insert( local_name!("area") );
        h.insert( local_name!("base") );
        h.insert( local_name!("br") );
        h.insert( local_name!("col") );
        h.insert( local_name!("embed") );
        h.insert( local_name!("frame") );
        h.insert( local_name!("hr") );
        h.insert( local_name!("img") );
        h.insert( local_name!("input") );
        h.insert( local_name!("keygen") );
        h.insert( local_name!("link") );
        h.insert( local_name!("meta") );
        h.insert( local_name!("param") );
        h.insert( local_name!("source") );
        h.insert( local_name!("track") );
        h.insert( local_name!("wbr") );
        h
    };
}

fn allow( parent_name: &LocalName, kind: &str, name: &LocalName, attributes: &[Attribute] ) -> bool {
    if kind == TEXT {
        if parent_name == &local_name!("option") ||
            parent_name == &local_name!("textarea") ||
            parent_name == &local_name!("title") ||
            parent_name == &local_name!("script") { return true }

        return false
    }

    if kind == ELEMENT {
        if name == &local_name!("form") || name == &local_name!("input") ||
            name == &local_name!("textarea") || name == &local_name!("option") ||
            name == &local_name!("title" ) || name == &local_name!("script" ) { return true }

        if name == &local_name!("frame") || name == &local_name!("iframe") {
            for attribute in attributes {
                if attribute.name.local == local_name!( "src" ) {
                    return !attribute.value.is_empty()
                }
            }

            return false
        }

        if name == &local_name!("a") || name == &local_name!("base") || name == &local_name!("area") ||
            name == &local_name!("link") {

            for attribute in attributes {
                if attribute.name.local == local_name!( "href" ) {
                    return !attribute.value.is_empty() && attribute.value != format_tendril!("#")
                }
            }

            return false
        }

        if name == &local_name!("meta") {
            for attribute in attributes {
                if attribute.name.local == local_name!( "http-equiv" ) {
                    let value = attribute.value.to_lowercase();
                    return value.contains( SET_COOKIE ) || value.contains( REFRESH )
                }
            }

            return false
        }

        if name == &local_name!("select") || name == &local_name!("button") {
            for attribute in attributes {
                if (
                    attribute.name.local == local_name!( "name" ) ||
                    attribute.name.local == local_name!( "id"  )
                ) && !attribute.value.is_empty() { return true }
            }

            return false
        }

        return false
    }

    false
}

pub struct Handler {
    current_node: node::Handle,
    skipped:      Vec<LocalName>,
    filter:       bool
}
impl Handler {
    pub fn new( root: node::Handle, filter: bool ) -> Self {
        Handler {
            current_node: root,
            skipped:      vec![],
            filter:       filter
        }
    }

    pub fn start_element( &mut self,
        name:             LocalName,
        attributes:       Vec<Attribute>,
        mut self_closing: bool
    ) {
        if self.filter {
            match self.current_node.borrow().node {
                node::Enum::Document => {
                    if !allow( &local_name!(""), ELEMENT, &name, &attributes ) {
                        self.skipped.push( name );
                        return
                    }
                },

                node::Enum::Element { name: ref pname, .. } => {
                    if !allow( pname, ELEMENT, &name, &attributes ) {
                        self.skipped.push( name );
                        return
                    }
                },

                _ => { return }
            }
        }

        if !self_closing { self_closing = SELF_CLOSE.contains( &name ); }

        let handle = node::Node::new_handle(
            node::Enum::Element { name: name, attributes: attributes, self_closing: self_closing },
            Option::Some( Rc::downgrade( &self.current_node ) )
        );

        self.current_node.borrow_mut().children.push( handle.clone() );
        self.current_node = handle;

        if self_closing { self.end_element( &local_name!("") ) }
    }

    pub fn end_element( &mut self, name: &LocalName, ) {
        if self.filter && name != &local_name!("") &&
            !self.skipped.is_empty() && name == self.skipped.last().unwrap() {
            self.skipped.pop();
            return
        }

        let cloned      = self.current_node.clone();
        let parent_ref  = &cloned.borrow().parent;

        if let Some( ref cloned_parent_ref ) = parent_ref.clone() {
            self.current_node = node::Handle( cloned_parent_ref.upgrade().unwrap() )
        }
    }

    pub fn text( &mut self, text: String ) {
        if self.filter {
            match self.current_node.borrow().node {
                node::Enum::Document => {
                    if !allow( &local_name!(""), TEXT, &local_name!( "" ), &[] ) { return }
                },

                node::Enum::Element { name: ref pname, .. } => {
                    if !allow( pname, TEXT, &local_name!(""), &[] ) { return }
                },

                _ => { return }
            }
        }

        self.current_node.borrow_mut().children.push(
            node::Node::new_handle(
                node::Enum::Text( text ),
                Option::Some( Rc::downgrade( &self.current_node ) )
            )
        );
    }

    pub fn comment( &mut self, text: String ) {
        self.current_node.borrow_mut().children.push(
            node::Node::new_handle(
                node::Enum::Comment( text ),
                Option::Some( Rc::downgrade( &self.current_node ) )
            )
        );
    }
}
