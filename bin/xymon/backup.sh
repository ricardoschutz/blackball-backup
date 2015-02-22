#!/bin/bash

TEST=backup
export COLOR=green
OUTFILE=/blackball/tmp/hobbit-bkp.tmp
OUTFILE2=/blackball/tmp/hobbit-bkp2.tmp
OUTFILE3=/blackball/tmp/hobbit-bkp3.tmp
ARQSAIDA=/blackball/tmp/hobbit-backup-full.tmp

TESTFILE=/blackball/log/backup/backup-monitor.log
BACKUPLOG=/blackball/log/backup/backup-`date +%Y%m%d`.log

function imprimeLinha {


	echo -n -e "<td align=\"center\" style=\"padding: 5px 30px;\">$1</td>" >> $OUTFILE
	echo -n -e "<td align=\"left\" style=\"padding: 5px 30px;\">$2</td>" >> $OUTFILE
	echo -n -e "<td align=\"center\" style=\"padding: 5px 30px;\">$3</td>" >> $OUTFILE
	echo "<td align=\"left\" style=\"padding: 5px 30px;\">$4</td></tr>" >> $OUTFILE

	if [[ "$1" == "&green" ]]; then
		echo "OK $2 [ $4 ]" >> $OUTFILE3
	else
		echo "ERRO $2 [ $4 ]" >> $OUTFILE3
	fi

}

echo "green" > $OUTFILE2
echo "" > $OUTFILE3

TEMPO=$(( `date +%s` - `date -r /blackball/log/backup/backup-monitor.log +%s` ))
TEMPO_HORAS=$(( $TEMPO / 3600 ))

if [[ $TEMPO -gt 87000 ]]; then
	echo "red" > $OUTFILE2
	echo "&red Ultimo backup executado ha $TEMPO segundos ($TEMPO_HORAS horas)." >> $OUTFILE
else
	echo "&green Ultimo backup executado ha $TEMPO segundos ($TEMPO_HORAS horas)." >> $OUTFILE
fi

echo "" >> $OUTFILE
#echo "===== BACKUPS =====" >> $OUTFILE

PAR=0
echo "<table style=\"border: 0px;\"><tr><th>Status</th><th>Descri&ccedil;&atilde;o</th><th>Tamanho</th><th>Arquivo Conf.</th></tr>" >> $OUTFILE
grep -v '^##' $TESTFILE | while read LINE; do
	NOME=`echo $LINE | cut -d";" -f1`
	ERRO=`echo $LINE | cut -d";" -f2`
	CONFFILE=`echo $LINE | cut -d";" -f3`
	TAMARQBKP=`echo $LINE | cut -d";" -f4`
	TAMARQBKPH=0
        if [[ $TAMARQBKP -gt 1048576 ]]; then
                TAMARQBKPH="$(( $TAMARQBKP / 1048576 )),`printf "%03d" $(( ( 1000 * ( ($TAMARQBKP / 1024) % 1024 ) ) / 1024 ))` MB"
        elif [[ $TAMARQBKP -gt 1024 ]]; then
                TAMARQBKPH="$(( $TAMARQBKP / 1024 )),`printf "%03d" $(( ( 1000 * ( $TAMARQBKP % 1024 ) ) / 1024 ))` KB"
        else
                TAMARQBKPH="$TAMARQBKP bytes"
        fi

	[[ $PAR -eq 0 ]] && PAR="0.05" || PAR=0
	
	echo -n "<tr style=\"background-color: rgba(255,255,255,${PAR});\">" >> $OUTFILE
	
	if [[ "$ERRO" == "yes" ]]; then
		echo "red" > $OUTFILE2
		imprimeLinha "&red" "$NOME" "-" "$CONFFILE"
	else
		imprimeLinha "&green" "$NOME" "$TAMARQBKPH" "$CONFFILE"
	fi

done

echo "</table>" >> $OUTFILE

# Prepara secao de comentarios
LINE=`grep '##duracao' ${TESTFILE}`
DURACAO=`echo $LINE | cut -d";" -f2`

echo "" >> $OUTFILE
echo "Tempo de execucao: $(( ${DURACAO} / 60 )) min $(( ${DURACAO} % 60 )) s" >> $OUTFILE

COLOR=`cat $OUTFILE2`

if [[ "$COLOR" == "red" ]]; then
	echo "" >> $OUTFILE
	echo "" >> $OUTFILE
	echo "Dump do arquivo de log:" >> $OUTFILE
	echo "" >> $OUTFILE
	cat $BACKUPLOG >> $OUTFILE
fi

# Prepara o arquivo de saida final
date > $ARQSAIDA
echo "<!--" >> $ARQSAIDA
cat $OUTFILE3 >> $ARQSAIDA
echo "-->" >> $ARQSAIDA
echo "" >> $ARQSAIDA
cat $OUTFILE >> $ARQSAIDA

$BB $BBDISP "status $MACHINE.$TEST $COLOR `< $ARQSAIDA`"

rm -f $OUTFILE2
rm -f $OUTFILE3
rm -f $OUTFILE
rm -f $ARQSAIDA
