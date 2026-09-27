PatternPart :: struct {
    type: enum u8 { LITERAL :: 0; VARIABLE; CHOICE; };
    content: string; // For LITERAL: The literal text
    variable_name: string; // For VARIABLE: The variable name
    choices: [..] string; // For CHOICE: The possible options
}

Variable_Info :: struct {
  start_index: s64;
  end_index: s64;
  value: string;
}

PatternResult :: struct {
  valid: bool;
  variables: Table(string, Variable_Info);
}

extract_from_pattern :: (input: string, pattern_parts: [] PatternPart) -> PatternResult {
  result: PatternResult;
  result.valid = false;
  // Match against input
  input_pos := 0;
  for pattern_parts {
    if it.type == {
      case .LITERAL;        
        if input_pos + it.content.count > input.count return result;
        input_part := slice(input, input_pos, it.content.count);
        if input_part != it.content return result;
        input_pos += it.content.count;
      
      case .VARIABLE;
        // Extract until the next part (or end of string)
        start_pos := input_pos;
        end_pos := input.count; // Default to end of input
        // Find where this variable end looking for the next part
        for next_part_index: it_index + 1 .. pattern_parts.count - 1 {
          next_part := pattern_parts[next_part_index];
          if next_part.type == .LITERAL {
            found_pos := find_index_from_left(input, next_part.content, input_pos);
            if found_pos != -1 {
              end_pos = found_pos;
              break;
            }
          } else if next_part.type == .CHOICE {
            // Find the earliest among all the choices
            earliest := input.count;
            for choice: next_part.choices {
              found_pos := find_index_from_left(input, choice, input_pos);
              if found_pos != -1 && found_pos < earliest {
                earliest = found_pos;
              }
            }
            if earliest != input.count {
              end_pos = earliest;
              break; // Break out of the loop
            }
          }
        }
        if end_pos <= start_pos return result; // No content found
        
        var_value := slice(input, start_pos, end_pos - start_pos);
        var_info: Variable_Info;
        var_info.start_index = start_pos;
        var_info.end_index = end_pos;
        var_info.value = var_value;
        table_set(*result.variables, it.variable_name, var_info);
        input_pos = end_pos;
      case .CHOICE;
        matched := false;
        best_match: string;
        best_match_length := 0;
        for choice: it.choices {
          choice_trimmed := trim(choice);
          if choice_trimmed.count == 0 continue; // Skip empty choices

          if input_pos + choice_trimmed.count <= input.count {
            input_part := slice(input, input_pos, choice_trimmed.count);
            if input_part == choice_trimmed && choice_trimmed.count > best_match_length {
              best_match = choice_trimmed;
              best_match_length = choice_trimmed.count;
            }
          }
        }
        if best_match_length > 0 {
          input_pos += best_match_length;
          matched = true;
        }
        if !matched return result; // No match found
    }
  }
  result.valid = true;
  return result;
}

parse_patterns :: (pattern: string) -> [..] PatternPart {
  parts: [..] PatternPart;
  current_pos := 0;
  i := 0;
  while i < pattern.count {
    if pattern[i] == #char "[" {
      // Add any literal text before this bracket
      if i > current_pos {
          part: PatternPart;
          part.type = .LITERAL;
          part.content = slice(pattern, current_pos, i - current_pos);
          array_add(*parts, part);
      }
      // Find the closing bracket
      end_bracket := -1;
      for j: i + 1 .. pattern.count - 1 {
        if pattern[j] == #char "]" {
          end_bracket = j;
          break;
        }
      }
      if end_bracket == -1 {
        i += 1;
        continue;
      }
      bracket_content := slice(pattern, i + 1, end_bracket - i - 1);
      is_choice, _ := contains_any_character(bracket_content, "|");
      if is_choice {
        // This is a choice pattern
        part: PatternPart;
        part.type = .CHOICE;
        adding_choices: [..] string;
        choices := split(bracket_content, "|");
        for choices {
          trimmed := trim(it);
          if trimmed.count > 0 {
            array_add(*adding_choices, trimmed);
          }
        }
        part.choices = adding_choices;
        array_add(*parts, part);
      } else {
        // Regular variable
        part: PatternPart;
        part.type = .VARIABLE;
        part.variable_name = trim(bracket_content);
        array_add(*parts, part);
      }
      current_pos = end_bracket + 1;
      i = end_bracket + 1;
    } else {
      i += 1;
    }
  }

  if current_pos < pattern.count {
    // Add any remaining literal after the last bracket
    part: PatternPart;
    part.type = .LITERAL;
    part.content = slice(pattern, current_pos, pattern.count - current_pos);
    array_add(*parts, part);
  }
  return parts;
}

#import "String";