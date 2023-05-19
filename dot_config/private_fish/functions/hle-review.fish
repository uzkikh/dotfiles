function hle-review
    echo -e "=== Account balances ==="
    hledger bal ass liabil --strict 

    echo -e "======"
    hledger is -MAS --pretty-tables --layout=tall -b $(date -j -v-3m '+%Y-%m')
    
    echo "=== Pending transactions ===" 
    hledger reg --pending --strict
end
