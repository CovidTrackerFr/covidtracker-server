#!/bin/sh
# Script d'optimisation et de sauvegarde de la base de données. Repose sur WP-CLI. 

DATE=`date +%Y-%m-%d`

echo "Optimisation et sauvegarde de la base de données : $DATE"

cd /var/www/covidtracker.fr/

# Optimisations (basé sur https://gist.github.com/lukecav/66f1039edcd2827fd1bde82dce86a2be)
/usr/local/bin/wp --allow-root transient delete --expired 
/usr/local/bin/wp --allow-root cache flush
/usr/local/bin/wp --allow-root db optimize

# Sauvegarde
/usr/local/bin/wp --allow-root db export - | gzip > /home/ubuntu/backup/$DATE.sql.gz

# Permissions
chown -R ubuntu:ubuntu /home/ubuntu/backup/

# Nettoyage des anciennes sauvegardes (5 derniers jours)
find /home/ubuntu/backup/ -maxdepth 1 -type f -mmin +7200 | xargs rm -rf