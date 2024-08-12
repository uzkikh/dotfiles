#function zns --description "Start new zellij session"
#    zellij --session (basename (pwd))
#end

function zns --description "Start new zellij session"
    if test -n "$ZELLIJ_SESSION_NAME"
        echo "Already in a zellij session: $ZELLIJ_SESSION_NAME"
        return
    end

    if test (count $argv) -gt 0
        set dir $argv[1]
    else
        set dir (pwd)
    end

 cd $dir
    zellij --session (basename $dir)
end

