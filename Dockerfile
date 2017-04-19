FROM ubuntu:16.04
MAINTAINER Meng Wang <wangm0855@gmail.com>
LABEL Description="UCSC Genome Browser"

#
# Install dependencies
#
RUN apt-get update && apt-get install -y git build-essential \
    curl apache2 mysql-server \
    mysql-client-5.7 mysql-client-core-5.7 \
    libpng12-dev libssl-dev openssl libmysqlclient-dev && \
    apt-get clean

#
# Get browser source codes
#
ENV MACHTYPE x86_64
RUN mkdir -p ~/bin/${MACHTYPE}
RUN rm /var/www/html/index.html && mkdir /var/www/trash && \
    rsync -avzP rsync://hgdownload.cse.ucsc.edu/htdocs/ /var/www/html/

RUN mkdir /var/www/cgi-bin && \
    rsync -avP rsync://hgdownload.soe.ucsc.edu/cgi-bin/ /var/www/cgi-bin/


#
# Config db connection
#
RUN { \
        echo 'db.host=gbdb'; \
        echo 'db.user=admin'; \
        echo 'db.password=admin'; \
        echo 'db.trackDb=trackDb'; \
        echo 'defaultGenome=Human'; \
        echo 'central.db=hgcentral'; \
        echo 'central.host=gbdb'; \
        echo 'central.user=admin'; \
        echo 'central.password=admin'; \
        echo 'central.domain='; \
        echo 'backupcentral.db=hgcentral'; \
        echo 'backupcentral.host=gbdb'; \
        echo 'backupcentral.user=admin'; \
        echo 'backupcentral.password=admin'; \
        echo 'backupcentral.domain='; \
    } > /var/www/cgi-bin/hg.conf


#
# Config daliy clean
#
RUN { \
        echo '#!/bin/bash'; \
        echo 'find /var/www/trash/ \! \( -regex "/var/www/trash/ct/.*" \
              -or -regex "/var/www/trash/hgSs/.*" \) -type f -amin +5040 -exec rm -f {} \;'; \
        echo 'find /var/www/trash/    \( -regex "/var/www/trash/ct/.*" \
              -or -regex "/var/www/trash/hgSs/.*" \) -type f -amin +10080 -exec rm -f {} \;'; \
    } > /etc/cron.daily/genomebrowser

RUN chmod +x /etc/cron.daily/genomebrowser

#
# Config apache
#
RUN { \
        echo 'XBitHack on'; \
    } >> /etc/apache2/apache2.conf

RUN sed -i 's/<\/VirtualHost>//' /etc/apache2/sites-enabled/000-default.conf && \
    { \
        echo '<Directory /var/www/html>'; \
        echo '    AllowOverride AuthConfig'; \
        echo '    Options +Includes'; \
        echo '</Directory>'; \
        echo 'ScriptAlias /cgi-bin/ /var/www/cgi-bin/'; \
        echo '<Directory "/var/www/cgi-bin">'; \
        echo '    AllowOverride None'; \
        echo '    Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch'; \
        echo '    SetHandler cgi-script'; \
        echo '    Require all granted'; \
        echo '</Directory>'; \
        echo '</VirtualHost>'; \
    } >> /etc/apache2/sites-enabled/000-default.conf

RUN ln -s /etc/apache2/mods-available/include.load /etc/apache2/mods-enabled/ && \
    ln -s /etc/apache2/mods-available/cgi.load /etc/apache2/mods-enabled/


#
# Get gbdb data from UCSC
#
RUN mkdir -p /gbdb/hg38 && mkdir -p /gbdb/visiGene && \
    rsync -avzP --delete --max-delete=20 rsync://hgdownload.cse.ucsc.edu/gbdb/hg38/hg38.2bit /gbdb/hg38/hg38.2bit

RUN chown -R www-data.www-data /var/www /gbdb


#
# Start apache
#
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

EXPOSE 80 443

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
