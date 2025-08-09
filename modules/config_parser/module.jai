parse_config :: (src: string) -> Table(string, Value) {
  parser := Parser.{ tokenizer = Tokenizer.{ src = src, index = 0, line = 1, column = 1 } };
  advance(*parser);
  config: Table(string, Value);
  while parser.current_token.kind != Token_Kind.ENDOFFILE {
    entry := parse_entry(*parser);
    table_set(*config, entry.name, entry.value);
    // table_set(*config, entry.name, entry.value);
  }
  return config;
}

free_config :: (config: Table(string, Value)) {
  for config {
    if it.kind == Value_Kind.OBJECT {
      free_config(it.object);
      free(it.object);
    } else if it.kind == Value_Kind.ARRAY {
      for it.array {
        if it.kind == Value_Kind.OBJECT {
          free_config(it.object);
          free(it.object);
        }
      }
    }
  }
}
#load "ast.jai";