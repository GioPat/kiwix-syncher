// Software that enables ZIM scraping and updates
VERSION :: "0.1.0";


main :: () {
    log("Kiwix scraper version % by GioPat (gyo15@hotmail.it)", VERSION);
    file := read_entire_file("config.cfg");
    config := read_config(file);
    print_config(config);
    zim_search_prefix_len := config.zim_search_prefix.count;
    dir := get_working_directory();
    log("Current working directory: %", dir, flags=Log_Flags.VERBOSE_ONLY);
    files := list_files(config.watching_dir);
    existing_zims: Table(string, Zim_Metadata);
    for file: files {
        zim_metadata := extract_zim_metadata(file);
        table_add(*existing_zims, zim_metadata.name_without_date, zim_metadata);
    }
    // A table storing the zim to download
    zim_to_download: Table(string, Zim_Metadata);
    for watching_zim: config.watching_zim_patterns {
        url, pattern := get_url_and_pattern(config.base_url, watching_zim);
        res := get(url);
        defer free(res);
        body := res.body;
        occurrences := find_occurrences_of_wrap(res.body, config.zim_search_prefix, ".zim");
        if occurrences.count == 0 {
            continue;
        }
        // TODO: Salvare i file da cancellare dopo il download
        for occurrences {
            found_zim := slice(body, it.start + zim_search_prefix_len, it.end - it.start - zim_search_prefix_len);
            pattern_result := extract_from_pattern(found_zim, pattern);
            if !pattern_result.valid {
                continue;
            }
            date_found, date_variable_info := table_find_new(*pattern_result.variables, "date");
            if !date_found {
                log_error("The found zim % did not return any [date] variable, kindly recheck your patterns", found_zim);
                continue;
            }
            zim_before_date := slice(found_zim, 0, date_variable_info.start_index);
            zim_after_date := slice(found_zim, date_variable_info.end_index, found_zim.count - date_variable_info.end_index);
            zim_without_date := join(zim_before_date, zim_after_date);
            metadata: Zim_Metadata;
            metadata.name_without_date = zim_without_date;
            metadata.original_file_name = found_zim;
            metadata.download_url = join(url, found_zim);
            time := zim_date_to_apollo(date_variable_info.value);
            metadata.time = time;
            found_existing_zim, existing_zim := table_find_new(*existing_zims, zim_without_date);
            if !found_existing_zim {
                found_downloading_zim, downloading_zim := table_find_new(*zim_to_download, zim_without_date);
                if found_downloading_zim && downloading_zim.time >= time {
                    continue;
                } else {
                    table_set(*zim_to_download, zim_without_date, metadata);
                }
            } else {
                if existing_zim.time < time {
                    table_set(*zim_to_download, zim_without_date, metadata);
                } else {
                    continue;
                }
            }
        }
    }
    for el: zim_to_download {
        zim_index := find_index_from_right(el.name_without_date, ".zim");
        string_before_zim := slice(el.name_without_date, 0, zim_index - 1);
        calendar_time := to_calendar(el.time);
        
        zim_file_name := sprint("%_%-%.zim", string_before_zim, formatInt(calendar_time.year, minimum_digits=4), formatInt(calendar_time.month_starting_at_0 + 1, minimum_digits=2));
        output_path := join(config.watching_dir, "/", zim_file_name);
        download(el.download_url, output_path);
        // zim_file_path := join(config.watching_dir, zim_metadata.name_without_date);
        // if file_exists(zim_file_path) {
        //     print("[INFO] ZIM file % already exists, skipping download\n", zim_file_path);
        //     continue;
        // }
        // res := get(zim_metadata.download_url);
        // defer free(res);
        // if res.status_code != 200 {
        //     print("[ERROR] Failed to download ZIM file %: HTTP status code %\n", zim_metadata.download_url, res.status_code);
        //     continue;
        // }
        // write_entire_file(zim_file_path, res.body);
        // print("[INFO] Successfully downloaded ZIM file to %\n", zim_file_path);
    }
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
#load "utils.jai";