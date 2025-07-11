#!/bin/bash +x
# sudo ./setup.sh ${YOUR_ACCOUNT_ID} ${YOUR_LICENSE_KEY} ${YOUR_USER_KEY}
# e.g. sudo ./setup.sh 4103581 *****2NRAL NRAK-8*****
NEW_RELIC_ACCOUNT_ID=${1:-YOUR_ACCOUNT_ID}
NEW_RELIC_LICENSE_KEY=${2:-YOUR_LICENSE_KEY}
NEW_RELIC_USER_KEY=${3:-YOUR_USER_KEY}
NEW_RELIC_APP_NAME=${4:-DemoApp}

rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
dnf -y localinstall  https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm
dnf -y install mysql mysql-community-client mysql-community-server
yum -y update
yum -y install git perl perl-FindBin perl-open perl-YAML perl-File-HomeDir perl-Unicode-LineBreak zlib-devel gem sqlite-devel mysql-devel
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && source ~/.bashrc && nvm install 16
git version
git clone https://gitlab.gameday.nrkk.technology/demo/catalogue-db.git
systemctl start mysqld
sleep 5s;
mysql -uroot -p$(grep -oP '(?<=A temporary password is generated for root@localhost: ).*' /var/log/mysqld.log) --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'P4ssW0rd\!'"
mysql -uroot -pP4ssW0rd! -e "CREATE DATABASE socksdb;"
mysql -uroot -pP4ssW0rd! socksdb < catalogue-db/fat_header.sql
mysql -uroot -pP4ssW0rd! socksdb < catalogue-db/socks.sql
mysql -uroot -pP4ssW0rd! socksdb < catalogue-db/sock_tags.sql
systemctl restart mysqld

curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && sudo NEW_RELIC_API_KEY=${NEW_RELIC_USER_KEY} NEW_RELIC_ACCOUNT_ID=${NEW_RELIC_ACCOUNT_ID} /usr/local/bin/newrelic install -y
sudo yum -y install nri-mysql

echo 'integrations:
  - name: nri-mysql
    env:
      HOSTNAME: localhost
      PORT: 3306
      USERNAME: newrelic
      PASSWORD: P4ssW0rd!
      EXTENDED_METRICS: true
      EXTENDED_INNODB_METRICS: true
      EXTENDED_MYISAM_METRICS: true
      REMOTE_MONITORING: true
    interval: 30s
    labels:
      env: production
    inventory_source: config/mysql
' > /etc/newrelic-infra/integrations.d/mysql-config.yml

adduser appuser
su - appuser -c 'git clone https://github.com/sstephenson/rbenv.git ~/.rbenv'
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> /home/appuser/.bashrc;
echo 'eval "$(rbenv init -)"' >> /home/appuser/.bashrc;
su - appuser -c 'git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build' &&
su - appuser -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && source ~/.bashrc && nvm install 16 && yes | npm install --global yarn' &&
su - appuser -c 'mkdir -p ${PWD}/tmp' &&
su - appuser -c 'TMPDIR="${PWD}/tmp" rbenv install 3.0.2 -v' &&
su - appuser -c 'rbenv global 3.0.2' &&
su - appuser -c 'git clone https://gitlab.gameday.nrkk.technology/demo/catalogue.git' &&
su - appuser -c 'cp -r ~/catalogue/install ~/install' &&
su - appuser -c 'cd ~/catalogue && bundle update newrelic_rpm newrelic-infinite_tracing puma-newrelic' &&
su - appuser -c 'cd ~/catalogue && bundle install' &&
su - appuser -c 'cd ~/catalogue && bundle exec rails assets:precompile RAILS_ENV=production' &&
su - appuser -c 'cd ~/catalogue && DB_HOST=localhost NEW_RELIC_LICENSE_KEY='${NEW_RELIC_LICENSE_KEY}' NEW_RELIC_APP_NAME="'${NEW_RELIC_APP_NAME}'" NEW_RELIC_DISTRIBUTED_TRACING_ENABLED=true NEW_RELIC_CODE_LEVEL_METRICS_ENABLED=true NEW_RELIC_BROWSER_MONITORING_ATTRIBUTES_ENABLED=true RAILS_SERVE_STATIC_FILES=true RAILS_DB_USER=catalogue_user RAILS_DB_PASSWORD=P4ssW0rd! bundle exec rails server --environment production -d'

mkdir -p /demo/script &&
cd /demo/script
git clone https://gitlab.gameday.nrkk.technology/demo/catalogue-test.git &&
wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm &&
yum install -y ./google-chrome-stable_current_x86_64.rpm &&
cd /demo/script/catalogue-test &&
npm install -y chromedriver --chromedriver-force-download &&
npm install

echo '#!/bin/bash -x
export TAG=${1:-master};
su - appuser -c '"'"'source ~/.bashrc;
cd /home/appuser/catalogue;
git checkout '"'"'${TAG}'"'"';
bundle update newrelic_rpm newrelic-infinite_tracing puma-newrelic;
bundle install;
bundle exec rails assets:precompile RAILS_ENV=production;
kill $(cat /home/appuser/catalogue/tmp/pids/server.pid);'"'"'
systemctl restart mysqld;
rm -r /tmp/execjs*
rm -r /tmp/.org.chromium.Chromium.*
su - appuser -c '"'"'source ~/.bashrc;
cd /home/appuser/catalogue;
export DB_HOST=localhost;
export NEW_RELIC_LICENSE_KEY='${NEW_RELIC_LICENSE_KEY}';
export NEW_RELIC_APP_NAME='${NEW_RELIC_APP_NAME}';
export NEW_RELIC_DISTRIBUTED_TRACING_ENABLED=true;
export NEW_RELIC_CODE_LEVEL_METRICS_ENABLED=true;
export NEW_RELIC_BROWSER_MONITORING_ATTRIBUTES_ENABLED=true;
export RAILS_SERVE_STATIC_FILES=true;
export RAILS_DB_USER=catalogue_user;
export RAILS_DB_PASSWORD='"'"'P4ssW0rd!'"'"';
export NEW_RELIC_RULES_IGNORE_URL_REGEXES="^/assets,^/packs"
bundle exec rails server --environment production -d;
cd /home/appuser/install;
bash -x ./change_tracking.sh '${NEW_RELIC_ACCOUNT_ID}' '${NEW_RELIC_USER_KEY}' '${NEW_RELIC_APP_NAME}' '"'"'${TAG}'   > /demo/script/restart_app.sh

chmod +x /demo/script/restart_app.sh
echo '[Unit]
Description=TestCron

[Service]
Type=oneshot
ExecStart=/demo/script/catalogue-test/run.sh

[Install]
WantedBy=multi-user.target' >  /etc/systemd/system/test.service

echo '[Unit]
Description=TestCron

[Timer]
OnCalendar=minutely
Persistent=true

[Install]
WantedBy=timers.target' > /etc/systemd/system/test.timer

sudo systemctl enable test.service
sudo systemctl enable test.timer
sudo systemctl start test.timer

echo '[Unit]
Description=App1Cron

[Service]
Type=oneshot
ExecStart=/demo/script/restart_app.sh v0.2.2

[Install]
WantedBy=multi-user.target' >  /etc/systemd/system/app1.service

echo '[Unit]
Description=App1Cron

[Timer]
OnCalendar=*-*-* 0/2:00:00
Persistent=true

[Install]
WantedBy=timers.target' > /etc/systemd/system/app1.timer

sudo systemctl enable app1.service
sudo systemctl enable app1.timer
sudo systemctl start app1.timer


echo '[Unit]
Description=App1Cron

[Service]
Type=oneshot
ExecStart=/demo/script/restart_app.sh v0.2.59

[Install]
WantedBy=multi-user.target' >  /etc/systemd/system/app2.service

echo '[Unit]
Description=App1Cron

[Timer]
OnCalendar=*-*-* 0/2:20:00
Persistent=true

[Install]
WantedBy=timers.target' > /etc/systemd/system/app2.timer

sudo systemctl enable app2.service
sudo systemctl enable app2.timer
sudo systemctl start app2.timer

echo '[Unit]
Description=App1Cron

[Service]
Type=oneshot
ExecStart=/demo/script/restart_app.sh v0.2.112

[Install]
WantedBy=multi-user.target' >  /etc/systemd/system/app3.service

echo '[Unit]
Description=App1Cron

[Timer]
OnCalendar=*-*-* 0/2:45:00
Persistent=true

[Install]
WantedBy=timers.target' > /etc/systemd/system/app3.timer

sudo systemctl enable app3.service
sudo systemctl enable app3.timer
sudo systemctl start app3.timer

echo '[Unit]
Description=App1Cron

[Service]
Type=oneshot
ExecStart=/demo/script/restart_app.sh v0.2.201

[Install]
WantedBy=multi-user.target' >  /etc/systemd/system/app4.service

echo '[Unit]
Description=App1Cron

[Timer]
OnCalendar=*-*-* 1/2:05:00
Persistent=true

[Install]
WantedBy=timers.target' > /etc/systemd/system/app4.timer

sudo systemctl enable app4.service
sudo systemctl enable app4.timer
sudo systemctl start app4.timer

echo '[Unit]
Description=App1Cron

[Service]
Type=oneshot
ExecStart=/demo/script/restart_app.sh v0.3.11

[Install]
WantedBy=multi-user.target' >  /etc/systemd/system/app5.service

echo '[Unit]
Description=App1Cron

[Timer]
OnCalendar=*-*-* 1/2:30:00
Persistent=true

[Install]
WantedBy=timers.target' > /etc/systemd/system/app5.timer

sudo systemctl enable app5.service
sudo systemctl enable app5.timer
sudo systemctl start app5.timer

echo '[Unit]
Description=App1Cron

[Service]
Type=oneshot
ExecStart=/demo/script/restart_app.sh v0.3.101

[Install]
WantedBy=multi-user.target' >  /etc/systemd/system/app6.service

echo '[Unit]
Description=App1Cron

[Timer]
OnCalendar=*-*-* 1/2:50:00
Persistent=true

[Install]
WantedBy=timers.target' > /etc/systemd/system/app6.timer

sudo systemctl enable app6.service
sudo systemctl enable app6.timer
sudo systemctl start app6.timer
systemctl restart mysqld

