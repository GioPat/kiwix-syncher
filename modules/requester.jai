
size_t :: u64;

Download_Content :: struct {
    file: *File;
    curl: *CURL;
    verbose: bool = false;
}

request :: (url: string, data: string = "", method: string = "", headers: [] string = .[], include_headers: bool = false, setopt: (curl: *CURL)->()=null, getinfo: (curl: *CURL)->()=null) -> res: Curl_Response {
    curl := curl_easy_init();
    assert(curl != null);
    defer curl_easy_cleanup(curl);

    // url
    curl_easy_setopt(curl, .URL, temp_c_string(url));
    curl_easy_setopt(curl, .FOLLOWLOCATION, 1); // follow redirects

    // method
    if method {
        curl_easy_setopt(curl, .CUSTOMREQUEST, temp_c_string(method));
    }

    // data
    if data || (method && method != "GET") {
        curl_easy_setopt(curl, .POSTFIELDS, temp_c_string(data));
    }

    // headers - your request headers
    if headers.count {
        slist: *curl_slist;
        for headers slist = curl_slist_append(slist, temp_c_string(it));
        curl_easy_setopt(curl, .HTTPHEADER, slist);
    }

    // nobody
    if method == "HEAD" curl_easy_setopt(curl, .NOBODY, 1);

    // include_headers - parses response headers
    headers_builder: String_Builder;
    defer free_buffers(*headers_builder);
    if include_headers {
        curl_easy_setopt(curl, .HEADERFUNCTION, header_callback);
        curl_easy_setopt(curl, .HEADERDATA,     *headers_builder);
    }

    // our buffer for downloaded body data
    body_builder: String_Builder;
    defer free_buffers(*body_builder);
    curl_easy_setopt(curl, .WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, .WRITEDATA,     *body_builder);


    curl_easy_setopt(curl, .USERAGENT, "curl"); // some sites require a User-Agent

    // setopt - callback function used to call curl_easy_setopt
    if setopt setopt(curl);


    // actually execute the request. this is blocking
    res: Curl_Response;
    res.curl_code = curl_easy_perform(curl);

    if res.curl_code == .OK {
        // getinfo - callback function used to call curl_easy_getinfo
        if getinfo getinfo(curl);

        curl_easy_getinfo(curl, .RESPONSE_CODE, *res.code);

        if builder_string_length(*body_builder)    res.body    = builder_to_string(*body_builder);
        if builder_string_length(*headers_builder) res.headers = builder_to_string(*headers_builder);
        if res.headers                             res.headers_table = parse_headers(res.headers);
    }

    return res;
}

get    :: #bake_arguments request(method="GET");

print_curl_stats :: (curl: *CURL) {
    // Fetch and print stats
    total_time      : float64;
    download_speed  : float64;
    size_downloaded : float64;

    curl_easy_getinfo(curl, .TOTAL_TIME,     *total_time);
    curl_easy_getinfo(curl, .SPEED_DOWNLOAD, *download_speed);
    curl_easy_getinfo(curl, .SIZE_DOWNLOAD,  *size_downloaded);

    print("Time: %s, Speed: %MB/s, Downloaded: %MB\n", total_time, download_speed / 1024.0 / 1024.0, size_downloaded / 1024.0 / 1024.0);
}

// Curl expects a C function, that's why we have to use #c_call, and since #c_call doesn't provide a context and JAI function need it, we push_context
write_download_callback :: (contents: *u8, count: u64, size: u64, download_content: *Download_Content) -> u64 #c_call {
    total_size := count * size;
    push_context {
        // Write data to the file
        file_write(download_content.file, contents, cast(s64) total_size);
        if download_content.verbose print_curl_stats(download_content.curl);
    }

    return total_size;
}


download :: (url: string, target: string, verbose: bool = false) -> bool {
    curl := curl_easy_init();
    if !curl {
        log_error("An error occured while initting up the Curl connection, but Curl doesn't tell us why.");
        return false;
    }
    defer curl_easy_cleanup(curl);
    curl_easy_setopt(curl, .URL, temp_c_string(url));
    curl_easy_setopt(curl, .FOLLOWLOCATION, 1);

    out_file, ok := file_open(target, for_writing=true);
    if !ok {
        log_error("An error occured while opening the file % for storing the download.", target);
        return false;
    }
    defer file_close(*out_file);
    download_content: Download_Content;
    download_content.file = *out_file;
    download_content.curl = curl;
    download_content.verbose = verbose;
    curl_easy_setopt(curl, .WRITEFUNCTION, write_download_callback);
    curl_easy_setopt(curl, .WRITEDATA, *download_content);
    error_code := curl_easy_perform(curl);
    if error_code != .OK {
        error_message := to_string(curl_easy_strerror(error_code));
        defer free(error_message);
        log_error("Curl Error: %", error_message);
        return false;
    }
    return true;
}

Curl_Response :: struct {
    body          : string;
    headers       : string;
    headers_table : Table(string, string);
    code          : int;
    curl_code     : CURLcode;
}


// called once for each complete header line
header_callback :: (ptr: *u8, size: size_t, nmemb: size_t, userdata: *void) -> size_t #c_call {
    headers_builder := cast(*String_Builder)userdata;

    push_context {
        header: string = ---;
        header.data = ptr;
        header.count = xx nmemb;

        // when using .FOLLOWLOCATION, we have to clear old headers after redirecting
        // we know all our headers are expired if we receive a new HTTP status "header"
        if begins_with(header, "HTTP/") {
            reset(headers_builder);
            return nmemb;
        }

        append(headers_builder, ptr, xx nmemb);
    }

    return nmemb;
}

parse_headers :: (headers: string) -> headers_table: Table(string, string) {
    headers_table: Table(string, string);
    init(*headers_table);

    if !headers return headers_table;

    startofline := 0;
    for i: 0 .. headers.count-1 -3/*because we're looking 3 ahead*/ {
        if headers[i] == #char "\r" && headers[i+1] == #char "\n" {
            defer startofline = i + 2;

            header: string = ---;
            header.data = headers.data + startofline;
            header.count = i - startofline;

            if begins_with(header, "HTTP/") continue; // first line is the status code. not a header

            found, key, val := split_from_left(header, ": ");
            if !found break; // parse error
            table_add(*headers_table, key, val);

            if headers[i+2] == #char "\r" && headers[i+3] == #char "\n" {
                break; // \r\n\r\n found. end of headers
            }
        }
    }

    return headers_table;
}

// called when a chunk of the body is downloaded and ready
write_callback :: (ptr: *u8, size: size_t, nmemb: size_t, userdata: *void) -> size_t #c_call {
    body_builder := cast(*String_Builder)userdata;

    push_context {
        append(body_builder, ptr, xx nmemb);
    }

    return nmemb;
}


get_header :: (using res: Curl_Response, key: string) -> val: string {
    found, val := table_find_new(*headers_table, key);
    return ifx found then val;
}

free :: (using res: Curl_Response) {
    if body                    free(body);
    if headers                 free(headers);
    if headers_table.allocated deinit(*headers_table);
}

#import "Curl";
#import "Hash_Table";
#import "Basic";
#import "String";
#import "File";