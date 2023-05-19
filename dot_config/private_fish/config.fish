if status is-interactive
    # Commands to run in interactive sessions can go here
end

op completion fish | source

# Hledger settings
set -gx LEDGER_FILE /Users/ivan/hledger/main.journal

# Set PATH
set PATH $PATH ~/.emacs.d/bin

# Set DOCKER envs for Colima
set -gx DOCKER_HOST unix://$HOME/.colima/default/docker.sock
set -gx TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE /var/run/docker.sock
