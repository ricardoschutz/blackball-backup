#!/bin/bash

COR1="\e[01;32m"
COR2="\e[01;31m"
COR3="\e[0m"

function splashBlackball {

	echo
	echo -e "\t==================================="
	echo -e "\t=        ${COR1}B L A C K B A L L${COR3}        ="
	echo -e "\t==================================="
	echo -e "\t:: ${COR2}$1${COR3}"
	echo
	
}

function okay {
	echo -e "${COR1}OK${COR3}"
}

function erro {
	echo -e "${COR2}ERRO${COR3}"
}

function testa {
	[[ $? -eq 0 ]] && okay || erro $@
}

STR1=000NOMEDOSERVIDOR000
STR2=000DIRETORIOBASE000
STR3=000DESTINODOBACKUP000

NOMEDOSERVIDOR=`hostname`
DIRETORIOBASE="/opt/blackball-backup"
DESTINODOBACKUP="/backup"
USAXYMON="S"

splashBlackball "Preparacao do sistema de backup"

echo "Este script funciona somente uma vez!"
echo
read -p "Nome do servidor [$NOMEDOSERVIDOR]: " VAR
test -z "$VAR" || NOMEDOSERVIDOR=$VAR

read -p "Diretorio onde o sistema de backup esta instalado [$DIRETORIOBASE]: " VAR
test -z "$VAR" || DIRETORIOBASE=$VAR

read -p "Destino padrao do backup [$DESTINODOBACKUP]: " VAR
test -z "$VAR" || DESTINODOBACKUP=$VAR

read -p "Usa Xymon client para monitorar este servidor [$USAXYMON]: " VAR
test -z "$VAR" || USAXYMON=$VAR

echo -e "\nConfigurando backup padrao... "

echo -n -e "\tNome do servidor... "
find ${DIRETORIOBASE}/ -type f -exec sed -i -e "s:${STR1}:$NOMEDOSERVIDOR:g" {} \; > /dev/null 2>&1
testa

echo -n -e "\tDiretorio de instalacao... "
find ${DIRETORIOBASE}/ -type f -exec sed -i -e "s:${STR2}:$DIRETORIOBASE:g" {} \; > /dev/null 2>&1
testa

echo -n -e "\tDestino do backup... "
find ${DIRETORIOBASE}/ -type f -exec sed -i -e "s:${STR3}:$DESTINODOBACKUP:g" {} \; > /dev/null 2>&1
testa

echo -n -e "\tCriando diretorio de destino... "
mkdir -p $DESTINODOBACKUP > /dev/null 2>&1
testa

echo -n -e "\tCriando diretorios adicionais... "
mkdir -p ${DIRETORIOBASE}/log/backup > /dev/null 2>&1
testa

echo -n -e "\tPermitindo executar... "
mv ${DIRETORIOBASE}/etc/system-defaults ${DIRETORIOBASE}/etc/system-defaults.conf
testa

echo
echo "=== PRONTO! ===" 
echo
echo -e "[${COR1}*${COR3}] Teste o backup executando:"
echo -e "\t${COR1}${DIRETORIOBASE}/bin/backup.sh${COR3}"
echo
echo
echo -e "[${COR1}*${COR3}] Execute ${COR2}crontab -e${COR3} e adicione as seguintes linhas:"
echo
echo -e "# BLACKBALL Sistema de Backup"
echo -e "00\t00\t*\t*\t*\t${DIRETORIOBASE}/bin/backup.sh"
echo
echo

case "$USAXYMON" in
	S|s|Y|y)
		echo -e "[${COR1}*${COR3}] Edite o arquivo ${COR2}clientlaunch.cfg${COR3} do xymon e adicione:"
		echo
		echo -e "[backup]"
		echo -e "        ENVFILE \$XYMONCLIENTHOME/etc/xymonclient.cfg"
		echo -e "        CMD ${DIRETORIOBASE}/bin/xymon/backup.sh"
		echo -e "        LOGFILE \$XYMONCLIENTLOGS/xymonlaunch.log"
		echo -e "        INTERVAL 5m"
		echo
		;;
esac

echo
echo
echo -e "[${COR1}*${COR3}] Verifique em ${COR2}${DIRETORIOBASE}/etc/${COR3} as configuracoes adicionais."
echo

rm -f ${DIRETORIOBASE}/bin/instala-backup.sh > /dev/null 2>&1
