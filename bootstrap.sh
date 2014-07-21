#!/usr/bin/env bash

# APT
echo "Updating APT"
apt-get update > /dev/null 2>&1

# Mysql
echo "Configuring mysql"
debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password password vagrant' > /dev/null 2>&1
debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password_again password vagrant' > /dev/null 2>&1

apt-get install -y mysql-server > /dev/null 2>&1

# PHP5
echo "Installing php"
apt-get install -y php5-fpm php5-cli php5-xdebug php5-mysql php5-curl php5-gd git > /dev/null 2>&1

sed -i '/;date.timezone =/c date.timezone = Europe/Copenhagen' /etc/php5/cli/php.ini
sed -i '/;date.timezone =/c date.timezone = Europe/Copenhagen' /etc/php5/fpm/php.ini

sed -i '/upload_max_filesize = 2M/cupload_max_filesize = 256M' /etc/php5/fpm/php.ini
sed -i '/post_max_size = 8M/cpost_max_size = 256M' /etc/php5/fpm/php.ini

sed -i '/;listen.owner = www-data/c listen.owner = vagrant' /etc/php5/fpm/pool.d/www.conf
sed -i '/;listen.group = www-data/c listen.group = vagrant' /etc/php5/fpm/pool.d/www.conf
sed -i '/;listen.mode = 0660/c listen.mode = 0660' /etc/php5/fpm/pool.d/www.conf

# Nginx
echo "Installing nginx"
apt-get install -y nginx > /dev/null 2>&1
unlink /etc/nginx/sites-enabled/default

# Setup web root
ln -s /vagrant/htdocs /var/www

# Memcache
echo "Installing memcache"
apt-get install -y memcached php5-memcached > /dev/null 2>&1

# APC
echo "Configuring APC"
apt-get install -y php-apc > /dev/null 2>&1

cat > /etc/php5/conf.d/apc.ini <<DELIM
apc.enabled=1
apc.shm_segments=1
apc.optimization=0
apc.shm_size=64M
apc.ttl=7200
apc.user_ttl=7200
apc.num_files_hint=1024
apc.mmap_file_mask=/tmp/apc.XXXXXX
apc.enable_cli=1
apc.cache_by_default=1
DELIM

cat << DELIM >> /etc/php5/conf.d/20-xdebug.ini
xdebug.remote_enable=1
xdebug.remote_handler=dbgp
xdebug.remote_host=192.168.50.1
xdebug.remote_port=9000
xdebug.remote_autostart=0
DELIM

# Config files into nginx
cat > /etc/nginx/sites-available/service.indholdskanalen.vm.conf <<DELIM
server {
  server_name service.indholdskanalen.vm;
  root /var/www/backend_indholdskanalen/web;
  access_log /var/log/nginx/backend_indholdskanalen_access.log;
  error_log /var/log/nginx/backend_indholdskanalen_error.log;
  location / {
    try_files \$uri @rewriteapp;
  }
  location @rewriteapp {
    rewrite ^(.*)\$ /app_dev.php/\$1 last;
  }
  location ~ ^/(app|app_dev|config)\.php(/|\$) {
    fastcgi_pass unix:/var/run/php5-fpm.sock;
    fastcgi_split_path_info ^(.+\.php)(/.*)\$;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    fastcgi_param HTTPS off;
  }
  location ~ /\.ht {
    deny all;
  }
}
DELIM

# Symlink
ln -s /etc/nginx/sites-available/service.indholdskanalen.vm.conf /etc/nginx/sites-enabled/service.indholdskanalen.vm.conf

# SSL
mkdir /etc/ssl/nginx
cat > /etc/ssl/nginx/server.key <<DELIM
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAr/XEHIjUq9JiI2ciKjJ6a/bdf5/3FxrJXIYiw+rFO7GEy+ly
RfALVhMiZpZQOo4fYk0AvTb3ZtTmwRDvP3uIsE/xicK7p+F+78xXUzFDDJGoFtSg
jyiSS3Vqv/Eo7tQWPcZI0xRlKUMH1X2yerasesodBfUArEU7o7aXP8pv03saU2YG
wITIMV5kKN51+AiqWu7BFFNsf1djBIahGt20vFTJvbKdWMSv/9hqDE2Bm2fW2qZf
Sd5+VF1R9LTIERuvrkR/pOwcDXxOYUf8DBOFVINZOaBAIU3+2cZEXsskyfAfhS3W
aT4DIQA8pVqvn9E4bnopGzWhLgu44IhKlHGEgQIDAQABAoIBAHFO15xwWFLUxTF7
BjsaCk9fxr6aaejM7QHRtq1mjt+jrpoIl/eFXidtZuecv8kVIAyS/Xja3nGvg3Cr
0QSWLi0rLaTCa0juImmUsl72B/EeEpmxDjthquNAlx9G0k8I79GTz+1s4r+xVGgb
60SuQV9Iq2vcmzRT2NXRjJAdcelB+KO+0Vb/y7e5D6QKwbXXSQGOZ2XvQ3/KsO1p
lw1zLmbZ5FtqtXFP469hjjiI30R71kYSpH5tcCDvLrkHbvBiQoiToedPWF8bVnvl
CJRUmXWgVedGc3xciBC63BQ46ebJu+2/4oTcWJMxjPAAN8SRe7hcVCHQhlOLv3gl
76INt2kCgYEA4NDzDzmk6WGbnFRd7dFBiIyhnweMVkRUkcQlq3eW9JZhgkH7Tlzp
kvIZxcWSNwpnLJW1GaUWw2S/VPeESLuWgePIfUPKOdLtAd0/gSPQQC873t8LhtTy
Pvf5pryDG9BiMeg6JwrHUMRkwPX3RjcQM3qTAWzfY7qUuvMZuYg8QC8CgYEAyF34
mH88ixc24HOczRtbAWI7XaQPsFze4K7TlL6MR9umwSw1L67L9FSgDAFjzsYrxzFe
J4mReNNm6RQ0APeJmf4IZju1lQd/VeLr4b43wgtj949K+uqAJLE9q44WZtri+FQy
WIjrvSAwSGrfBwNMLE9whipGUmQCDmpoljdOKk8CgYEAt0/pQNrh6yKZvejVBhuA
chUpnACNn7Hru0fS53OF9T3BmHKwtX7xPc6G0Up+JL8ozaPsnVKNsxktId0JUj0T
RiozymBCPtAMTV7YbzaCkjNxgBMi1PhB5rJQMHK5/S33Q3Z2JGuXhfX9qZFl5Sz0
2uTxhVH+/NSgfafHrA64AiUCgYAZdt/mOZ1vK+cchXTzGDvrpBlZYEViK5tjwLRB
Hipj44WA3WZxBe0Dw1GH1RFjMQpVSW/m5HPpgCx/CMNHMC57tK5Kl+IO66ICP1Gt
IeiiL6Jnzv0/gFgC0ce9qtQsBDt+Re0UFWqoYZPhUDvB/2hJ5VquombHh9A/FsTt
+l9jvwKBgQC8utARFyZbhpa42HSq8JpE2GV4/JHGo+a+jGI4CKus+HYLG4ILL3sd
dsyYppekDo9LOvD7jMCKb2bmNcLeGhihcwzVYSg+ivpO9kVGB8wzpxdTVXKH4bCo
QiaYLGAU81Y0EJrmw1vin6jQY92+JSnou/ZgOKTqWEpvBV4pvOBacA==
-----END RSA PRIVATE KEY-----
DELIM

cat > /etc/ssl/nginx/server.cert <<DELIM
-----BEGIN CERTIFICATE-----
MIIDCzCCAfOgAwIBAgIJAOeMvrD8wE0fMA0GCSqGSIb3DQEBBQUAMBwxGjAYBgNV
BAMMEWluZm9zdGFuZGVyLmxvY2FsMB4XDTE0MDMzMTEwMzYyNVoXDTI0MDMyODEw
MzYyNVowHDEaMBgGA1UEAwwRaW5mb3N0YW5kZXIubG9jYWwwggEiMA0GCSqGSIb3
DQEBAQUAA4IBDwAwggEKAoIBAQCv9cQciNSr0mIjZyIqMnpr9t1/n/cXGslchiLD
6sU7sYTL6XJF8AtWEyJmllA6jh9iTQC9Nvdm1ObBEO8/e4iwT/GJwrun4X7vzFdT
MUMMkagW1KCPKJJLdWq/8Sju1BY9xkjTFGUpQwfVfbJ6tqx6yh0F9QCsRTujtpc/
ym/TexpTZgbAhMgxXmQo3nX4CKpa7sEUU2x/V2MEhqEa3bS8VMm9sp1YxK//2GoM
TYGbZ9bapl9J3n5UXVH0tMgRG6+uRH+k7BwNfE5hR/wME4VUg1k5oEAhTf7ZxkRe
yyTJ8B+FLdZpPgMhADylWq+f0ThueikbNaEuC7jgiEqUcYSBAgMBAAGjUDBOMB0G
A1UdDgQWBBS2aKYdKQHo9VWVz5a+PUFwubdsRzAfBgNVHSMEGDAWgBS2aKYdKQHo
9VWVz5a+PUFwubdsRzAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBBQUAA4IBAQAj
wmFkHq5NXwqG0QF98tVG+7iU9LqT18gyOjLw/oZeSgE+FI4D1+2ejft838/usE7M
8IEps5apWVJ1RtUv5yiFatxMhbrYEQLiTuMv395MzOiYcnf6Q3hV5cC3ADOquuLq
LRd4KWb2Y7gx0dzO9+bPd5l+JjF3OXNJuGFKhq8K0/UrYz1X+hXQWmDxzUyv8W63
fCtg8B4069q5jh2nk8Zz5PjxWpekQ9kRGhu59vSQa2Bk+lVhlKo4sGF5o22Nu2Es
MPIM5fVpjlk86lZVGGCN97Y1Jghl01p6ZkmIwyd7Heg+Xdc+yTHGWKrzgOOjH9Tr
FRMjoVlMmXmMnDeGuB4l
-----END CERTIFICATE-----
DELIM

# Create database
echo "Setting up database indholdskanalen"
echo "create database indholdskanalen" | mysql -uroot -pvagrant

# Setup backend indholdskanalen
echo "Setting up composer"
cd /vagrant/htdocs/backend_indholdskanalen
curl -sS http://getcomposer.org/installer | php  > /dev/null 2>&1

# Config file for backend_indholdskanalen
cat > /vagrant/htdocs/backend_indholdskanalen/app/config/parameters.yml <<DELIM
parameters:
  database_driver: pdo_mysql
  database_host: 127.0.0.1
  database_port: null
  database_name: indholdskanalen
  database_user: root
  database_password: vagrant
  mailer_transport: smtp
  mailer_host: 127.0.0.1
  mailer_user: null
  mailer_password: null
  locale: en
  secret: ThisTokenIsNotSoSecretChangeIt
DELIM

php composer.phar install  > /dev/null 2>&1
php app/console doctrine:schema:update --force

# Setup super-user
echo "Setting up super-user:   admin/admin"
php app/console fos:user:create --super-admin admin test@etek.dk admin

# Elastic search
apt-get install openjdk-7-jre -y > /dev/null 2>&1
cd /root
wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.2.1.deb > /dev/null 2>&1
dpkg -i elasticsearch-1.2.1.deb > /dev/null 2>&1
rm elasticsearch-1.2.1.deb
update-rc.d elasticsearch defaults 95 10 > /dev/null 2>&1

# NodeJS middleware
echo "Installing nodejs"
apt-get install -y python-software-properties python > /dev/null 2>&1
add-apt-repository ppa:chris-lea/node.js -y > /dev/null 2>&1
sed -i 's/wheezy/lucid/g' /etc/apt/sources.list.d/chris-lea-node_js-wheezy.list
apt-get update > /dev/null 2>&1
apt-get install -y nodejs > /dev/null 2>&1

echo "Installing middleware requirements"
cd /vagrant/htdocs/search_node/
su vagrant -c "npm install > /dev/null 2>&1"

cat > /etc/init.d/middleware <<DELIM
#!/bin/sh

NODE_APP='app.js'
APP_DIR='/vagrant/htdocs/search_node';
PID_FILE=\$APP_DIR/app.pid
LOG_FILE=\$APP_DIR/app.log
NODE_EXEC=\`which node\`

###############
# chkconfig: - 58 74
# description: node-app is the script for starting a node app on boot.
### BEGIN INIT INFO
# Provides: node
# Required-Start:    \$network \$remote_fs \$local_fs
# Required-Stop:     \$network \$remote_fs \$local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: start and stop node
# Description: Node process for app
### END INIT INFO

start_app (){
    if [ -f \$PID_FILE ]
    then
        PID=\`cat $PID_FILE\`
        if ps -p \$PID > /dev/null; then
            echo "\$PID_FILE exists, process is already running"
            exit 1
        else
            rm \$PID_FILE
            start_app
        fi
    else
        echo "Starting node app..."
        if [ ! -d \$APP_DIR ]
        then
            sleep 30
        fi
        cd \$APP_DIR
        \$NODE_EXEC \$APP_DIR/\$NODE_APP  1>\$LOG_FILE 2>&1 &
        echo \$! > \$PID_FILE;
    fi
}

stop_app (){
    if [ ! -f \$PID_FILE ]
    then
        echo "\$PID_FILE does not exist, process is not running"
        exit 1
    else
        echo "Stopping \$APP_DIR/\$NODE_APP ..."
        echo "Killing \`cat \$PID_FILE\`"
        kill \`cat \$PID_FILE\`;
        rm -f \$PID_FILE;
        echo "Node stopped"
    fi
}

case "\$1" in
    start)
        start_app
    ;;

    stop)
        stop_app
    ;;

    restart)
        stop_app
        start_app
    ;;

    status)
        if [ -f \$PID_FILE ]
        then
            PID=\`cat \$PID_FILE\`
            if [ -z "\`ps ef | awk '{print \$1}' | grep "^\$PID\$"\`" ]
            then
                echo "Node app stopped but pid file exists"
            else
                echo "Node app running with pid \$PID"

            fi
        else
            echo "Node app stopped"
        fi
    ;;

    *)
        echo "Usage: \$0 {start|stop|restart|status}"
        exit 1
    ;;
esac
DELIM
chmod +x /etc/init.d/middleware
update-rc.d middleware defaults

# Start services
echo "Starting search_node"
service middleware start > /dev/null 2>&1

echo "Starting php5-fpm"
service php5-fpm start > /dev/null 2>&1

echo "Starting nginx"
service nginx restart > /dev/null 2>&1

echo "Starting mysql"
service mysql start > /dev/null 2>&1

echo "Starting ElasticSearch"
service elasticsearch restart

echo "Done"
