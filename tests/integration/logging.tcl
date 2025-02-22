set server_path [tmpdir server.log]
set system_name [string tolower [exec uname -s]]
# ldd --version returns 1 under musl for unknown reasons. If this check stops working, that may be why
set is_musl [catch {exec ldd --version}]

if {$system_name eq {linux} && $is_musl eq 0 || $system_name eq {darwin}} {
    start_server [list overrides [list dir $server_path]] {
        test "Server is able to generate a stack trace on selected systems" {
            r config set watchdog-period 200
            r debug sleep 1
            set pattern "*watchdogSignalHandler*"
            set retry 10
            while {$retry} {
                set result [exec tail -100 < [srv 0 stdout]]
                if {[string match $pattern $result]} {
                    break
                }
                incr retry -1
                after 1000
            }
            if {$retry == 0} {
                error "assertion:expected stack trace not found into log file"
            }
        }
    }
}
