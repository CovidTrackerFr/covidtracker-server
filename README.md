# Configuration serveur dédié à CovidTracker

Ce dépôt contient la configuration du serveur pour [le site CovidTracker](https://covidtracker.fr).

## Que fait le script d'installation ?

Le script installe ces outils sur une base d'Ubuntu 20.04 :

- Serveur web :
    - [Caddy 2](https://caddyserver.com) ;
    - PHP 7.4 ;
    - MySQL 8 ;
    - [WP-CLI](http://wp-cli.org/fr/) ;
- Terminal :
    - ZSH et [oh-my-zsh](http://ohmyz.sh).

Il installe aussi les fichiers de configuration stockés dans le sous-dossier `/etc/`, grâce à des liens symboliques qui simplifient ensuite les mises à jour.

Il crée enfin les dossiers nécessaires pour héberger les sites et les logs : 

- Données : dans `/var/www/ndd.fr` ;
- Logs : dans `/var/log/caddy/`.

## Mode d'emploi

### Configuration initiale du serveur

Le script d'installation est conçu pour être exécuté à partir d'un serveur sous Ubuntu 20.04 et d'un compte avec les autorisations root. 


### Récupérer le dépôt

Clonez le dépôt à partir du dossier utilisateur qui servira à exécuter le script. Les configurations seront aussi stockées dans ce dossier et liées vers ce dossier, donc il ne faudra plus y toucher.

    git clone https://github.com/nicolinuxfr/covidtracker.fr.git ~/config

### Lancer le script

Certaines opérations nécessitent les permissions root, d'où le `sudo`. 

    sudo ~/config/tools/install.sh

⚠️ **ATTENTION** ⚠️

Ne relancez pas le script une deuxième fois sur un serveur !

### Après le script

Le script indique à la fin la commande à exécuter depuis un ordinateur local, ou bien sur le serveur précédent, pour initier le transfert des données. Par simplicité, le transfert est effectué en root.

Après cela, importer les données MySQL et lancer Caddy. Pour le HTTPS, le nom de domaine doit déjà pointer sur le serveur.

Le script `post-install.sh` se charge d'importer les données : 

    ~/config/tools/post-install.sh

