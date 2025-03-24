# Containerized Installation

## Downloading Required Databases and Software

First, we need to download the necessary databases and software. In contrast to `beacon2-ri-tools`, where **the data was bundled inside the container to provide a zero-configuration experience for users, we now store the data externally**. This change improves data persistence and allows software updates without requiring a full re-download of all data.

### Step 1: Download Required Files

Navigate to a directory with at least **150GB** of available space and run:

```bash
wget https://raw.githubusercontent.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/main/scripts/01_download_external_data.py
```

Then execute the script:

```bash
python3 01_download_external_data.py
```

> **Note:** Google Drive can sometimes restrict downloads. If you encounter an error, use the provided error URL in a browser to retrieve the file manually.

### Step 2: Verify Download Integrity

Run a checksum to ensure the files were not corrupted:

```bash
md5sum -c data.tar.gz.md5
```

### Step 3: Reassemble Split Files

The downloaded data is split into parts. Reassemble it into a single tar archive (**~130GB required**):

```bash
cat data.tar.gz.part-?? > data.tar.gz
```

Once the files are successfully merged, delete the split parts to free up space:

```bash
rm data.tar.gz.part-??
```

### Step 4: Extract Data

Extract the tar archive:

```bash
tar -xzvf data.tar.gz
```

### Step 5: Configure Path in SnpEff

**In the downloaded data:**  

Update the `data.dir` variable in **SnpEff** config file:

```bash
/path/to/downloaded/data/soft/NGSutils/snpEff_v5.0/snpEff.config
```

Ensure it points to the correct location of your downloaded data.

---

## Method 1: Installing from Docker Hub

Pull the latest Docker image from [Docker Hub](https://hub.docker.com/r/manuelrueda/beacon2-cbi-tools):

```bash
docker pull manuelrueda/beacon2-cbi-tools:latest
docker image tag manuelrueda/beacon2-cbi-tools:latest cnag/beacon2-cbi-tools:latest
```

---

## Method 2: Installing from Dockerfile

Download the `Dockerfile` from [GitHub](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/blob/main/Dockerfile):

```bash
wget https://raw.githubusercontent.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/main/docker/Dockerfile
```

Then build the container:

- **For Docker version 19.03 and above (supports buildx):**

  ```bash
  docker buildx build -t cnag/beacon2-cbi-tools:latest .
  ```

- **For Docker versions older than 19.03 (no buildx support):**

  ```bash
  docker build -t cnag/beacon2-cbi-tools:latest .
  ```

---

## Running the Container

```bash
# Please update '/media/mrueda/4TBB/beacon2-cbi-tools-data' with the location of your data. Do not touch the mounting point ':/beacon2-cbi-tools-data'
docker run -tid --volume /media/mrueda/4TBB/beacon2-cbi-tools-data:/beacon2-cbi-tools-data --name beacon2-cbi-tools cnag/beacon2-cbi-tools:latest

# To check the containers
docker ps  # list your containers, beacon2-cbi-tools should be there

# Connect to the container interactively
docker exec -ti beacon2-cbi-tools bash
```

Alternatively, you can run commands **from the host**, like this:

First, create an alias to simplify invocation:

```bash
alias bff-tools='docker exec -ti beacon2-cbi-tools /usr/share/beacon2-cbi-tools/bin/bff-tools'
```

Then run:

```bash
bff-tools
```

## Testing the deployment

Go to directory `test` and execute:

```bash
bash 02_test_deployment.sh
```

---

## MongoDB Installation (Optional: Only for `load/full` modes)

If you don't already have MongoDB installed in a separate container, follow these steps.

### Step 1: Download `docker-compose.yml`

```bash
wget https://raw.githubusercontent.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/main/docker/docker-compose.yml
```

### Step 2: Start MongoDB

```bash
docker network create my-app-network
docker compose up -d
```

Mongo Express will be accessible at `http://localhost:8081` with default credentials `admin` and `pass`.

> **IMPORTANT:** If you plan to load data into MongoDB from inside the `beacon2-cbi-tools` container, read the section [Access MongoDB from inside the container](#access-mongodb-from-inside-the-container) before proceeding.

### Access MongoDB from Inside the Container

If you want to load data from **inside** the `beacon2-cbi-tools` container directly into the `mongo` container, both containers must be on the same network.

#### **Option A**: Before running the container

```bash
docker run -tid --network=my-app-network --volume /media/mrueda/4TBB/beacon2-cbi-tools-data:/beacon2-cbi-tools-data --name beacon2-cbi-tools cnag/beacon2-cbi-tools:latest
```

#### **Option B**: After running the container

```bash
docker network connect my-app-network beacon2-cbi-tools
```

---

## System requirements

- OS/ARCH supported: **linux/amd64** and **linux/arm64)**.
- Ideally a Debian-based distribution (Ubuntu or Mint), but any other (e.g., CentOS, OpenSUSE) should do as well (untested).
- Docker and docker compose
- Perl 5 (>= 5.10 core; installed by default in most Linux distributions). Check the version with perl -v
- 4GB of RAM (ideally 16GB).
- \>= 1 core (ideally i7 or Xeon).
- At least 200GB HDD.

Perl itself does not require much RAM (max load ~400MB), but external tools (e.g., `mongod` [MongoDB's daemon]) do.

---

## Common errors: Symptoms and treatment

  * Dockerfile:

          * DNS errors

            - Error: Temporary failure resolving 'foo'

              Solution: https://askubuntu.com/questions/91543/apt-get-update-fails-to-fetch-files-temporary-failure-resolving-error
---

## References

1. **BCFtools**  
   Danecek P, Bonfield JK, et al. Twelve years of SAMtools and BCFtools. *Gigascience* (2021) 10(2):giab008. [Read more](https://pubmed.ncbi.nlm.nih.gov/33590861).

2. **SnpEff**  
   Cingolani P, Platts A, Wang le L, Coon M, et al. *Fly (Austin)*. 2012 Apr-Jun;6(2):80-92. PMID: 22728672.

3. **SnpSift**  
   Cingolani, P., et. al. *Frontiers in Genetics*, 3, 2012.

4. **dbNSFP v4**  
   - Liu X, Jian X, and Boerwinkle E. *Human Mutation*. 32:894-899.
   - Liu X, Wu C, Li C, and Boerwinkle E. *Human Mutation*. 37:235-241.
   - Liu X, Li C, Mou C, Dong Y, and Tu Y. *Genome Medicine*. 12:103.
