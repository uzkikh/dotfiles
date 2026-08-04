function hle-is
    hledger is -MA --pretty-tables --layout=tall -b $(date -j -v-$argv[1]m '+%Y-%m')
end
