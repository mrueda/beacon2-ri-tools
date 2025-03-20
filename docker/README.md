# Containerized Installation

## Downloading Required Databases and Software

First, we need to download the necessary databases and software. Unlike `beacon-cbi-tools`, where the data was inside the container, we now store the data externally. This improves data persistence and allows software updates without needing to re-download everything.

### Step 1: Download Required Files

Navigate to a directory with at least **150GB** of available space and run:

```bash
wget https://raw.githubusercontent.com/mrueda/beacon2-cbi-tools/main/scripts/01_foo_bar.py
```

Then execute the script:

```bash
python3 01_foo_bar.py
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

### Step 5: Configure Paths

1. **In the downloaded data:**  
   Update the `data.dir` variable in:

   ```bash
   /path/to/downloaded/data/soft/NGSutils/snpEff_v5.0/snpEff.config
   ```

2. **In the `beacon2-cbi-tools` repository:**  
   Update `{base}` in:

   ```bash
   bin/config.yaml
   ```

   Ensure it points to the correct location of your downloaded data.

---

## Method 1: Installing from Docker Hub

Pull the latest Docker image from [Docker Hub](https://hub.docker.com/r/manuelrueda/beacon-cbi-tools):

```bash
docker pull manuelrueda/beacon-cbi-tools:latest
docker image tag manuelrueda/beacon-cbi-tools:latest cnag/beacon-cbi-tools:latest
```

---

## Method 2: Installing from Dockerfile

Download the `Dockerfile` from [GitHub](https://github.com/mrueda/beacon-cbi-tools/blob/main/Dockerfile):

```bash
wget https://raw.githubusercontent.com/mrueda/beacon2-cbi-tools/main/docker/Dockerfile
```

Then build the container:

- **For Docker version 19.03 and above (supports buildx):**

  ```bash
  docker buildx build -t cnag/beacon-cbi-tools:latest .
  ```

- **For Docker versions older than 19.03 (no buildx support):**

  ```bash
  docker build -t cnag/beacon-cbi-tools:latest .
  ```

---

## Running the Container

```bash
docker run -tid --volume /your/path/to/beacon2-cbi-tools-data:/beacon2-cbi-tools-data --name beacon-cbi-tools cnag/beacon-cbi-tools:latest
docker ps  # list your containers, beacon-cbi-tools should be there
docker exec -ti beacon-cbi-tools bash  # connect to the container interactively
```

Alternatively, you can run commands **from the host**, like this:

First, create an alias to simplify invocation:

```bash
alias beacon='docker exec -ti beacon-cbi-tools /usr/share/beacon-cbi-tools/bin/beacon'
```

Then run:

```bash
beacon
```

---

## MongoDB Installation (Optional: Only for `mongodb/full` modes)

If you don't already have MongoDB installed in a separate container, follow these steps.

### Step 1: Download `docker-compose.yml`

```bash
wget https://raw.githubusercontent.com/mrueda/beacon2-cbi-tools/main/docker/docker-compose.yml
```

### Step 2: Start MongoDB

```bash
docker network create my-app-network
docker compose up -d
```

Mongo Express will be accessible at `http://localhost:8081` with default credentials `admin` and `pass`.

> **IMPORTANT:** If you plan to load data into MongoDB from inside the `beacon2-cbi-tools` container, read the section [Access MongoDB from inside the container](#access-mongodb-from-inside-the-container) before proceeding.

### Access MongoDB from Inside the Container

If you want to load data from **inside** the `beacon-cbi-tools` container directly into the `mongo` container, both containers must be on the same network.

#### **Option A**: Before running the container

```bash
docker run -tid --network=my-app-network --name beacon-cbi-tools cnag/beacon-cbi-tools:latest
```

#### **Option B**: After running the container

```bash
docker network connect my-app-network beacon2_ri-tools
```

---

## System requirements

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
