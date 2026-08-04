function hle-iss
    hledger is -MAS --pretty-tables --layout=tall -b $(date -j -v-$argv[1]m '+%Y-%m')
end
