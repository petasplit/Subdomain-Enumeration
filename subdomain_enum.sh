#!/bin/bash

# Update and upgrade the system
echo "[+] Updating system..."
sudo apt update && sudo apt upgrade -y

# Ask for the domain input
read -p "Enter the domain to gather subdomains for: " DOMAIN
if [ -z "$DOMAIN" ]; then
    echo "[-] No domain provided. Please run the script again and enter a domain."
    exit 1
fi

# Install Go if not already installed
if ! [ -x "$(command -v go)" ]; then
    echo "[+] Installing Golang..."
    sudo apt install golang -y
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export PATH=$GOPATH/bin:$PATH
    echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
    echo "export GOPATH=$HOME/go" >> ~/.bashrc
    echo "export PATH=$GOPATH/bin:$PATH" >> ~/.bashrc
    source ~/.bashrc
fi

# Create a directory for subdomain tools
mkdir -p ~/subdomain_tools
cd ~/subdomain_tools

# Install Subfinder
echo "[+] Installing Subfinder..."
GO111MODULE=on go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

# Install Sublist3r
echo "[+] Installing Sublist3r..."
sudo apt install sublist3r -y

# Install Amass
echo "[+] Installing Amass..."
sudo apt install amass -y

# Install Assetfinder
echo "[+] Installing Assetfinder..."
go install -v github.com/tomnomnom/assetfinder@latest

# Install DNSx
echo "[+] Installing DNSx..."
GO111MODULE=on go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest

# Install PureDNS
echo "[+] Installing PureDNS..."
GO111MODULE=on go install github.com/d3mondev/puredns/v2@latest

# Install DNSRecon
echo "[+] Installing DNSRecon..."
sudo apt install dnsrecon -y

# Install DNSenum
echo "[+] Installing DNSenum..."
sudo apt install dnsenum -y

# Install Findomain
echo "[+] Installing Findomain..."
wget https://github.com/findomain/findomain/releases/latest/download/findomain-linux
chmod +x findomain-linux
sudo mv findomain-linux /usr/local/bin/findomain

# Install Knockpy
echo "[+] Installing Knockpy..."
sudo apt install python3-pip -y
pip3 install knockpy

# Install DNScan
echo "[+] Installing DNScan..."
git clone https://github.com/rbsec/dnscan.git
cd dnscan
pip3 install -r requirements.txt
cd ..

# Install Sudomy
echo "[+] Installing Sudomy..."
git clone --recursive https://github.com/screetsec/Sudomy.git
cd Sudomy
pip3 install -r requirements.txt
cd ..

# Install Domained
echo "[+] Installing Domained..."
git clone https://github.com/TypeError/domained.git
cd domained
pip3 install -r requirements.txt
cd ..

# Install Gotator
echo "[+] Installing Gotator..."
go install github.com/Josue87/gotator@latest

echo "[+] All tools installed successfully."

# Running subdomain enumeration using installed tools
OUTPUT_FILE="all_subdomains.txt"
TEMP_DIR="subdomains_temp"
mkdir -p $TEMP_DIR

echo "[+] Starting subdomain enumeration for $DOMAIN..."

# Run each tool and collect the results
subfinder -d $DOMAIN -silent > $TEMP_DIR/subfinder.txt
sublist3r -d $DOMAIN -o $TEMP_DIR/sublist3r.txt
amass enum -passive -d $DOMAIN -o $TEMP_DIR/amass.txt
assetfinder --subs-only $DOMAIN > $TEMP_DIR/assetfinder.txt
knockpy $DOMAIN -o $TEMP_DIR/knockpy_output
cat $TEMP_DIR/knockpy_output/$DOMAIN.csv | cut -d, -f1 | tail -n +2 > $TEMP_DIR/knockpy.txt
dnsx -d $DOMAIN -silent > $TEMP_DIR/dnsx.txt
puredns bruteforce $DOMAIN > $TEMP_DIR/puredns.txt
dnsrecon -d $DOMAIN -t brt -o $TEMP_DIR/dnsrecon.xml
cat $TEMP_DIR/dnsrecon.xml | grep "<hostname>" | sed -e 's/<[^>]*>//g' > $TEMP_DIR/dnsrecon.txt
dnsenum $DOMAIN -o $TEMP_DIR/dnsenum.xml
cat $TEMP_DIR/dnsenum.xml | grep "<hostname>" | sed -e 's/<[^>]*>//g' > $TEMP_DIR/dnsenum.txt
findomain -t $DOMAIN -q > $TEMP_DIR/findomain.txt
python3 dnscan/dnscan.py -d $DOMAIN -o $TEMP_DIR/dnscan.txt
python3 Sudomy/sudomy.py -d $DOMAIN -o $TEMP_DIR/sudomy.txt
python3 domained/domained.py $DOMAIN > $TEMP_DIR/domained.txt
gotator -sub $TEMP_DIR/subfinder.txt -perm mutations.txt -depth 1 -numbers 10 -mindup > $TEMP_DIR/gotator.txt

# Combine, sort, and deduplicate results
echo "[+] Combining results..."
cat $TEMP_DIR/*.txt | sort -u > $OUTPUT_FILE

# Clean up temporary files
rm -rf $TEMP_DIR

echo "[+] Subdomain enumeration completed."
echo "Results saved in $OUTPUT_FILE"
