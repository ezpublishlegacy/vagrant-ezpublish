#!/usr/bin/env bash

whoami

sudo apt-get update

# install git
sudo apt-get -y install git

# install nginx
sudo apt-get -y install apache

# install php5
sudo apt-get -y install php5 php5-curl php5-cli php5-gd php5-intl php5-json libapache2-mod-php5 php5-xsl

sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
sudo apt-get -y install mysql-server

#sudo mysqladmin -u root root secretroot

sudo apt-get install -y mysql-client php5-mysql

# configuring apache
sudo /etc/init.d/apache2 stop
sudo chown -R vagrant:vagrant /var/log/apache2
sudo chown -R vagrant:vagrant /var/lock/apache2


# enable site gcda
if [ -f /etc/apache2/sites-enabled/000-default.conf ]; then
    sudo rm -rf /etc/apache2/sites-available/000-default.conf
fi

if [ -f /etc/apache2/sites-available/blog.conf ]; then
    sudo rm -rf /etc/apache2/sites-available/blog.conf
fi

sudo cat <<EOT >/vagrant/blog_conf
<VirtualHost *:80>
    <Directory /vagrant/ezpublish-community/web>
        Options FollowSymLinks
        AllowOverride None
        # depending on your global Apache settings, you may need to uncomment and adapt
        # for Apache 2.2 and earlier:
        #Allow from all
        # for Apache 2.4:
        Require all granted
    </Directory>

    # Environment.
    # Possible values: "prod" and "dev" out-of-the-box, other values possible with proper configuration
    # Defaults to "prod" if omitted
    SetEnv ENVIRONMENT "dev"

    # Whether to use Symfony's ApcClassLoader.
    # Possible values: 0 or 1
    # Defaults to 0 if omitted
    #SetEnv USE_APC_CLASSLOADER 0

    # Prefix used when USE_APC_CLASSLOADER is set to 1.
    # Use a unique prefix in order to prevent cache key conflicts
    # with other applications also using APC.
    # Defaults to "ezpublish" if omitted
    #SetEnv APC_CLASSLOADER_PREFIX "ezpublish"

    # Whether to use debugging.
    # Possible values: 0 or 1
    # Defaults to 0 if omitted, unless ENVIRONMENT is set to: "dev"
    #SetEnv USE_DEBUGGING 0

    # Whether to use Symfony's HTTP Caching.
    # Disable it if you are using an external reverse proxy (e.g. Varnish)
    # Possible values: 0 or 1
    # Defaults to 1 if omitted, unless ENVIRONMENT is set to: "dev"
    #SetEnv USE_HTTP_CACHE 1

    # Defines the proxies to trust.
    # Separate entries by a comma
    # Example: "proxy1.example.com,proxy2.example.org"
    # By default, no trusted proxies are set
    #SetEnv TRUSTED_PROXIES "127.0.0.1"

    <IfModule mod_php5.c>
        php_admin_flag safe_mode Off
        php_admin_value register_globals 0
        php_value magic_quotes_gpc 0
        php_value magic_quotes_runtime 0
        php_value allow_call_time_pass_reference 0
    </IfModule>

    DirectoryIndex index.php

    <IfModule mod_rewrite.c>
        RewriteEngine On

        # Uncomment in FastCGI mode or when using PHP-FPM, to get basic auth working.
        #RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

        # v1 rest API is on Legacy
        RewriteRule ^/api/[^/]+/v1/ /index_rest.php [L]

        # If using cluster, uncomment the following two lines:
        #RewriteRule ^/var/([^/]+/)?storage/images(-versioned)?/.* /index_cluster.php [L]
        #RewriteRule ^/var/([^/]+/)?cache/(texttoimage|public)/.* /index_cluster.php [L]

        RewriteRule ^/var/([^/]+/)?storage/images(-versioned)?/.* - [L]
        RewriteRule ^/var/([^/]+/)?cache/(texttoimage|public)/.* - [L]
        RewriteRule ^/design/[^/]+/(stylesheets|images|javascript|fonts)/.* - [L]
        RewriteRule ^/share/icons/.* - [L]
        RewriteRule ^/extension/[^/]+/design/[^/]+/(stylesheets|flash|images|lib|javascripts?)/.* - [L]
        RewriteRule ^/packages/styles/.+/(stylesheets|images|javascript)/[^/]+/.* - [L]
        RewriteRule ^/packages/styles/.+/thumbnail/.* - [L]
        RewriteRule ^/var/storage/packages/.* - [L]

        # Makes it possible to place your favicon at the root of your
        # eZ Publish instance. It will then be served directly.
        RewriteRule ^/favicon\.ico - [L]
        # Uncomment the line below if you want you favicon be served
        # from the standard design. You can customize the path to
        # favicon.ico by changing /design/standard/images/favicon\.ico
        #RewriteRule ^/favicon\.ico /design/standard/images/favicon.ico [L]
        RewriteRule ^/design/standard/images/favicon\.ico - [L]

        # Give direct access to robots.txt for use by crawlers (Google,
        # Bing, Spammers..)
        RewriteRule ^/robots\.txt - [L]

        # Platform for Privacy Preferences Project ( P3P ) related files
        # for Internet Explorer
        # More info here : http://en.wikipedia.org/wiki/P3p
        RewriteRule ^/w3c/p3p\.xml - [L]

        # Uncomment the following lines when using popup style debug in legacy
        #RewriteRule ^/var/([^/]+/)?cache/debug\.html.* - [L]

        # Following rule is needed to correctly display assets from eZ Publish5 / Symfony bundles
        RewriteRule ^/bundles/ - [L]

        # Additional Assetic rules for eZ Publish 5.1 / 2013.4 and higher.
        ## Don't forget to run php ezpublish/console assetic:dump --env=prod
        ## and make sure to comment these out in DEV environment.
        RewriteRule ^/css/.*\.css - [L]
        RewriteRule ^/js/.*\.js - [L]

        RewriteRule .* /index.php
    </IfModule>

    DocumentRoot /vagrant/ezpublish-community/web/
    ServerName local.ezp.local

</VirtualHost>
EOT

if [ ! -f /etc/apache2/envvars_bc ]; then
    cp /etc/apache2/envvars /etc/apache2/envvars_bc
fi

cat <<EOT >/etc/apache2/envvars

# envvars - default environment variables for apache2ctl

# this won't be correct after changing uid
unset HOME

# for supporting multiple apache2 instances
if [ "${APACHE_CONFDIR##/etc/apache2-}" != "${APACHE_CONFDIR}" ] ; then
        SUFFIX="-${APACHE_CONFDIR##/etc/apache2-}"
else
        SUFFIX=
fi

# Since there is no sane way to get the parsed apache2 config in scripts, some
# settings are defined via environment variables and then used in apache2ctl,
# /etc/init.d/apache2, /etc/logrotate.d/apache2, etc.
export APACHE_RUN_USER=vagrant
export APACHE_RUN_GROUP=vagrant
export APACHE_PID_FILE=/var/run/apache2$SUFFIX.pid
export APACHE_RUN_DIR=/var/run/apache2$SUFFIX
export APACHE_LOCK_DIR=/var/lock/apache2$SUFFIX
# Only /var/log/apache2 is handled by /etc/logrotate.d/apache2.
export APACHE_LOG_DIR=/var/log/apache2$SUFFIX

## The locale used by some modules like mod_dav
export LANG=C
## Uncomment the following line to use the system default locale instead:
#. /etc/default/locale

export LANG

## The command to get the status for 'apache2ctl status'.
## Some packages providing 'www-browser' need '--dump' instead of '-dump'.
#export APACHE_LYNX='www-browser -dump'

## If you need a higher file descriptor limit, uncomment and adjust the
## following line (default is 8192):
#APACHE_ULIMIT_MAX_FILES='ulimit -n 65536'


## If you would like to pass arguments to the web server, add them below
## to the APACHE_ARGUMENTS environment.
#export APACHE_ARGUMENTS=''

EOT

sudo mv /vagrant/blog_conf /etc/apache2/sites-available/blog.conf
sudo a2ensite blog.conf
sudo a2dissite 000-default.conf
sudo a2enmod rewrite

sudo /etc/init.d/apache2 restart

# Configuring les acces au fichier de application pour user cli et web
sudo usermod -g vagrant vagrant


# configure project
cd /vagrant/ezpublish-community
curl -s http://getcomposer.org/installer | php
php composer.phar install
