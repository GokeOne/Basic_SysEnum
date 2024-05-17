#!/bin/bash

date=$(date +'%d_%m_%Y_%H%M%S')
report="report_$date.txt"
line=$(printf "%0.s-" {1..50})

write_report() {
        local message=$1
        echo -e "$message" >> $report
}
line() {
	echo "$line" >>$report
}

enumerate() {
	#Esto saca los permisos de la carpeta /etc/passwd y con cut cogeriamos el 2 al 4 char
	perm=$(ls -l /etc/passwd | awk '{print $1}' | cut -c 8-10)
	if [ $perm == "r--"  ] || [ $perm == "r-x" ] || [ $perm == "rw-" ] || [ $perm == "rwx" ]; then
		local etcpass=$(cat /etc/passwd)
		write_report "\033[34m\033[1m System users:  \033[0m"
		line
		write_report "$etcpass"
		line
	else
		line
		local message2="/etc/passwd don't have read permissions"
		write_report "$message2"
		line
	fi
	kernelName="\033[34m\033[1m Kernel name:\033[0m $(uname -s)"
	kernelRelease="\033[34m\033[1m Kernel release:\033[0m $(uname -r)"
	kernelVersion="\033[34m\033[1m Kernel version:\033[0m $(uname -v)"
	machineArch="\033[34m\033[1m Architecture:\033[0m $(uname -m)"
	os="\033[34m\033[1m Operating System:\033[0m $(uname -o)"

	write_report "$kernelName"
	line
	write_report "$kernelRelease"
	line
	write_report "$kernelVersion"
	line
	write_report "$machineArch"
	line
	write_report "$os"
	line

	write_report "\033[34m\033[1m System info\033[0m"
	line
	etcRelease="$(cat /etc/*release)"
	write_report "$etcRelease"
	line
	write_report "\033[34m\033[1m Disk information \033[0m"
	line
	diskinf=$(df -h)
	write_report "$diskinf"
	line

	write_report "\033[34m\033[1m Installed kernels \033[0m"
	line

	inskernel=$(dpkg -l linux-image-*)
	write_report "$inskernel"
	line

	write_report "\033[34m\033[1m Arp table \033[0m"
	line
	arptable=$(arp -e)
	write_report "$arptable"
	line

	write_report "\033[34m\033[1m User info \033[0m"
	line
	who=$(whoami)
	write_report "Whoami: $who"
	host=$(cat /etc/hostname)
	write_report "Hostname: $host"
	write_report "ID: $(id)"
	line

	write_report "\033[34m\033[1m Last connections \033[0m"
	line
	write_report "$(last)"
	line

	write_report "\033[34m\033[1m Open port connections \033[0m"
	line
	write_report "$(netstat -tuln)"
	line
}

enumerate
