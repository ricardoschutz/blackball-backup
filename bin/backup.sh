#!/bin/bash

DIRNAME=`dirname $0`
RUNNINGPATH="`pwd`/`dirname $0`"
[[ "${DIRNAME:0:1}" == "/" ]] && RUNNINGPATH="`dirname $0`"

if [[ ! -e "${RUNNINGPATH}/../etc/system-defaults.conf" ]]; then
        echo
        echo -e "POR FAVOR EXECUTE O SCRIPT instala-backup.sh"
        echo
        exit 1
fi

. ${RUNNINGPATH}/../etc/system-defaults.conf

. ${BLACKBALL_BIN}/blackball-common-functions

###############
#    BIN
###############

LOG_DATE=`date +%Y%m%d`
LOG="${BLACKBALL_LOG}/backup/backup-${LOG_DATE}.log"
LOGMONITOR="${BLACKBALL_LOG}/backup/backup-monitor.log"

NUMCMD=0
GOTERROR="no"

DURACAO=0
export DURACAO

function okay {

	echo -e "${COR1}OK${COR3}"

}

function erro {

	GOTERROR="yes"
	THISONEGOTERROR="yes"

	echo -e "${COR2}ERRO${COR3}"
	
	[[ -n "$1" ]] && loga "ERRO: $@"
	
}

function testa {

	[[ $? -eq 0 ]] && okay || erro $@

}

function loga {
	echo -e "$@" >> $LOG
}

################
# BACKUP

function executaComando {
	
	loga "executaComando: $@"
	$@ >> $LOG 2>&1
	testa "executaComando: $@"
	
}

function comandosPreBackup {

	[[ -z "$ANTES" ]] && return
	
	echo -e "\tComandos pre-backup..."

	NUMCMD=0
	for (( i=0; i < ${#ANTES[@]}; i++ )); do
		NUMCMD=$(( $NUMCMD + 1 ))
		echo -e -n "\t\tExecutando comando $NUMCMD ... "
		executaComando ${ANTES[$i]}
	done
	
	unset ANTES
	
}

function comandosPosBackup {

	[[ -z "$APOS" ]] && return
	
	echo -e "\tComandos pos-backup..."

	NUMCMD=0
	for (( i=0; i < ${#APOS[@]}; i++ )); do
		NUMCMD=$(( $NUMCMD + 1 ))
		echo -e -n "\t\tExecutando comando $NUMCMD ... "
		executaComando ${APOS[$i]}
	done
	
	unset APOS
	
}

function validaBackupTar {

	echo -e -n "\t\tvariavel ARQUIVO ... "
	[[ -n "$ARQUIVO" ]]
	testa "validaBackupTar: variavel ARQUIVO nao foi configurada"

	echo -e -n "\t\tdiretorio de destino ... "
	[[ -d "`dirname $ARQUIVO`" ]] || mkdir -p `dirname $ARQUIVO`
	testa "validaBackupTar: diretorio `dirname $ARQUIVO` nao encontrado"
	
	echo -e -n "\t\tvariavel DIRS ... "
	[[ -n "$DIRS" ]]
	testa "validaBackupTar: variavel DIRS nao foi configurada"
	
}

function fazBackupTar {
	
	echo -e "\tTipo de backup: ${COR1}tar${COR3}"
	loga "Tipo: tar"
	
	validaBackupTar
	
	comandosPreBackup
	
	if [[ "$THISONEGOTERROR" == "no" ]]; then
                if [[ -n "$EXCLUDE" ]]; then
			EXCLUDECMD=""
			for (( j=0; j < ${#EXCLUDE[@]}; j++ )); do
				EXCLUDECMD="$EXCLUDECMD --exclude='${EXCLUDE}'"
			done

			echo -e -n "\tExecutando backup tar ... "
			executaComando tar zcpf ${ARQUIVO} ${EXCLUDECMD} ${DIRS[@]}
		else
			echo -e -n "\tExecutando backup tar ... "
			executaComando tar zcpf $ARQUIVO ${DIRS[@]}
		fi

		TAMARQBKP=`ls -l ${ARQUIVO} | awk '{ print $5 }'`
	else
		loga "fazBackupTar: Backup nao executado devido a erros anteriores."
	fi
	
	comandosPosBackup
	
	unset ARQUIVO
	unset DIRS
	unset EXCLUDE
	
}

function validaBackupDpkg {

	echo -e -n "\t\tvariavel ARQUIVO ... "
	[[ -n "$ARQUIVO" ]]
	testa "validaBackupDpkg: variavel ARQUIVO nao foi configurada"

	echo -e -n "\t\tdiretorio de destino ... "
	[[ -d "`dirname $ARQUIVO`" ]] || mkdir -p `dirname $ARQUIVO`
	testa "validaBackupDpkg: diretorio `dirname $ARQUIVO` nao encontrado"
	
}

function fazBackupDpkg {
	
	echo -e "\tTipo de backup: ${COR1}dpkg${COR3}"
	loga "Tipo: dpkg"

	validaBackupDpkg
	
	comandosPreBackup
	
	if [[ "$THISONEGOTERROR" == "no" ]]; then
		echo -e -n "\tExecutando backup dpkg ... "
		loga "fazBackupDpkg: Executando dpkg --get-selections"
		dpkg --get-selections > $ARQUIVO 2>>$LOG
		testa "fazBackupDpkg: Problema ao executar dpkg --get-selections"

		TAMARQBKP=`ls -l ${ARQUIVO} | awk '{ print $5 }'`
	else
		loga "fazBackupDpkg: Backup nao executado devido a erros anteriores."
	fi
	
	comandosPosBackup
	
	unset ARQUIVO
	
}

function validaBackupAcl {

	echo -e -n "\t\tvariavel ARQUIVO ... "
	[[ -n "$ARQUIVO" ]]
	testa "validaBackupAcl: variavel ARQUIVO nao foi configurada"

	echo -e -n "\t\tdiretorio de destino ... "
	[[ -d "`dirname $ARQUIVO`" ]] || mkdir -p `dirname $ARQUIVO`
	testa "validaBackupAcl: diretorio `dirname $ARQUIVO` nao encontrado"
	
	echo -e -n "\t\tvariavel DIR ... "
	[[ -n "$DIR" ]]
	testa "validaBackupAcl: variavel DIR nao foi configurada"
	
}

function fazBackupAcl {
	
	echo -e "\tTipo de backup: ${COR1}acl${COR3}"
	loga "Tipo: acl"
	
	validaBackupAcl
	
	comandosPreBackup
	
	if [[ "$THISONEGOTERROR" == "no" ]]; then
		echo -e -n "\tExecutando backup de ACLs ... "
		loga "executaComando: $GETFACL -R --skip-base $DIR > $ARQUIVO"
		${GETFACL} -R --skip-base ${DIR} > ${ARQUIVO} 2>> $LOG
		testa

		TAMARQBKP=`ls -l ${ARQUIVO} | awk '{ print $5 }'`
	else
		loga "fazBackupAcl: Backup nao executado devido a erros anteriores."
	fi
	
	comandosPosBackup
	
	unset ARQUIVO
	unset DIR
	
}

function validaBackupMysql {

	echo -e -n "\t\tvariavel USUARIO ... "
	[[ -n "$USUARIO" ]]
	testa "validaBackupMysql: variavel USUARIO nao foi configurada"
	
	echo -e -n "\t\tvariavel SENHA ... "
	[[ -n "$SENHA" ]]
	testa "validaBackupMysql: variavel SENHA nao foi configurada"

	echo -e -n "\t\tvariavel ARQUIVO ... "
	[[ -n "$ARQUIVO" ]]
	testa "validaBackupMysql: variavel ARQUIVO nao foi configurada"

	echo -e -n "\t\tdiretorio de destino ... "
	[[ -d "`dirname $ARQUIVO`" ]] || mkdir -p `dirname $ARQUIVO`
	testa "validaBackupMysql: diretorio `dirname $ARQUIVO` nao encontrado"
	
	echo -e -n "\t\tvariavel DATABASES ... "
	[[ -n "$DATABASES" ]]
	testa "validaBackupMysql: variavel DATABASES nao foi configurada"

}

function fazBackupMysql {
	
	echo -e "\tTipo de backup: ${COR1}MySQL${COR3}"
	loga "Tipo: MySQL"
	
	validaBackupMysql
	
	comandosPreBackup
	
	if [ "${DATABASES[@]}" == "all" ]; then
		PARAMS="--all-databases"
	else
		PARAMS="--databases ${DATABASES[@]}"
	fi

	if [[ "$THISONEGOTERROR" == "no" ]]; then
		echo -e -n "\tExecutando backup MySQL ... "
		loga "executaComando: mysqldump -u ${USUARIO} -p ${PARAMS} > ${ARQUIVO}"
		mysqldump -u ${USUARIO} -p${SENHA} ${PARAMS} > ${ARQUIVO} 2>> $LOG
		testa

		TAMARQBKP=`ls -l ${ARQUIVO} | awk '{ print $5 }'`
	else
		loga "fazBackupMysql: Backup nao executado devido a erros anteriores."
	fi
	
	comandosPosBackup
	
	unset USUARIO
	unset SENHA
	unset DATABASES
	unset ARQUIVO

}


function validaBackupRsync {

	echo -e -n "\t\tvariavel PARAMS ... "
	[[ -n "$PARAMS" ]]
	testa "validaBackupRsync: variavel PARAMS nao foi configurada"

	echo -e -n "\t\torigem ... "
	[[ -n "$ORIGEM" ]]
	testa "validaBackupRsync: variavel ORIGEM nao foi configurada"
	
	echo -e -n "\t\tdestino ... "
	[[ -n "$DESTINO" ]]
	testa "validaBackupRsync: variavel DESTINO nao foi configurada"
	
}

function fazBackupRsync {
	
	echo -e "\tTipo de backup: ${COR1}rsync${COR3}"
	loga "Tipo: rsync"
	
	validaBackupRsync
	
	comandosPreBackup
	
	if [[ "$THISONEGOTERROR" == "no" ]]; then
#                if [[ -n "$EXCLUDE" ]]; then
#			EXCLUDECMD=""
#			for (( j=0; j < ${#EXCLUDE[@]}; j++ )); do
#				EXCLUDECMD="$EXCLUDECMD --exclude='${EXCLUDE}'"
#			done
#
#			echo -e -n "\tExecutando backup rsync ... "
#			executaComando rsync ${PARAMS} ${EXCLUDECMD} ${ORIGEM} ${DESTINO}
#		else
			echo -e -n "\tExecutando backup rsync ... "
			executaComando rsync ${PARAMS} ${ORIGEM} ${DESTINO}
#		fi

		TAMARQBKP=`du -s ${DESTINO} | awk '{ print $1 }'`
	else
		loga "fazBackupRsync: Backup nao executado devido a erros anteriores."
	fi
	
	comandosPosBackup
	
	unset PARAMS
	unset ORIGEM
	unset DESTINO
	unset EXCLUDE
	
}

function executaBackup {
	# Uso: executaBackup TIPO
	
	if [[ -z "$1" ]]; then
		echo -e "${COR2}Variavel TIPO nao configurada${COR3}\n"
		loga "executaBackup: Variavel TIPO nao configurada"
		return
	fi
	
	TIPO=`echo $1 | tr 'A-Z' 'a-z'`
	
	case "$TIPO" in
		"tar")
			fazBackupTar
			;;
		"mysql")
			fazBackupMysql
			;;
		"acl")
			fazBackupAcl
			;;
		"dpkg")
			fazBackupDpkg
			;;
		"rsync")
			fazBackupRsync
			;;
		*)
			echo -e "${COR2}Tipo invalido: $1 ${COR3}"
			loga "executaBackup: Tipo de backup invalido: $1"
	esac
	
	unset TIPO
	echo
	
}

function carregaVars {

	loga "\nConfiguracao: $1"
	
	echo -n "Lendo arquivo \"$1\"... "
	[[ -f "${BLACKBALL_ETC}/$1" ]]
	testa "carregaVars: Arquivo nao encontrado \"$1\""

	. ${BLACKBALL_ETC}/$1
	
}

function iniciaLog {
	loga "--------------"
	loga "--- INICIO ---"
	loga `date "+%d/%m/%Y  %H:%M:%S  %A"`
}

function carregaListaBackups {

	BACKUPS=`ls -1 ${BLACKBALL_ETC} | grep ^backup- | grep .conf$`

}

function iniciaRelatorioMonitor {

	rm -f $LOGMONITOR 2>> $LOG

	DURACAO=`date +%s`
	export DURACAO

}

function finalizaRelatorioMonitor {

        DATA2=`date +%s`
	DURACAO=`expr $DATA2 - $DURACAO`
	echo "##duracao;$DURACAO" >> $LOGMONITOR

}


function relatorioMonitor {

	echo "${NOMEBKP};${THISONEGOTERROR};${BKP};${TAMARQBKP}" >> $LOGMONITOR

}

function executarAntes {

	. ${BLACKBALL_ETC}/backup.conf

	[[ -z "$CMDPRE" ]] && return
	
	echo -e "Executar antes:"

	NUMCMD=0
	for (( i=0; i < ${#CMDPRE[@]}; i++ )); do
		NUMCMD=$(( $NUMCMD + 1 ))
		echo -e -n "\tExecutando comando $NUMCMD ... "
		executaComando ${CMDPRE[$i]}
	done

	echo
	
	unset CMDPRE
	
}

function executarDepois {

	. ${BLACKBALL_ETC}/backup.conf

	[[ -z "$CMDPOS" ]] && return
	
	echo
	echo -e "Executar depois:"

	loga ""

	NUMCMD=0
	for (( i=0; i < ${#CMDPOS[@]}; i++ )); do
		NUMCMD=$(( $NUMCMD + 1 ))
		echo -e -n "\tExecutando comando $NUMCMD ... "
		executaComando ${CMDPOS[$i]}
	done
	
	unset CMDPOS

}

function startBackup {

	iniciaLog
	
	iniciaRelatorioMonitor
	
	executarAntes

	carregaListaBackups

	for BKP in ${BACKUPS[@]}; do
		THISONEGOTERROR="no"
		carregaVars $BKP
		executaBackup $TIPO
		relatorioMonitor
	done

	executarDepois

	finalizaRelatorioMonitor

}

function endBackup {

	loga "--- FIM ---"
	loga "\n"
	
#	if [[ "$1" != "-t" ]]; then
#		[[ "$GOTERROR" == "yes" ]] && mutt -s "[${SERVERNAME}] Backup ERRO" "monitor@blackballti.com" < $LOG
#		[[ "$GOTERROR" == "no" ]] && mutt -s "[${SERVERNAME}] Backup OK" "monitor@blackballti.com" < $LOG
#	fi

}

function startSingleBackup {

        executarAntes

	THISONEGOTERROR="no"
	carregaVars $1
	executaBackup $TIPO

	executarDepois

}

function endBackup {

        loga "--- FIM ---"
	loga "\n"

}


splashBlackball "Sistema de backup"

if [[ -n "$1" ]]; then
        startSingleBackup $1
else
	startBackup
fi
	
endBackup
