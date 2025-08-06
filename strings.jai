
Occurrence :: struct {
    start, end: s64;
};


find_occurrences_of_wrap :: (input: string, start_string: string, end_string: string) -> []Occurrence {
    // Be careful since this function is optimized for performances but it's not formally correct:
    // There are some pathological cases that it won't handle correctly.
    occurrences: [..] Occurrence;
    start_occurrence_found := false;
    start_string_len := start_string.count;
    end_string_len := end_string.count;
    start_match_index := 0;
    end_match_index := 0;
    if start_string_len == 0 || end_string_len == 0 return occurrences;
    inside := false;
    temp_occurrence: Occurrence;
    for i: 0 .. input.count-1 {
        if !inside {
            // We are looking for the start string
            if input[i] == start_string[start_match_index] {
                start_match_index += 1;
            }
            if start_match_index == start_string_len {
                // We found the start string, let's start the occurrence and reset the start index
                start_match_index = 0;
                inside = true;
                temp_occurrence.start = i - start_string_len + 1; // +1 because we want to include the start of the string
            }
        } else {
            // We are looking for the end string
            if input[i] == end_string[end_match_index] {
                end_match_index += 1;
                if end_match_index == end_string_len {
                    // We found the end string, let's end the occurrence and reset the end index
                    temp_occurrence.end = i + 1; // +1 because we want to include the end of the string
                    array_add(*occurrences, temp_occurrence);
                    start_match_index = 0;
                    end_match_index = 0;
                    inside = false;
                }
            } else {
                // Reset and check if current character could start a new match
                end_match_index = 0;
                if input[i] == end_string[0] {
                    end_match_index = 1;
                }
            }
        }
    }
    return occurrences;
}

#import "String";
#import "Hash_Table";