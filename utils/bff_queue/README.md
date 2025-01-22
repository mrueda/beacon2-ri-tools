# README

This is the README file for the `bff-queue` utility.

## Background 

It's very likely that you will need to process many VCF files using the **B2RI** data ingestion tools.

Because processing these files takes time, you may consider some form of _parallel processing_. It's also worth noting that since the jobs are independent, you can **split VCFs per chromosome** to further speed up the calculation.

Depending on your infrastructure, you may have access to a **High-Performance Computing (HPC)** system at your institution (e.g., [PBS](https://en.wikipedia.org/wiki/Portable_Batch_System)). If you have access to such a system and it meets your security requirements, you don't need to read further.

However, in most cases, **B2RI** will be installed on a _workstation_ or a _server_ that likely does not have access to an HPC system.

Here, we provide a few solutions to speed up the calculation process:

## How to Run Multiple Jobs on Your Workstation/Server

There are several options to accomplish this:

1. **Run the jobs sequentially**
 
    - For example, by using a `for` loop in `bash`. 

2. **Run the jobs in parallel**

    - Using `xargs` or `parallel`.
    - Using the included utility, `bff-queue`.

## GNU-Parallel

[GNU-Parallel](https://www.gnu.org/software/parallel) is a shell tool that enables parallel execution of jobs using one or more computers. 

In the example below, we allow `parallel` to process all 24 VCF files (one per chromosome). `parallel` will distribute one job per available core and manage the workload as a _lightweight_ queue system.

```bash
parallel "./beacon vcf -n 1 -i chr{}.vcf.gz  > chr{}.log 2>&1" ::: {1..22} X Y
```

**GNU-Parallel** is an excellent tool, and I highly recommend it.

## BFF-Queue (Included Utility)

All the previous options are useful, but let's take things a step further.

We'll be using an **open-source** queue system and task manager based on **Mojolicious**, called [Minion](https://metacpan.org/dist/Minion).

![Minion](https://raw.githubusercontent.com/mojolicious/minion/main/examples/admin.png)

[Minion](https://metacpan.org/dist/Minion) is a **lightweight** queue system written in Perl, offering functionality similar to other popular solutions in different languages, such as Python's [Celery](https://docs.celeryproject.org/en/stable/getting-started/introduction.html) and [RQ](https://python-rq.org/docs/monitoring), or JavaScript's [Bull](https://optimalbits.github.io/bull). However, Minion stands out due to its **smaller footprint** and simpler setup compared to these alternatives, making it an efficient choice for applications where minimal overhead is crucial.

Like other queue systems, Minion relies on a _back-end_ to manage task data, typically using SQL or NoSQL databases, or [Redis](https://redis.io).

Alright, no more talking—let's get started!

### Installation

To simplify things, we will use [SQLite](https://www.sqlite.org/index.html) as a _back-end_. However, Minion supports other back-ends such as PostgreSQL, MongoDB, Redis, and more.

```bash
cpanm Minion Minion::Backend::SQLite
```

### Usage

We go the to the app directory:

```bash
cd bff_queue
```

First, start a worker:

```bash
./bff-queue minion worker -j 8 -q beacon # Use 8 cores simultaneously and queue <beacon>
```

In another terminal, start the UI with:

```bash
./minion_ui.pl daemon # You will be able to access it at http://localhost:3000
```

Yes, the UI is **phenomenal**.

Alternatively, in production, you can run the UI using:

```bash
hypnotoad minion_ui.pl # You will be able to access it at http://localhost:8080
```

**Note:** For more details about Minion UI deployment, please refer to [this guide](https://docs.mojolicious.org/Mojolicious/Guides/Cookbook#DEPLOYMENT).

Next, navigate to the directory where your VCF files are located:

```bash
cd my_vcf_file_directory
```

Then, submit a job from there:

(Please update the paths to match your environment)

```bash
/usr/share/beacon2-ri/beacon2-ri-tools/utils/bff_queue/bff-queue minion job -q beacon -e beacon_task -a '["cd /home/mrueda/beacon ; /usr/share/beacon2-ri/beacon2-ri-tools/bin/beacon vcf -i test_1000G.vcf.gz -p param.yaml -n 1 > beacon.log 2>&1"]'
```

**Note:** If you encounter any issues, simply delete the `minion.db` file in the `bff_queue` directory.

Enjoy!

— Manu

### Credits

A big thanks to all the [contributors](https://github.com/mojolicious/minion) of **Minion**, and a special shout-out to [Sebastian Riedel](https://github.com/kraih).
