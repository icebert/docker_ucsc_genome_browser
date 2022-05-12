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
The dockers contain no data. Please download the data of the species you are interested in as follows.

Assume local data is going to be stored in /my/data/path/gbdb and the track database is going to be stored in /my/data/path/database

First copy the basic database files from docker into local /my/data/path/database

```shell
docker run -d --name gbdb -p 3338:3306 icebert/ucsc_genome_browser_db

cd /my/data/path/database && docker cp gbdb:/data ./ && mv data/* ./ && rm -rf data

docker stop gbdb
```

Next download database files from UCSC into /my/data/path/database. For example, mirror all the tracks of hg38 from ucsc genome browser.
For mouse (or other species), just replace hg38 with mm10 (or other species name).

```shell
rm -rf /my/data/path/database/hg38

rsync -avP --delete --max-delete=20 rsync://hgdownload.soe.ucsc.edu/mysql/hg38 /my/data/path/database/
```

Then download basic data files from UCSC into /my/data/path/gbdb

```shell
mkdir /my/data/path/gbdb/visiGene

rsync -avzP --delete --max-delete=20 rsync://hgdownload.cse.ucsc.edu/gbdb/hg38 /my/data/path/gbdb/
```


Finally start the database server and genome browser server

```shell
docker run -d --name gbdb -p 3338:3306 -v /my/data/path/database:/data icebert/ucsc_genome_browser_db

docker run -d --link gbdb:gbdb -p 8038:80 -v /my/data/path/gbdb:/gbdb icebert/ucsc_genome_browser
```

The browser would be available at port 8038.


### MySQL Access
The mysql server listens on port 3338. The default username for mysql is 'admin' with password 'admin'.

```shell
mysql -h 127.0.0.1 -P 3338 -u admin -p
```


### Add tracks
For adding custom tracks to the genome browser, [this post](https://bergmanlab.uga.edu/running-a-ucsc-genome-browser-mirror-iii-loading-custom-data/) and [this page](https://genome.ucsc.edu/goldenpath/help/mirrorManual.html#adding-your-own-track-groups-to-the-browser) describe the detailed steps. Briefly,

1. Add a new track group in `grp` table (optional)

2. add track description using `~/bin/x86_64/hgTrackDb` with `trackDb.ra` file as input

3. add track with loader program based on the track type. For example, use `~/bin/x86_64/hgLoadBed` to load bed files and use `~/bin/x86_64/hgBbiDbLink` to load bigWig files.

