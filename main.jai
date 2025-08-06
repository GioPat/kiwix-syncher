// Software that enables ZIM scraping and updates
VERSION :: "0.1.0";

base_url :: "https://download.kiwix.org/zim/devdocs/";

watching_zim_patterns :: string.[
    "devdocs_en_angular_[date].zim"
];

watching_directory :: "./zims/";

main :: () {

    print("Making request to KIWIX library...\n");
    res := get(base_url);
    defer free(res);
    body := res.body;
    start_idx := 0;
    files: [..] string;
    files.allocator = temp;
    occurrences := find_occurrences_of_wrap(body, "devdocs_", ".zim");
    for occurrences {
        url := slice(body, it.start, it.end - it.start);
        array_add(*files, url);
    }
    print("Found % files\n", files.count);
    print("First file is: %\n", files[0]);
    pattern_result := extract_from_pattern(files[0], watching_zim_patterns[0]);
    if pattern_result.valid {
        found, date := table_find_new(*pattern_result.variables, "date");
        if found {
            print("Extracted date: %\n", date);
        }
    } else {
        print("Pattern extraction failed.\n");
    }
    return;
}

#import "Basic";
#import "Curl"()(LINUX_USE_SYSTEM_LIBRARY=true);
#import,file "modules/requester.jai";

#load "strings.jai";
#load "patterns.jai";