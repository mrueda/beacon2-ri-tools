# INSTALLATION

## Containerized

### Method 1: From Docker Hub

Download a docker image (latest version) from [Docker Hub](https://hub.docker.com/r/manuelrueda/beacon2-ri-tools) by executing:

    docker pull manuelrueda/beacon2-ri-tools:latest
    docker image tag manuelrueda/beacon2-ri-tools:latest cnag/beacon2-ri-tools:latest

See additional instructions below.

### Method 2: From Dockerfile

Download the `Dockerfile` from [Github](https://github.com/mrueda/beacon2-ri-tools/blob/main/Dockerfile) by typing:

    wget https://raw.githubusercontent.com/mrueda/beacon2-ri-tools/main/docker/Dockerfile

Then execute the following commands:

    # Docker Version 19.03 and Above (Supports buildx)
    docker buildx build -t cnag/beacon2-ri-tools:latest . # build the container (~1.1G)

    # Docker Version Older than 19.03 (Does Not Support buildx)
    docker build -t cnag/beacon2-ri-tools:latest . # build the container (~1.1G)

### Additional instructions for Methods 1 and 2

If MongoDB has not been installed alongside the `beacon2-ri-api` repository, it will be necessary to install it separately. MongoDB should be deployed outside the `beacon2-ri-tools` container.

Please download the `docker-compose.yml` file:

    wget https://raw.githubusercontent.com/mrueda/beacon2-ri-tools/main/docker/docker-compose.yml

And then execute:

    docker network create my-app-network
    docker-compose up -d

Mongo Express will be accessible via `http://localhost:8081` with default credentials `admin` and `pass`.

**IMPORTANT:** Docker containers are fully isolated. If you think you'll have to mount a volume to the container please read the section [Mounting Volumes](#mounting-volumes) before proceeding further.

**IMPORTANT (BIS):** If you plan to load data into MongoDB from inside `beacon2-ri-tools` container please read the section [Access MongoDB from inside the container](#access-mongodb-from-inside-the-container) before proceeding further.

    docker run -tid --name beacon2-ri-tools cnag/beacon2-ri-tools:latest # run the image detached
    docker ps  # list your containers, beacon2-ri-tools should be there
    docker exec -ti beacon2-ri-tools bash # connect to the container interactively

After the `docker exec` command, you will land at `/usr/share/beacon-ri/`, then execute:

    nohup beacon2-ri-tools/lib/BEACON/bin/deploy_external_tools.sh &

...that will inject the external tools and DBs into the image and modify the [configuration](#readme-md-setting-up-beacon) files. It will also run a test to check that the installation was successful. Note that running `deploy_external_tools.sh` will take some time (and disk space!!!). You can check the status by using:

    tail -f nohup.out

### Mounting volumes

It's simpler to mount a volume when starting a container than to add it to an existing one. If you need to mount a volume to the container please use the following syntax (`-v host:container`). Find an example below (note that you need to change the paths to match yours):

    docker run -tid --volume /media/mrueda/4TBT/workdir:/workdir --name beacon2-ri-tools cnag/beacon2-ri-tools:latest

Now you'll need to execute:

    docker exec -ti beacon2-ri-tools bash # connect to the container interactively

After the `docker exec` command, you will land at `/usr/share/beacon-ri/`, then execute:

    nohup beacon2-ri-tools/lib/BEACON/bin/deploy_external_tools.sh & # see above why

Then, you can run commands **inside the container**, like this:

    # We connect to the container interactively
    docker exec -ti beacon2-ri-tools bash
    # We go to the mounting point
    cd /workdir
    # We run the executable
    /usr/share/beacon-ri/beacon2-ri-tools/bin/beacon vcf -i example.vcf.gz -p param.in

Alternatively, you can run commands **from the host**, like this:

    # First we create an alias to simplify invocation
    alias beacon='docker exec -ti beacon2-ri-tools /usr/share/beacon-ri/beacon2-ri-tools/beacon'
    # Now we use a text editor to edit the file <params.in> to include the parameter 'projectdir'
    projectdir /workdir/my_fav_job_id
    # Finally we use the alias to run the command
    beacon vcf -i /workdir/my_vcf.gz -p /workdir/param.in

### Access MongoDB from inside the container

If you want to load data from **inside** the `beacon2-ri-tools` directly to `mongo` container, both containers have to be on the same network:

    docker run -tid --network=my-app-network --name beacon2-ri-tools cnag/beacon2-ri-tools:latest # change the network to match yours

### System requirements

- Ideally a Debian-based distribution (Ubuntu or Mint), but any other (e.g., CentOS, OpenSUSE) should do as well (untested).
- Docker and docker-compose
- Perl 5 (>= 5.10 core; installed by default in most Linux distributions). Check the version with `perl -v`
- 4GB of RAM (ideally 16GB).
- \>= 1 core (ideally i7 or Xeon).
- At least 200GB HDD.

The Perl itself does not need a lot of RAM (max load will reach 400MB), but external tools do (e.g., process `mongod` [MongoDB's daemon]).

### Common errors: Symptoms and treatment

  * Dockerfile:

          * DNS errors

            - Error: Temporary failure resolving 'foo'

              Solution: https://askubuntu.com/questions/91543/apt-get-update-fails-to-fetch-files-temporary-failure-resolving-error

## References

1. BCFtools
    Danecek P, Bonfield JK, et al. Twelve years of SAMtools and BCFtools. Gigascience (2021) 10(2):giab008 [link](https://pubmed.ncbi.nlm.nih.gov/33590861)

2.	SnpEff
    "A program for annotating and predicting the effects of single nucleotide polymorphisms, SnpEff: SNPs in the genome of Drosophila melanogaster strain w1118; iso-2; iso-3.", Cingolani P, Platts A, Wang le L, Coon M, Nguyen T, Wang L, Land SJ, Lu X, Ruden DM. Fly (Austin). 2012 Apr-Jun;6(2):80-92. PMID: 22728672.

3. SnpSift
    "Using Drosophila melanogaster as a model for genotoxic chemical mutational studies with a new program, SnpSift", Cingolani, P., et. al., Frontiers in Genetics, 3, 2012.

4.	dbNSFP v4
    1. Liu X, Jian X, and Boerwinkle E. 2011. dbNSFP: a lightweight database of human non-synonymous SNPs and their functional predictions. Human Mutation. 32:894-899.
    2. Liu X, Jian X, and Boerwinkle E. 2013. dbNSFP v2.0: A Database of Human Non-synonymous SNVs and Their Functional Predictions and Annotations. Human Mutation. 34:E2393-E2402.
    3. Liu X, Wu C, Li C, and Boerwinkle E. 2016. dbNSFP v3.0: A One-Stop Database of Functional Predictions and Annotations for Human Non-synonymous and Splice Site SNVs. Human Mutation. 37:235-241.
    4. Liu X, Li C, Mou C, Dong Y, and Tu Y. 2020. dbNSFP v4: a comprehensive database of transcript-specific functional predictions and annotations for human nonsynonymous and splice-site SNVs. Genome Medicine. 12:103.
