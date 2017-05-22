log_level = "DEBUG"
data_dir = "/opt/nomad"

server {
    enabled = true
    bootstrap_expect = 1

    # We might need to consider running more than one Nomad server
    # servers = [...]
}