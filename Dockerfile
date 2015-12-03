FROM ubuntu:14.04.3
MAINTAINER Meng Wang <wangm0855@gmail.com>
LABEL Description="UCSC Genome Browser"

#
# Install dependencies
#
RUN apt-get update && apt-get install -y git build-essential \
    apache2 mysql-server \
    mysql-client-5.5 mysql-client-core-5.5 \
    libpng12-dev libssl-dev openssl libmysqlclient-dev && \
    apt-get clean

#
# Get browser source codes
#
RUN git clone git://genome-source.cse.ucsc.edu/kent.git
RUN cd kent && git checkout -t -b beta origin/beta

ENV MACHTYPE x86_64
RUN mkdir -p ~/bin/${MACHTYPE}
RUN rm /var/www/html/index.html && \
    rsync -avzP rsync://hgdownload.cse.ucsc.edu/htdocs/ /var/www/html/

#
# Build
#
RUN cd /kent/src && make libs

RUN mkdir -p /var/www/html/cgi-bin && mkdir -p /usr/local/apache && \
    ln -s /var/www/html/cgi-bin /usr/local/apache/cgi-bin

RUN cd /kent/src/hg && make compile && make install DESTDIR=/var/www/html \
                                                    CGI_BIN=/cgi-bin \
                                                    DOCUMENTROOT=/var/www/html

RUN rm -r /kent && mkdir -p /var/www/trash && \
    ln -s /var/www/html /usr/local/apache/htdocs

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
    } > /var/www/html/cgi-bin/hg.conf


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
        echo 'ScriptAlias /cgi-bin/ /var/www/html/cgi-bin/'; \
        echo '<Directory "/var/www/html/cgi-bin">'; \
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
