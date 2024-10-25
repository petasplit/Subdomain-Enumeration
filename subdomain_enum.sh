
#!/bin/bash

# Kali Linux Subdomain Discovery Script
# Author: Your Name
# Description: Comprehensive subdomain discovery using multiple tools

# Prompt for the domain if not provided as a command-line argument
if [ -z "$1" ]; then
    read -p "Please enter the main domain (e.g., example.com): " DOMAIN
else
    DOMAIN=$1
fi

OUTPUT_DIR="${DOMAIN}_subdomain_results"
WORDLIST="/usr/share/wordlists/rockyou.txt"

if [ -z "$DOMAIN" ]; then
    echo "No domain provided. Exiting..."
    exit 1
fi

# Step 1: Install dependencies
echo "[*] Installing dependencies..."
sudo apt update
sudo apt install -y git golang python3-pip dnsrecon gobuster feroxbuster jq
pip3 install --upgrade waybackurls gotator mksub dsieve regulator linkfinder

# Install Go-based tools
GO_BIN_PATH=$(go env GOPATH)/bin
export PATH=$PATH:$GO_BIN_PATH
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/lc/gospider@latest
go install github.com/OWASP/Amass/v3/...@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/blechschmidt/massdns@latest

# Clone and install other tools
echo "[*] Cloning and setting up additional tools..."
mkdir -p $OUTPUT_DIR
cd $OUTPUT_DIR

# Step 2: Run subdomain discovery tools
echo "[*] Running Subfinder..."
subfinder -d $DOMAIN -o subfinder_results.txt

echo "[*] Using Waybackurls..."
echo $DOMAIN | waybackurls > waybackurls_results.txt

echo "[*] Using Gotator for permutations..."
gotator -sub subfinder_results.txt -perm permutations.txt -output gotator_results.txt

echo "[*] Using Dnsgen for additional permutations..."
dnsgen subfinder_results.txt > dnsgen_results.txt

echo "[*] Using Mksub for wordlist manipulation..."
mksub -l $WORDLIST -d $DOMAIN -o mksub_results.txt

echo "[*] Filtering results with Dsieve..."
dsieve -i dnsgen_results.txt -o dsieve_results.txt

echo "[*] Using Regulator for refining wordlists..."
regulator -w permutations.txt -r regulator_results.txt

echo "[*] Running DNS resolution..."
cat gotator_results.txt dnsgen_results.txt dsieve_results.txt | sort -u | massdns -r /path/to/resolvers.txt -o S -w massdns_results.txt

# Step 3: Use additional tools for web crawling and link discovery
echo "[*] Running Gospider for crawling..."
gospider -s "https://$DOMAIN" -o gospider_results.txt

echo "[*] Running Linkfinder for link extraction..."
python3 /path/to/linkfinder.py -i gospider_results.txt -o linkfinder_results.txt

# Step 4: Perform content discovery with Feroxbuster and Gobuster
echo "[*] Running Feroxbuster..."
feroxbuster -u "https://$DOMAIN" -w /usr/share/wordlists/dirb/common.txt -o feroxbuster_results.txt

echo "[*] Running Gobuster..."
gobuster dns -d $DOMAIN -w /usr/share/wordlists/dirb/common.txt -o gobuster_results.txt

# Step 5: Final aggregation of results
echo "[*] Aggregating results..."
cat subfinder_results.txt waybackurls_results.txt gotator_results.txt dnsgen_results.txt mksub_results.txt massdns_results.txt gospider_results.txt linkfinder_results.txt | sort -u > final_subdomains.txt

echo "[*] Subdomain discovery completed. Results saved in final_subdomains.txt"
