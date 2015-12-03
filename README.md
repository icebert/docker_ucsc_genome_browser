### UCSC Genome Browser Docker Image

A minimal UCSC Genome Browser mirror.
http://genome.ucsc.edu/

### Download
docker pull icebert/ucsc_genome_browser
docker pull icebert/ucsc_genome_browser_db

### Demo Run
docker run -d --name gbdb -p 3338:3306 icebert/ucsc_genome_browser_db
docker run -d --link gbdb -p 8038:80 icebert/ucsc_genome_browser

### Run with local data files
docker run -d --name gbdb -p 3338:3306 -v /my/data/path:/data icebert/ucsc_genome_browser_db
docker run -d --link gbdb -p 8038:80 icebert/ucsc_genome_browser


