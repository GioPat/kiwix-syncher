// Software that enables ZIM scraping and updates
VERSION :: "0.1.0";

Config :: struct {
    base_url: string;
    poll_period: u64;
    watching_dir: string;
    watching_zim_patterns: [..] string;
}

read_config :: (file_content: string) -> Config {
    config := parse_config(file_content);
    returning_config: Config;
    defer free_config(config);

    global_found, global_config := table_find_new(*config, "global");
    if !global_found {
        print("Global configuration not found.\n");
        free_config(config);
        exit(1);
    }
    base_url_found, base_url := table_find_new(global_config.object, "base_url");
    poll_period_found, poll_period := table_find_new(global_config.object, "poll_period_minutes");
    watching_dir_found, watching_dir := table_find_new(global_config.object, "watching_directory");
    watching_zim_patterns_found, watching_zim_patterns := table_find_new(*config, "watching_zims");

    if !base_url_found || !poll_period_found || !watching_dir_found || !watching_zim_patterns_found {
        print("Config not valid\n");
        free_config(config);
        exit(1);
    }
    zim_patterns: [..] string;
    for pattern: watching_zim_patterns.array {
        array_add(*zim_patterns, pattern.str);
    }
    returning_config.base_url = base_url.str;
    returning_config.poll_period = cast(u64) poll_period.number;
    returning_config.watching_zim_patterns = zim_patterns;
    returning_config.watching_dir = watching_dir.str;
    print("Base URL: %\n", base_url);
    return returning_config;
}

main :: () {
    print("Reading Config file config.cfg \n");
    file := read_entire_file("config.cfg");
    config := read_config(file);
    print("Making request to KIWIX library...\n");
    dir := get_working_directory();
    print("Current working directory: %\n", dir);
    files := file_list(config.watching_dir);
    if files.count == 0 {
        print("No files found in the watching directory: %\n", config.watching_dir);
        exit(0);
    }
    // watching_zim_patterns := string.["xxxx"];
    // res := get(base_url);
    // defer free(res);
    // body := res.body;
    // start_idx := 0;
    // files: [..] string;
    // files.allocator = temp;
    // occurrences := find_occurrences_of_wrap(body, "devdocs_", ".zim");
    // for occurrences {
    //     url := slice(body, it.start, it.end - it.start);
    //     array_add(*files, url);
    // }
    // print("Found % files\n", files.count);
    // print("First file is: %\n", files[0]);
    // pattern_result := extract_from_pattern(files[0], watching_zim_patterns[0]);
    // if pattern_result.valid {
    //     found, date := table_find_new(*pattern_result.variables, "date");
    //     if found {
    //         print("Extracted date: %\n", date);
    //     }
    // } else {
    //     print("Pattern extraction failed.\n");
    // }
    return;
}

#import "File";
#import "File_Utilities";
#import "Basic";
#import "Curl"()(LINUX_USE_SYSTEM_LIBRARY=true);
#import "config_parser";
#import "requester";
#load "strings.jai";
#load "patterns.jai";