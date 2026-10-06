#run {
  set_build_options_dc(.{do_output=false});

  make_directory_if_it_does_not_exist("./bin/");
  w := compiler_create_workspace("syncher");
  options := get_build_options(w);
  args := options.compile_time_command_line;
  import_path: [..] string;
  array_add(*import_path, .. options.import_path);
  array_add(*import_path, "./modules");
  
  release := array_find(args, "-release");
  release_very := array_find(args, "-very-release");
  arm := array_find(args, "-arm");
  memdebug := array_find(args, "-memdebug");


  copy_commonly_propagated_fields(get_build_options(), *options);
  options.output_executable_name = "syncher";
  options.output_path = "./bin/";
  options.import_path = import_path;
  if release set_optimization(*options, .OPTIMIZED);
  if release_very set_optimization(*options, .VERY_OPTIMIZED);
  if arm options.cpu_target = .ARM64;
  set_build_options(options, w);
  add_build_string(tprint("MEMORY_DEBUG :: %;", memdebug), w);
  add_build_file("./main.jai", w);
  
}

#import "Basic";
#import "Compiler";
#import "File";