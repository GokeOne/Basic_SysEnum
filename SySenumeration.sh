#!/bin/bash

date=$(date +'%d_%m_%Y_%H%M%S')
report="report_$date.txt"
line=$(printf "%0.s-" {1..50})

write_report() {
        local message=$1
        echo "$message" >> $report
}
line() {
	echo "$line" >>$report
}

enumerate() {
	#Esto saca los permisos de la carpeta /etc/passwd y con cut cogeriamos el 2 al 4 char
	perm=$(ls -l /etc/passwd | awk '{print $1}' | cut -c 8-10)
	if [ $perm == "r--"  ] || [ $perm == "r-x" ] || [ $perm == "rw-" ] || [ $perm == "rwx" ]; then
		local etcpass=$(cat /etc/passwd)
		write_report="We have read permissions"
		write_report "$etcpass"
		line
	else
		local message2="/etc/passwd don't have read permissions"
		write_report "$message2"
		line
	fi
	kernelName="Kernel name: $(uname -s)"
	kernelRelease="Kernel release: $(uname -r)"
	kernelVersion="Kernel version: $(uname -v)"
	machineArch="Architecture: $(uname -m)"
	os="Operating System: $(uname -o)"

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

	write_report "System info"
	line
	etcRelease="$(cat /etc/*release)"
	write_report "$etcRelease"
	line
	write_report "Disk information"
	line
	diskinf=$(df -h)
	write_report "$diskinf"
	line

	write_report "Installed kernels"
	line

	inskernel=$(dpkg -l linux-image-*)
	write_report "$inskernel"
	line

	write_report "Arp table"
	line
	arptable=$(arp -e)
	write_report "$arptable"
	line

	write_report "User info"
	line
	who=$(whoami)
	write_report "Whoami: $who"
	host=$(cat /etc/hostname)
	write_report "Hostname: $host"
	write_report "ID: $(id)"
	line

	write_report "Last connections"
	line
	write_report "$(last)"
	line

	write_report "Open port connections"
	line
	write_report "$(netstat -tuln)"
	line
}

enumerate
