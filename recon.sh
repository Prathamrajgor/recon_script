#!/bin/bash
echo "[+] \n Script Started \n"
echo "[+] \n This script might take some time to run. "
mkdir subdomains
echo "[+] \n Enumerating Subdomains for $1\n"
cd subdomains
echo "Enumerating using Amass, Subfinder, Findomain and Knockpy"
touch subdomains.txt
(subfinder -d $1 | tee -a subdomains.txt) & (assetfinder $1 | tee -a subdomains.txt) & (findomain -t $1 -u findomain.txt) & wait
mkdir knock
knockpy -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt  $1 -o knock
cd knock
cat * | jq "keys[]" | sed "/_meta/d" |sed "s/\"//g" | tee sub.txt
cd ../
cat subdomains.txt findomain.txt knock/sub.txt | sed "s/www.//g" | sort -u | tee subdomains.txt
wc subdomains.txt -l
cd ../
echo "[+] \n Subdomain Enumeration complete\n"
echo "[+] \n Checking for subdomain takeover\n"
mkdir subtake
cd subtake
echo "[Info] Using Subjack and Cname Enumerator"
(subjack -w ../subdomains/subdomains.txt -v | tee subjack.txt) & (node /usr/bin/cname.js ../subdomains/subdomains.txt)
sort -u active.txt -o active.txt
cd ../
echo "[+] \n Subdomain Takeover testing compleated\n"
echo "[+] \n Filtering active domains\n"
mkdir active
cd active
echo > active.txt
echo "[Info] Using httpx and httprobe"
(cat ../subdomains/subdomains.txt | httpx | tee -a active.txt) & 
(cat ../subdomains/subdomains.txt | httprobe | tee -a active.txt) & wait
cat active.txt | sed "s/www.//g" | sort -u active.txt -o active.txt 
echo "[Info] Active domains are"
wc active.txt -l
cd ../
echo "[+] \n Filtered out the active domains\n"
echo "[+] \n Collecting all the urls\n"
mkdir urls
cd urls
echo "[Info] Using waybackurls and gau"
echo > urls.txt
cat ../active/active.txt | gau --threads 25 | tee -a urls.txt
sort -u urls.txt -o urls.txt 
echo "[Info] Extracting js files"
cat urls.txt | grep -w js | tee js.txt
cd ../
echo "[+] \n Done collecting urls\n"
echo "[+] \n Starting Directory bruteforcing"
mkdir fuzz
cd fuzz
echo > fuzz.txt
echo "[Info] Staring Gobuster"
cat ../active/active.txt  | parallel -j 10 "(gobuster dir  -w /usr/share/seclists/Discovery/Web-Content/common.txt --url {} | tee -a fuzz.txt)" 
cd ../
echo "\n[+] \n Directory bruteforced successfully"
echo "Do you want to use aquatone on the active domains? "
read -p "Enter Y or y for yes, N or n for No.  Y or N ?  " ans
if [[ ($ans == "Y") || $ans == "y" ]]
then
    mkdir aquatone
    cd aquatone
    cat ../active/active.txt | aquatone
    cd ../ 
else
    echo "[+] \n You said no"
fi
echo "[+] \n Enumeration Compleated Successfully!"
echo "[Info ]Staring Python server on port 8000. visit Localhost 8000 to view the report. "
python -m http.server 8000 

