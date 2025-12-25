# Nmap_Live_IP_Address_Output

# Ping Sweep - Live Host Discovery

A fast, multi-threaded bash script for discovering live hosts on a network using ICMP ping requests. Supports both simple subnet notation and CIDR notation for flexible network scanning.

## Features

- **Multiple input formats**: Subnet prefix (192.168.1) or CIDR notation (192.168.1.0/24)
- **CIDR support**: /8 through /30 networks
- **Multi-threaded**: 50 concurrent threads for fast scanning
- **Auto-generated output**: Timestamped filenames prevent overwrites
- **Sorted results**: Output sorted numerically by IP address
- **Large scan protection**: Confirmation prompt for networks over 1000 hosts
- **Coloured output**: Easy identification of live hosts

## Installation
```bash
# Clone or download the script
git clone https://github.com/yourusername/pingsweep.git

# Make executable
chmod +x pingsweep.sh

# Optional: Move to PATH for global access
sudo cp pingsweep.sh /usr/local/bin/pingsweep
```

## Usage
```bash
./pingsweep.sh <target> [output_file]
```

### Target Formats

| Format | Example | Hosts Scanned |
|--------|---------|---------------|
| Subnet prefix | `192.168.1` | 254 |
| CIDR /24 | `192.168.1.0/24` | 254 |
| CIDR /25 | `192.168.1.0/25` | 126 |
| CIDR /16 | `172.16.0.0/16` | 65,534 |
| CIDR /8 | `10.0.0.0/8` | 16,777,214 |

### Examples
```bash
# Basic scan using subnet prefix
./pingsweep.sh 192.168.1

# CIDR /24 scan
./pingsweep.sh 192.168.1.0/24

# CIDR /25 scan (half subnet)
./pingsweep.sh 192.168.1.0/25

# Specify custom output file
./pingsweep.sh 10.10.10.0/24 targets.txt

# Large network scan
./pingsweep.sh 172.16.0.0/16 internal_hosts.txt
```

## Output

### Console Output
```
============================================
[*] Mode: CIDR Notation
[*] Target: 192.168.1.0/24
[*] Range: 192.168.1.1 - 192.168.1.254
[*] Hosts: 254
[*] Timeout: 1s | Threads: 50
============================================

[+] 192.168.1.1 is up
[+] 192.168.1.10 is up
[+] 192.168.1.25 is up

============================================
[+] Scan complete
[+] Found 3 live hosts
[+] Results saved to: live_hosts_20241215_142530.txt
============================================
```

### Output File

The script generates a clean text file with one IP per line, sorted numerically:
```
192.168.1.1
192.168.1.10
192.168.1.25
```

## Configuration

Default settings can be modified at the top of the script:
```bash
TIMEOUT=1       # Ping timeout in seconds
THREADS=50      # Number of concurrent threads
```

### Adjusting for Different Environments

| Environment | Recommended Settings |
|-------------|---------------------|
| Local LAN | `TIMEOUT=1` `THREADS=50` |
| Remote/VPN | `TIMEOUT=2` `THREADS=25` |
| Slow network | `TIMEOUT=3` `THREADS=10` |

## Requirements

- Bash 4.0+
- Standard Linux utilities: `ping`, `xargs`, `seq`, `sort`

## Integration

### Using Output with Other Tools
```bash
# Feed results to nmap
nmap -iL live_hosts.txt -sC -sV -oA detailed_scan

# Use with NetExec
netexec smb live_hosts.txt

# Quick service check
cat live_hosts.txt | xargs -I {} nc -zv {} 445
```

### Adding as Bash Alias

Add to your `~/.bash_aliases` or `~/.bashrc`:
```bash
alias pingsweep='/path/to/pingsweep.sh'
```

## Limitations

- Requires ICMP to be allowed through firewalls
- Some hosts may block ping requests
- Large scans (/8, /16) can take considerable time
- Minimum CIDR supported is /8, maximum is /30

## Troubleshooting

### No hosts found

- Verify network connectivity
- Check if ICMP is blocked by firewall
- Try increasing the timeout value

### Permission errors

- Some networks require root for raw ICMP
- Run with `sudo` if needed

### Slow scanning

- Reduce thread count on slower networks
- Increase timeout for high-latency connections

## License

MIT License - Feel free to modify and distribute.

## Author

[Your Name]

## Contributing

Pull requests welcome. For major changes, please open an issue first.
