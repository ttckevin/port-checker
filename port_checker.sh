#!/bin/bash
directory=$1
username=$2
password=$3
domain="{$4:-}"

if [ -z "$directory" ] || [ -z "$username" ] || [ -z "$password" ]; then
	echo "Usage: $0 <DIRECTORY> <USERNAME> <PASSWORD> <DOMAIN>"
	exit 2
fi

> master_ports.txt

find "$directory" -type f -name "full_scan.gnmap" | while read -r file; do

    host=$(basename $(dirname "$file"))
    cat "$file" | awk -F "Ports:" '{print $2}' | \
    awk -F',' '{for (i=1;i<=NF;i++){print $i}}' | \
    awk -F'/' -v h="$host" '{print h "," $1}' >> master_ports.txt
done

while read -r line; do
    IFS=',' read host port <<< "$line"
    case "$port" in
        22)
	        echo "[Msg]: ssh..."
			sshpass -p "$password" ssh -o StrictHostKeyChecking=no "${username}@${host}"
            ;;
        445)
	        echo "[Msg]: rpcclient, smbclient..."
            rpcclient -U "${domain}\\${username}%${password}" "$host"
			smbclient -L "\\\\${host}\\" -U "$username" --password="$password"
            ;;
        514)
            echo "[Msg]: Rservices..."
            rlogin "$host" -l "$username"
            ;;
        1433)
            echo "[Msg]: MSSQL..."
            impacket-mssqlclient -windows-auth "${domain}/${username}:${password}@${host}"
            ;;
        3306)
            echo "[Msg]: MySQL..."
            mysql -u "$username" -p"$password" -h "$host"
            ;;
        3389)
            echo "[Msg]: RDP..."
            xfreerdp3 /v:"$host" /u:"$username" /p:"$password" 
            ;;
		3389)
            echo "[Msg]: WinRM..."
            evil-winrm -i "$host" -u "$username" -p "$password" 
            ;;
        110)
            echo "[Msg]: POP3..."
            curl --connect-timeout 5 --url "pop3://$host/" --user "${username}:${password}"
            ;;
        995)
            echo "[Msg]: POP3S..."
            curl --connect-timeout 5 --url "pop3s://$host/" --user "${username}:${password}"
            ;;
        143)
            echo "[Msg]: IMAP..."
            curl --connect-timeout 5 --url "imap://$host/INBOX" --user "${username}:${password}"
            ;;
        993)
            echo "[Msg]: IMAPs..."
            curl --connect-timeout 5 --url "imaps://$host/INBOX" --user "${username}:${password}"
            ;;
    esac
done < master_ports.txt                                                                                                                                                                     