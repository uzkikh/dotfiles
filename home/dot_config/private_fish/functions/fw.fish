# Author: Uzkikh Ivan
# Created: 2026-01-25

function fw
    set -l selected (aerospace list-windows --all | sk)
    if test -n "$selected"
        set -l window_id (echo $selected | awk '{print $1}')
        aerospace focus --window-id $window_id
    end
end
