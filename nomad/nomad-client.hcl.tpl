log_level = "DEBUG"

data_dir = "/opt/nomad"
datacenter = "us-east-1"

client {
    enabled = true
    # Expecting to have DNS record for nomad server(s)
    servers = ["${nomad_server}:4647"]
    node_class = "linux-64bit"
    options = {"driver.raw_exec.enable" = "1"}
}