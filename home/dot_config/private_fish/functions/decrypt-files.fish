# ~/.config/fish/functions/decrypt.fish

function decrypt-files
    # Parse arguments
    set -l input_file ""
    set -l output_dir "."

    argparse 'o=' -- $argv 2>/dev/null
    set input_file $argv[1]
    set output_dir $_flag_o

    # Validate input
    if test -z "$input_file"
        echo "Usage: decrypt <file.enc> [-o output_dir]"
        return 1
    end

    if not test -f "$input_file"
        echo "Error: '$input_file' not found"
        return 1
    end

    # Use current dir if -o not provided
    if test -z "$output_dir"
        set output_dir "."
    end

    # Decrypt using openssl + tar
    openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -in "$input_file" | tar xzf - -C "$output_dir"

    if test $status -eq 0
        echo "Decrypted into: $output_dir"
    else
        echo "Error: decryption failed (wrong password?)"
        return 1
    end
end
