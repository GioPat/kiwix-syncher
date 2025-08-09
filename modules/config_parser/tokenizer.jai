Token_Kind :: enum u8 {
    IDENTIFIER :: 0;
    STRING;
    NUMBER;
    BOOLEAN;
    COLON;      // :
    SEMICOLON;  // ;
    LANGLE;     // <
    RANGLE;     // >
    LBRACKET;   // [
    RBRACKET;   // ]
    COMMA;      // ,
    ENDOFFILE;
    INVALID;
}

Token :: struct {
    kind: Token_Kind;
    text: string;
    line: s32;
    column: s32;
}

Tokenizer :: struct {
    src: string;
    index: s32;
    line: s32;
    column: s32;
}

is_whitespace :: (c: u8) -> bool {
    return c == #char " " || c == #char "\t" || c == #char "\n" || c == #char "\r";
}

is_identifier_start :: (c: u8) -> bool {
    return is_alpha(c) || c == #char "_";
}

is_identifier_char :: (c: u8) -> bool {
    return is_alpha(c) || is_digit(c) || c == #char "_" || c == #char "-";
}

advance :: (t: *Tokenizer) -> u8 {
    c := t.src[t.index];
    t.index += 1;
    if c == #char "\n" {
        t.line += 1;
        t.column = 0;
    } else {
        t.column += 1;
    }
    return c;
}

peek :: (t: *Tokenizer) -> u8 {
    return t.src[t.index];
}

skip_whitespace_and_comments :: (t: *Tokenizer) {
    while t.index < t.src.count {
        c := peek(t);
        if is_whitespace(c) {
            advance(t);
        } else if c == #char "#" {
            while t.index < t.src.count && peek(t) != #char "\n" {
                advance(t);
            }
        } else {
            break;
        }
    }
}

next_token :: (t: *Tokenizer) -> Token {
    skip_whitespace_and_comments(t);
    token := Token.{ line = t.line, column = t.column };

    if t.index >= t.src.count {
        token.kind = Token_Kind.ENDOFFILE;
        return token;
    }

    c := advance(t);

    if c == {
        case #char ":";
          token.kind = Token_Kind.COLON;
        case #char ";";
          token.kind = Token_Kind.SEMICOLON;
        case #char "<";
          token.kind = Token_Kind.LANGLE;
        case #char ">";
          token.kind = Token_Kind.RANGLE;
        case #char "[";
          token.kind = Token_Kind.LBRACKET;
        case #char "]";
          token.kind = Token_Kind.RBRACKET;
        case #char ",";
          token.kind = Token_Kind.COMMA;
        case #char "\"";
          start := t.index;
          while t.index < t.src.count && peek(t) != #char "\"" {
              advance(t);
          }
          token.text = slice(t.src, start, t.index - start);
          advance(t); // consume closing quote
          token.kind = Token_Kind.STRING;
        case;
          if is_identifier_start(c) {
              start := t.index - 1;
              while t.index < t.src.count && is_identifier_char(peek(t)) {
                  advance(t);
              }
              token.text = slice(t.src, start, t.index - start);
              if token.text == "true" || token.text == "false" {
                  token.kind = Token_Kind.BOOLEAN;
              } else {
                  token.kind = Token_Kind.IDENTIFIER;
              }
          } else if is_digit(c) || (c == #char "-" && t.index < t.src.count && is_digit(peek(t))) {
            // Handle numbers (including negative numbers)
            start := t.index - 1;
            while t.index < t.src.count && is_digit(peek(t)) {
                advance(t);
            }
            if peek(t) == #char "." {
                advance(t);
                while t.index < t.src.count && is_digit(peek(t)) {
                    advance(t);
                }
            }
            token.text = slice(t.src, start, t.index - start);
            token.kind = Token_Kind.NUMBER;
          } else {
            token.kind = Token_Kind.INVALID;
            token.text = string.{ 1, *c };
          }
    }
    return token;
}


#import "String";