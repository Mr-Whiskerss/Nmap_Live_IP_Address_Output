#!/bin/bash

# ============================================
# Ping Sweep - Extract Live Hosts
# Supports: Subnet prefix (192.168.1) or CIDR (192.168.1.0/24)
# ============================================

# Colours
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No colour

# Default settings
TIMEOUT=1
THREADS=50

# Usage check
usage() {
    echo -e "${YELLOW}Usage:${NC} $0 <target> [output_file]"
    echo ""
    echo -e "${YELLOW}Target formats:${NC}"
    echo "  Subnet prefix:  192.168.1"
    echo "  CIDR /8:        10.0.0.0/8"
    echo "  CIDR /16:       172.16.0.0/16"
    echo "  CIDR /24:       192.168.1.0/24"
    echo "  CIDR /25-/30:   192.168.1.0/25"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 192.168.1"
    echo "  $0 192.168.1.0/24"
    echo "  $0 10.10.10.0/24 live_hosts.txt"
    echo "  $0 172.16.0.0/16 internal_hosts.txt"
    exit 1
}

if [[ $# -lt 1 ]]; then
    usage
fi

TARGET="$1"
OUTPUT="${2:-live_hosts_$(date +%Y%m%d_%H%M%S).txt}"

# ============================================
# CIDR Calculation Functions
# ============================================

# Convert IP to integer
ip_to_int() {
    local ip="$1"
    local a b c d
    IFS='.' read -r a b c d <<< "$ip"
    echo $(( (a << 24) + (b << 16) + (c << 8) + d ))
}

# Convert integer to IP
int_to_ip() {
    local int="$1"
    echo "$(( (int >> 24) & 255 )).$(( (int >> 16) & 255 )).$(( (int >> 8) & 255 )).$(( int & 255 ))"
}

# Calculate network range from CIDR
calc_cidr_range() {
    local cidr="$1"
    local ip="${cidr%/*}"
    local mask="${cidr#*/}"
    
    # Validate mask
    if [[ ! "$mask" =~ ^[0-9]+$ ]] || [[ "$mask" -lt 8 ]] || [[ "$mask" -gt 30 ]]; then
        echo -e "${RED}[!] Invalid CIDR mask. Supported range: /8 to /30${NC}"
        exit 1
    fi
    
    local ip_int=$(ip_to_int "$ip")
    local mask_bits=$(( 0xFFFFFFFF << (32 - mask) & 0xFFFFFFFF ))
    local network=$(( ip_int & mask_bits ))
    local broadcast=$(( network | (0xFFFFFFFF >> mask & 0xFFFFFFFF) ))
    
    # First and last usable host
    local first_host=$(( network + 1 ))
    local last_host=$(( broadcast - 1 ))
    local total_hosts=$(( last_host - first_host + 1 ))
    
    echo "$first_host $last_host $total_hosts"
}

# ============================================
# Ping Function
# ============================================

ping_host() {
    local ip="$1"
    if ping -c 1 -W "$TIMEOUT" "$ip" &>/dev/null; then
        echo -e "${GREEN}[+] $ip is up${NC}"
        echo "$ip" >> "$OUTPUT"
    fi
}

export -f ping_host ip_to_int int_to_ip
export TIMEOUT OUTPUT GREEN NC

# ============================================
# Main Logic
# ============================================

# Clear output file
> "$OUTPUT"

# Detect input format
if [[ "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # Simple subnet prefix format (e.g., 192.168.1)
    echo -e "${CYAN}============================================${NC}"
    echo -e "${YELLOW}[*] Mode: Subnet Prefix${NC}"
    echo -e "${YELLOW}[*] Target: ${TARGET}.0/24${NC}"
    echo -e "${YELLOW}[*] Range: ${TARGET}.1 - ${TARGET}.254${NC}"
    echo -e "${YELLOW}[*] Hosts: 254${NC}"
    echo -e "${YELLOW}[*] Timeout: ${TIMEOUT}s | Threads: ${THREADS}${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo ""
    
    seq 1 254 | xargs -P "$THREADS" -I {} bash -c "ping_host $TARGET.{}"

elif [[ "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
    # CIDR format (e.g., 192.168.1.0/24)
    read -r FIRST_HOST LAST_HOST TOTAL_HOSTS <<< "$(calc_cidr_range "$TARGET")"
    
    FIRST_IP=$(int_to_ip "$FIRST_HOST")
    LAST_IP=$(int_to_ip "$LAST_HOST")
    
    echo -e "${CYAN}============================================${NC}"
    echo -e "${YELLOW}[*] Mode: CIDR Notation${NC}"
    echo -e "${YELLOW}[*] Target: ${TARGET}${NC}"
    echo -e "${YELLOW}[*] Range: ${FIRST_IP} - ${LAST_IP}${NC}"
    echo -e "${YELLOW}[*] Hosts: ${TOTAL_HOSTS}${NC}"
    echo -e "${YELLOW}[*] Timeout: ${TIMEOUT}s | Threads: ${THREADS}${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo ""
    
    # Warning for large scans
    if [[ "$TOTAL_HOSTS" -gt 1000 ]]; then
        echo -e "${RED}[!] Warning: Large scan (${TOTAL_HOSTS} hosts). This may take a while.${NC}"
        read -p "Continue? (y/n): " confirm
        [[ "$confirm" != "y" ]] && exit 0
        echo ""
    fi
    
    # Generate IP range and sweep
    seq "$FIRST_HOST" "$LAST_HOST" | xargs -P "$THREADS" -I {} bash -c '
        ip=$(int_to_ip {})
        ping_host "$ip"
    '

else
    echo -e "${RED}[!] Invalid target format${NC}"
    echo ""
    usage
fi

# Sort output numerically by octets
sort -t '.' -k1,1n -k2,2n -k3,3n -k4,4n "$OUTPUT" -o "$OUTPUT"

# Summary
echo ""
echo -e "${CYAN}============================================${NC}"
LIVE_COUNT=$(wc -l < "$OUTPUT")
echo -e "${GREEN}[+] Scan complete${NC}"
echo -e "${GREEN}[+] Found ${LIVE_COUNT} live hosts${NC}"
echo -e "${GREEN}[+] Results saved to: ${OUTPUT}${NC}"
echo -e "${CYAN}============================================${NC}"

# Optional: Display results
if [[ "$LIVE_COUNT" -gt 0 ]] && [[ "$LIVE_COUNT" -le 50 ]]; then
    echo ""
    echo -e "${YELLOW}[*] Live hosts:${NC}"
    cat "$OUTPUT"
fi
