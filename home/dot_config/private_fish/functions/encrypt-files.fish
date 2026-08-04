function encrypt-files
    # Parse arguments
    set -l input_path ""
    set -l output_file ""

    argparse 'o=' -- $argv 2>/dev/null
    set input_path $argv[1]
    set output_file $_flag_o

    # Validate input
    if test -z "$input_path"
        echo "Usage: encrypt <file_or_dir> [-o output.enc]"
        return 1
    end

    if not test -e "$input_path"
        echo "Error: '$input_path' not found"
        return 1
    end

    # Generate output filename if not provided
    if test -z "$output_file"
        set output_file (basename "$input_path").enc
    end

    # Encrypt using tar + openssl AES-256
    tar czf - "$input_path" | openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -out "$output_file"

    if test $status -eq 0
        echo "Encrypted: $output_file"
    else
        echo "Error: encryption failed"
        return 1
    end
end
