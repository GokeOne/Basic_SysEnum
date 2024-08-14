#!/bin/bash


# Color Definitions
C=$(printf '\033')
RED="${C}[1;31m"
GREEN="${C}[1;32m"
YELLOW="${C}[1;33m"
BLUE="${C}[1;34m"
MAGENTA="${C}[1;35m"
CYAN="${C}[1;36m"
LIGHT_GRAY="${C}[1;37m"
DARK_GRAY="${C}[1;90m"
NC="${C}[0m" # No Color
UNDERLINED="${C}[4m"
ITALIC="${C}[3m"

# Report time mark
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


check_permission() {
    if [ "$EUID" -ne 0 ]; then
        write_report "${YELLOW}[WARNING]${NC} This script is not running as root. Some information might be incomplete."
        line
    fi
}

#Check if we have read permissions in etc/passwd and if we have, show all users there are in system
check_etc_passwd() {
	if [ -r /etc/passwd ]; then
		etc_passwd=$(cat /etc/passwd)
		write_report "${BLUE}${UNDERLINED}System users:${NC}"
		line
		write_report "$etc_passwd"
		line
	else
		write_report "${RED}[ERROR]$[NC]/etc/passwd does not have read permissions."
		line
	fi
}

#Show system info
kernel_info() {
	write_report "${BLUE}${UNDERLINED}System Information:${NC}"
	line
	uname_info=$(uname -a)
	write_report "$uname_info"
	line

	if [ -f /etc/os-release ]; then
		os_info=$(cat /etc/os-release)
		write_report "$os_info"
		line
	fi

	if command -v lsb_release &> /dev/null; then
		lsb_info=$(lsb_release -a)
		write_report "$lsb_info"
		line
	fi

}
#Get all disks we have in system
all_disk() {
	lsblk -nd --output NAME,TYPE | awk '$2 == "disk" {print "/dev/" $1}'
}

#Show disk information
disk_information() {
	write_report "${BLUE}${UNDERLINED}Disk information:${NC}"
	line
	disk_info=$(df -hT)
	write_report "$disk_info"
	line
	if command -v iostat &> /dev/null; then
		#3 seconds of cpu/disk work
		stat_io=$(iostat -x 1 3)
		if [ $? -ne 0 ]; then
			write_report "${YELLOW}[WARNING]${NC}You can't execute this program."
		else
			write_report "${BLUE}${UNDERLINED}Timestamp of disk ${NC}"
			line
			write_report "$stat_io"
			line
		fi
	fi
	if command -v lsblk &> /dev/null; then
		partitions=$(lsblk)
		write_report "${CYAN}${UNDERLINED}Partition information${NC}"
		line
		write_report "$partitions"
		line
	fi

	if command -v fdisk &> /dev/null; then
		if [[ $EUID -ne 0  ]]; then
			write_report "${RED}[ERROR]${NC}Error getting detailed disk partition information"
			line
		else
			part_info=$(fdisk -l)
			write_report "${CYAN}${UNDERLINED}Detailed information${NC}"
			line
			write_report "$part_info"
			line
		fi
	fi
	if command -v smartctl &> /dev/null; then
		if [[ $EUID -ne 0 ]]; then
			write_report "${RED}[ERROR]${NC}Error executing smartctl, u dont have permissions"
			line
		else
			for disk in $(all_disk); do
				write_report "${GREEN}Information for $disk${NC}"
				detail_inf=$(smartctl -a -T permissive $disk)
				write_report "$detail_inf"
				line
			done
		fi


	fi
}

#Show installed kernels in system
list_kernels() {
	if command -v dpkg &> /dev/null; then
		write_report "${BLUE}${UNDERLINED}Installed kernels:${NC}"
		line
		kernels=$(dpkg -l | grep linux-image)
		write_report "$kernels"
		line
	elif command -v rpm &> /dev/null; then
		write_report "${BLUE}${UNDERLINED}Installed kernels (RPM):${NC}"
		line
		kernels=$(rpm -qa | grep kernel)
		write_report "$kernels"
		line
	else
		write_report "${YELLOW}[WARNING]${NC}Package manager not found."
		line
	fi
}

#Show arp table
arp_table() {
	if command -v arp &> /dev/null; then
		write_report "${BLUE}${UNDERLINED}ARP Table:${NC}"
		line
		table=$(arp -e)
		write_report "$table"
		line
	else
		write_report "${YELLOW}ARP command not found. Install requirments. ${NC}"
		line
	fi
}

#Display user information.
user_information() {
	write_report "${BLUE}${UNDERLINED}User information:${NC}"
	line
	who_info=$(whoami)
	host_info=$(hostname)
	id_info=$(id)
	group_info=$(groups)
	write_report "${BLUE} User:${NC} $who_info"
	write_report "${BLUE} Hostname:${NC} $host_info"
	write_report "${BLUE} ID:${NC} $id_info"
	write_report "${BLUE} Groups:${NC} $group_info"
	line
}

#show last logins in system
last_logins() {
	if command -v last &> /dev/null; then
		write_report "${BLUE}${UNDERLINED}Last logins:${NC}"
		line
		last_info=$(last -a | head -n 5)
		write_report "$last_info"
		line
	else
		write_report "${YELLOW}[WARNING]${NC} Command not found, can't display last login info"
		line
	fi
}

open_ports() {
	write_report "${BLUE}${UNDERLINED}Open network ports:${NC}"
	line
	if command -v netstat &> /dev/null; then
		netstat_info=$(netstat -tuln)
		write_report "$netstat_info"
		line
	elif command -v ss &> /dev/null; then
		ss_info=$(ss -tuln)
		write_report "$ss_info"
		line
	else
		wirte_report "${YELLOW}[WARNING]${NC}Neither netstat or ss found. Cannot display open ports"
		line
	fi
}

running_processes() {
	write_report "${BLUE}${UNDERLINED}Running processes:${NC}"
	line
	ps_info=$(ps aux --sort=-%mem | head -n 20)
	write_report "$ps_info"
	line
}

#Function to show all crontab jobs
cron_jobs() {
	write_report "${BLUE}${UNDERLINED}Cron jobs:${NC}"
	line
	if [ -d /etc/cron.d ]; then
		cron_files=$(ls /etc/cron.d)
		write_report "${GREEN}[INFO]${NC}System-wide cron jobs:"
		write_report "$cron_files"
	else
		write_report "${YELLOW}[WARNING]${NC}No system-wide cron jobs found."
	fi
	#If it's empty, there are not any crontab list
	user_cron=$(crontab -l 2>/dev/null)
	if [ -n "$user_cron" ]; then
		write_report "User cron jobs: "
		write_report "$user_cron"
		line
	else
		write_report "${YELLOW}[WARNING]${NC}No user-specific cron jobs found."
		line
	fi
}

enumerator() {
	check_etc_passwd
	kernel_info
	disk_information
	list_kernels
	arp_table
	user_information
	last_logins
	open_ports
	running_processes
	cron_jobs
}

enumerator
