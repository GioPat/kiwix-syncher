// Post-sync hook support.
//
// The syncher is the only component that knows when a sync cycle actually
// changed something on disk, which makes it the right place to trigger a
// library rebuild. It deliberately does NOT generate library.xml itself: a
// correct <book> entry needs the UUID, article count and favicon stored inside
// the ZIM, so producing one means linking libzim. Shelling out to kiwix-manage
// keeps that responsibility where it belongs, and a generic hook covers every
// other integration (notifications, backups, SIGHUP) for free.

run_sync_hook :: (command: string) -> bool {
    log("Running on_sync_complete hook: %", command);

    #if OS == .WINDOWS {
        result := run_command("cmd", "/c", command);
    } else {
        result := run_command("/bin/sh", "-c", command);
    }

    if result.type != .EXITED || result.exit_code != 0 {
        log_error("on_sync_complete hook failed (type: %, exit code: %).", result.type, result.exit_code);
        return false;
    }

    log("on_sync_complete hook finished successfully.");
    return true;
}

#import "Process";
