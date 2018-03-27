# blackball-backup
Script simples, prático e fácil de configurar para backup de arquivos, ACL, MySQL e dpkg com script para monitoramento pelo Xymon.

## Compatibilidade
Testado somente no debian.

## Instalação
Recomendo instalar o script em /opt.
```
cd /opt
git clone https://github.com/ricardoschutz/blackball-backup.git
```
Execute o instalador e siga os passos indicados pelo instalador.
```
/opt/blackball-backup/bin/instala-backup.sh
```
## Configuração
Siga os exemplos localizados em /opt/blackball-backup/etc/

### Ativar um exempo
Renomeie o arquivo removendo a extensão .exemplo
```
mv backup-mysql.conf.exemplo backup-mysql.conf
```
