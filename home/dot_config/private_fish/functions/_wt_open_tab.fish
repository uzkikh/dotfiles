function _wt_open_tab --description "Open zellij tab with claude (left) and shell (right)"
    set dir $argv[1]
    set tab_name $argv[2]

    set layout "layout {
        tab name=\"$tab_name\" {
            pane cwd=\"$dir\" {
                command \"fish\"
                args \"-c\" \"claude\"
            }
            pane cwd=\"$dir\" split_direction=\"vertical\"
        }
    }"

    zellij action new-tab --layout-string $layout --name $tab_name
end
