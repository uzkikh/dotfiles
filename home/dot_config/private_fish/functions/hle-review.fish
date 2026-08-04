function hle-review
    echo -e "=== Account balances ==="
    hledger bal ass liabil --strict
    
    echo "=== Pending transactions ===" 
    hledger reg --pending --strict
end
