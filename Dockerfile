FROM ubuntu:18.04
LABEL Description="UCSC Genome Browser"
LABEL Maintainer="Meng Wang <wangm0855@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive

#
# Install dependencies
#
RUN apt-get update && apt-get install -y git build-essential rsync \
    apache2 mysql-client-5.7 mysql-client-core-5.7 libcurl4 \
    libpng-dev libssl-dev openssl libmysqlclient-dev python-mysqldb \
    ghostscript imagemagick wget r-base-core curl gsfonts && \
    apt-get clean

#
# Get browser source codes
#
ENV MACHTYPE x86_64
RUN mkdir -p ~/bin/${MACHTYPE} && \
    rsync -avP rsync://hgdownload.soe.ucsc.edu/genome/admin/exe/linux.x86_64/ ~/bin/${MACHTYPE}/ && \
    cd && wget https://raw.githubusercontent.com/ucscGenomeBrowser/kent/master/src/hg/lib/trackDb.sql

RUN rm /var/www/html/index.html && mkdir /var/www/trash && \
    mkdir /usr/local/apache && ln -s /var/www/html /usr/local/apache/htdocs && \
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
        echo 'db.grp=grp'; \
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
        echo 'freeType=on'; \
        echo 'freeTypeDir=/usr/share/fonts/type1/gsfonts'; \
    } > /var/www/cgi-bin/hg.conf && \
    ln /var/www/cgi-bin/hg.conf ~/.hg.conf && \
    chmod 600 ~/.hg.conf


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
RUN sed -i 's/<\/VirtualHost>//' /etc/apache2/sites-enabled/000-default.conf && \
    { \
        echo 'XBitHack on'; \
        echo ''; \
        echo '<Directory /var/www/html>'; \
        echo '    Options +Includes'; \
        echo '    SSILegacyExprParser on'; \
        echo '</Directory>'; \
        echo ''; \
        echo 'ScriptAlias /cgi-bin/ /var/www/cgi-bin/'; \
        echo '<Directory "/var/www/cgi-bin">'; \
        echo '    AllowOverride None'; \
        echo '    Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch'; \
        echo '    SetHandler cgi-script'; \
        echo '    Require all granted'; \
        echo '</Directory>'; \
        echo ''; \
        echo '<Directory /var/www/html/trash>'; \
        echo '    Options MultiViews'; \
        echo '    AllowOverride None'; \
        echo '    Order allow,deny'; \
        echo '    Allow from all'; \
        echo '</Directory>'; \
        echo ''; \
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
