#!/bin/bash
#################################################################################################################################
#																#
# Script Name: get-rb.sh													#
#  																#
# Description: Script in shell to a few data from routerboards and export it to an CSV file.					#
# Author: Marcus Costa														#
# Email Address: marcus.asc@gmail.com												#
# Execution Sample: "sh get-rb.sh" or "./get-rb.sh"										#
# 																#
#################################################################################################################################
# Declaring global variables
arquivo="$(date +%H:%M)rbss.csv"
senha="123qwe"
user="admin"
porta="22"
origem="relatorio.txt"
# Test if host is UP with a simple ICMP package.
function testa_ping(){
	echo > online.txt
	for i in $(cat relatorio.txt | cut -d " " -f1)
	 do
		ping -c1 -W1 $i > /dev/null
                	if [ $? -eq 0 ]
                       		then
					#If host is UP, the address will be sent to a file named "online.txt"
					echo $i >> online.txt
				else
					#If host is DOWN, the address will be sent to a file named "log_descon.txt" for future analisys.
					echo "Endereco $i offline" >> log_descon.txt					
			fi
	done
}
# Test both TCP ports, 8291 (Winbox) to ensure if it is a RouterOS and 22 (SSH) to ensure if protocol to access is UP.
function testa_porta(){
	echo > mikrotiks.txt && echo > nao_mikrotiks.txt
	for i in $(cat online.txt | cut -d " " -f1)	
	do
		nmap -p 8291 $i && nmap -p 22 $i >> /dev/null
			if [ $? == 0 ]
			then
				# If these ports reply, the "mikrotiks.txt" file will be created and serve to future query.
				echo $i >> mikrotiks.txt
			else
				# If these ports dont reply to requests, the following file will be generated.
				echo $i >> nao_mikrotiks.txt
			fi
	done
}
# These following commands will show some informations about these Routerboard - You can edit it as well, according your necessity - trying some text filters to adequade the command return (I'm collect the IP address 2 time just for test, but you can set others informations like traffic, CPU consumption, etc.)
function comandos(){
	
	comando1=`sshpass -p $senha ssh -o StrictHostKeyChecking=no $user@$1 -p $porta '/system identity print' | cut -d ":" -f2 | cut -d" " -f2 | head -n1 | tr -d ''`		
	comando2=`sshpass -p $senha ssh -o StrictHostKeyChecking=no $user@$1 -p $porta '/ip address print' | egrep "*[0-9]" |  cut -d " " -f4- | cut -d "/" -f1 | tr -d ''`
}
# Running the functions
testa_ping
testa_porta
# Initialize the file with title rows
echo "End_IP;Device;QTDE_Cliente"> $arquivo
# Start the data colect for CSV file. 
for i in $(cat mikrotiks.txt | cut -d " " -f1)
	do
		comandos $i
		for j in {${i},';',${comando1},';',${comando2},'\n'}
			do
				echo -ne "$j" >> $arquivo
			done
	done

