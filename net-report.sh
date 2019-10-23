#!/bin/bash
#################################################################################################################################
#																#
# Script Name: RelatorioRede.sh													#
#  																#
# Description: Script in shell to scan network range (up to /24) to generate CSV format reports.				#
# Author: Marcus Costa														#
# Email Address: marcus.asc@gmail.com												#
# Execution Sample: "sh RelatorioRede.sh" or "./RelatorioRede.sh"								#
# 																#
#################################################################################################################################

# Getting network information by user.

read -p "Entre com os três primeiros octetos da rede(Ex.: 192.168.0): " net
read -p "Informe o IP inicial(Ex.: 1): " x
read -p "Informe o IP final(Ex.: 254): " z

# Setting report file name, if needed, you can change the file path.

arquivo=rel_rede-${net}\[$x-$z\]-$(date +%y%m%d).csv

# The next function will be used as param to collect data for each ip address, in ip's range list previously informed at beggining.
# The sequencial "cut" command has the function to extract exactly what do we need to inform in report fields.
# And the "egrep -v" command will negate the expression in '"', and bring all of other data to be filtered.

function porta(){
	ip=$1
	# Verifying if the IP address is associated to a domain name.
	dns=`echo $(nslookup $ip | egrep "arpa"|  cut -d"=" -f2 | cut -d" " -f2| cut -d"." -f1-4)`
	# Filtering TCP Service port name open in verified IP - Note.: This name is associated to NMAP command RFC, wich can bring some inconsistences about real service published information.
	nometcp=`echo $(nmap $ip | egrep -v "filtered" | egrep "*[0-9]/" | tr -s " " | cut -d" " -f3) | sed 's, ,/,g'`
	# Filtering TCP open service port in verified IP address.
	portatcp=`echo $(nmap $ip | egrep -v "filtered" | egrep "*[0-9]/" | cut -d"/" -f1 | cut -d" " -f2 | cut -d":" -f2- ) | sed 's, ,/,g'`

	# *Important Warning*: NMAP using UDP (not oriented connections) params scan can be excessively slow in this point.

	# Filtering UDP Service port name open in verified IP - Note.: As nometcp, this name is associated to NMAP command RFC, wich can bring some inconsistences about real service published information.
	nomeudp=`echo $(nmap -sU $1 | egrep "*[0-9]/" | tr -s " " | cut -d" " -f3) | sed 's, ,/,g'`
	# Filtering UDP open service port in verified IP address.
	portaudp=`echo $(nmap -sU $1 | egrep "*[0-9]/" | cut -d"/" -f1 | cut -d" " -f2 | cut -d":" -f2- ) | sed 's, ,/,g'`
	# Previously inserted list loop insertion to report file.
	for i in {$dns,';',$nometcp,';',$portatcp,';',$nomeudp,';',$portaudp,';',$endereco,'\n'};
        do
                echo -ne "$i" >> $arquivo
        done

}

# The next step will be used to generate the report file and a conectivity verification for each ip address, in ip's range list previously informed at beggining. If the address is in down state, will be informed just for record.

# Creating file with columns titles.	
echo "nome;servico_tcp;porta_tcp;servico_udp;porta_udp;endereco" > $arquivo
# Reading previously inserted list using a "for" loop.
for i in $( seq $x $z )
do
	endereco=$(echo "$net.$i")
	# Verifying IP address state.
	ping -c1 -W1 $endereco > /dev/null
	echo "Verificando IP $endereco"
		if [ $? == '0' ]
		then
			# Calling "porta" function to feed report fields.
			porta $endereco
		else
			# Just feeding with IP address.
			echo "$endereco" >> $arquivo
		fi
done

