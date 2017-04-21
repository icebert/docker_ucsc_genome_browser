### UCSC Genome Browser Docker Image

A minimal UCSC Genome Browser mirror.

http://genome.ucsc.edu/

### License
This is a Dockerized version of the UCSC Genome Browser source code. The license is the same as the UCSC Genome Browser itself. The source code and executables are freely available for academic, nonprofit and personal use. Commercial use requires purchase of a license with setup fee and annual payment. See https://genome-store.ucsc.edu/.

### Download
```shell
docker pull icebert/ucsc_genome_browser

docker pull icebert/ucsc_genome_browser_db
```

### Demo Run
```shell
docker run -d --name gbdb -p 3338:3306 icebert/ucsc_genome_browser_db

docker run -d --link gbdb:gbdb -p 8038:80 icebert/ucsc_genome_browser
```

### Run with local data files
Assume local data is going to be stored in /my/data/path

First copy the basic database files into /my/data/path from docker

```shell
docker run -d --name gbdb -p 3338:3306 icebert/ucsc_genome_browser_db

cd /my/data/path && docker cp gbdb:/data ./ && mv data/* ./ && rm -rf data hg38

docker stop gbdb
```

Then put database files into /my/data/path. For example, mirror all the tracks of hg38 from ucsc genome browser

```shell
rsync -avP --delete --max-delete=20 rsync://hgdownload.soe.ucsc.edu/mysql/hg38 /my/data/path/
```

Finally start the database server and genome browser server

```shell
docker run -d --name gbdb -p 3338:3306 -v /my/data/path:/data icebert/ucsc_genome_browser_db

docker run -d --link gbdb:gbdb -p 8038:80 icebert/ucsc_genome_browser
```

### MySQL Access
The mysql server listens on port 3338. The default username for mysql is 'admin' with password 'admin'.

```shell
mysql -h 127.0.0.1 -P 3338 -u admin -p
```

