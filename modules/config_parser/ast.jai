#load "tokenizer.jai";

Value_Kind :: enum {
    OBJECT :: 0;
    ARRAY  :: 1;
    STRING :: 2;
    NUMBER :: 3;
    BOOLEAN :: 4;
    NULL   :: 5;
}

Value :: struct {
  kind: Value_Kind;
  str: string;
  union {
    number: float;
    boolean: bool;
    object: *Table(string, Value);
    array: []Value;
  }
}

Parser :: struct {
  tokenizer: Tokenizer;
  current_token: Token;
}

advance :: (p: *Parser) {
  p.current_token = next_token(*p.tokenizer);
}

match :: (p: *Parser, kind: Token_Kind) -> bool {
  if p.current_token.kind == kind {
    advance(p);
    return true;
  }
  return false;
}

parse_value :: (p: *Parser) -> Value {
    t := p.current_token;

    if t.kind == Token_Kind.STRING {
        advance(p);
        return Value.{ kind = Value_Kind.STRING, str = t.text };
    }

    if t.kind == Token_Kind.NUMBER {
        advance(p);
        float_value, success := parse_float(*t.text);
        if !success {
            // Handle error: invalid number format
            return Value.{ kind = Value_Kind.NULL };
        }
        return Value.{ kind = Value_Kind.NUMBER, number = float_value };
    }

    if t.kind == Token_Kind.BOOLEAN {
        advance(p);
        return Value.{ kind = Value_Kind.BOOLEAN, boolean = (t.text == "true") };
    }

    if t.kind == Token_Kind.LANGLE {
        return parse_object(p);
    }

    if t.kind == Token_Kind.LBRACKET {
        return parse_array(p);
    }

    return Value.{ kind = Value_Kind.NULL };
}

parse_array :: (p: *Parser) -> Value {
    array: [..] Value;

    assert(p.current_token.kind == Token_Kind.LBRACKET);
    advance(p); // consume [

    while p.current_token.kind != Token_Kind.RBRACKET && p.current_token.kind != Token_Kind.ENDOFFILE {
        elem := parse_value(p);
        array_add(*array, elem);

        if !match(p, Token_Kind.COMMA) {
            break;
        }
    }

    if !match(p, Token_Kind.RBRACKET) {
        // Error handling could go here
    }

    return Value.{ kind = Value_Kind.ARRAY, array = array };
}

parse_object :: (p: *Parser) -> Value {
  assert(p.current_token.kind == Token_Kind.LANGLE);
  advance(p); // consume <
  object := New(Table(string, Value));

  
  while p.current_token.kind != Token_Kind.RANGLE && p.current_token.kind != Token_Kind.ENDOFFILE {
      entry := parse_entry(p);
      table_set(object, entry.name, entry.value);
  }
  // expected '>'
  assert(p.current_token.kind == Token_Kind.RANGLE);
  advance(p); // consume >

  return Value.{ kind = Value_Kind.OBJECT, object = object };
}

AstEntry :: struct {
    name: string;
    value: Value;
}

parse_entry :: (p: *Parser) -> AstEntry {
  key := p.current_token;
  assert(key.kind == Token_Kind.IDENTIFIER);
  advance(p);

  assert(match(p, Token_Kind.COLON));
  val := parse_value(p);
  assert(match(p, Token_Kind.SEMICOLON));

  return AstEntry.{ name = key.text, value = val };
}



#import "Hash_Table";
#import "Basic";
