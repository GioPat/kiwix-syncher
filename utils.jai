
Config :: struct {
    base_url: string;
    cooldown_minutes: u64;
    watching_dir: string;
    verbose: bool;
    watching_zim_patterns: [..] string;
    zim_search_prefix: string;
    on_sync_complete: string;
}

Zim_Metadata :: struct {
  original_file_name: string;
  name_without_date: string;
  download_url: string;
  time: Apollo_Time;
}

read_config :: (file_content: string) -> Config {
    config := parse_config(file_content);
    returning_config: Config;
    defer free_config(config);

    global_found, global_config := table_find(*config, "global");
    if !global_found {
        log_error("Global configuration not found.");
        free_config(config);
        exit(1);
    }
    base_url_found, base_url := table_find(global_config.object, "base_url");
    cooldown_minutes_found, cooldown_minutes := table_find(global_config.object, "cooldown_minutes");
    watching_dir_found, watching_dir := table_find(global_config.object, "watching_directory");
    watching_zim_patterns_found, watching_zim_patterns := table_find(*config, "watching_zims");
    zim_search_prefix_found, zim_search_prefix := table_find(global_config.object, "zim_search_prefix");
    verbose_found, verbose := table_find(global_config.object, "verbose");
    on_sync_complete_found, on_sync_complete := table_find(global_config.object, "on_sync_complete");
    if !zim_search_prefix_found {
        zim_search_prefix.str = "<a href=\""; // Default prefix if not found
    }

    if !base_url_found || !cooldown_minutes_found || !watching_dir_found || !watching_zim_patterns_found {
        log_error("Config not valid");
        free_config(config);
        exit(1);
    }
    zim_patterns: [..] string;
    for pattern: watching_zim_patterns.array {
        array_add(*zim_patterns, pattern.str);
    }
    returning_config.verbose = ifx verbose_found then verbose.boolean else false;
    returning_config.on_sync_complete = ifx on_sync_complete_found then on_sync_complete.str else "";

    returning_config.base_url = base_url.str;
    returning_config.cooldown_minutes = cast(u64) cooldown_minutes.number;
    returning_config.watching_zim_patterns = zim_patterns;
    returning_config.watching_dir = watching_dir.str;
    returning_config.zim_search_prefix = zim_search_prefix.str;
    return returning_config;
}

print_config :: (config: Config) {
  log("=== RUNTIME CONFIGS ===");
  log("Base URL: %", config.base_url, flags=Log_Flags.VERBOSE_ONLY);
  log("Cooldown minutes: %", config.cooldown_minutes, flags=Log_Flags.VERBOSE_ONLY);
  log("Watching directory: %", config.watching_dir, flags=Log_Flags.VERBOSE_ONLY);
  log("Watching ZIM patterns: ", flags=Log_Flags.VERBOSE_ONLY);
  for pattern: config.watching_zim_patterns {
      log("  - %", pattern, flags=Log_Flags.VERBOSE_ONLY);
  }
  log("ZIM search prefix: %", config.zim_search_prefix, flags=Log_Flags.VERBOSE_ONLY);
  if config.on_sync_complete.count > 0 {
    log("On sync complete: %", config.on_sync_complete, flags=Log_Flags.VERBOSE_ONLY);
  }
  log("========================", flags=Log_Flags.VERBOSE_ONLY);
}


// zim date: YYYY-MM to Apollo_Time
zim_date_to_apollo :: (zim_date: string) -> Apollo_Time {
  calendar_time: Calendar_Time;
  year_and_month := split(zim_date, "-");
  year := string_to_int(year_and_month[0], 10, s32);
  month := string_to_int(year_and_month[1], 10, s8) - 1;
  calendar_time.year = year;
  calendar_time.month_starting_at_0 = month;
  calendar_time.day_of_month_starting_at_0 = 0; // Default to the first day of the month
  calendar_time.time_zone = Time_Zone.UTC;
  return calendar_to_apollo(calendar_time);
}

extract_zim_metadata :: (zim_file_name: string) -> Zim_Metadata {
  zim_metadata: Zim_Metadata;
  zim_metadata.original_file_name = zim_file_name;
  index := find_index_from_right(zim_file_name, "_");
  if index == -1 {
      log_error("Invalid ZIM file name format: %\nKindly fix your ZIM folders and re-run the daemon", zim_file_name);
      exit(1);
  }
  file_name := slice(zim_file_name, 0, index + 1);
  zim_metadata.name_without_date = sprint("%.zim", file_name);
  date_str := slice(zim_file_name, index + 1, zim_file_name.count - index);
  time := zim_date_to_apollo(date_str);
  zim_metadata.time = time;
  return zim_metadata;
}


get_url_and_pattern :: (base_url: string, watching_zim: string) -> string, string {
    final_slash_pos := find_index_from_right(watching_zim, "/");
    pattern := slice(watching_zim, final_slash_pos + 1, watching_zim.count - final_slash_pos);
    if final_slash_pos == -1 {
        return sprint("%/%", base_url, watching_zim), pattern;
    }
    return sprint("%/%/", base_url, slice(watching_zim, 0, final_slash_pos)), pattern;
}

list_files :: (path: string, follow_directory_symlinks := true) -> [] string {
    files : [..] string;

    visitor :: (info: *File_Visit_Info, user_data: *[..] string) {
        array_add(user_data, copy_string(info.short_name));
    }

    visit_files(path, false, *files, visitor, follow_directory_symlinks=follow_directory_symlinks);

    return files;
}

#import "Basic";
#import "File";
#import "String";
