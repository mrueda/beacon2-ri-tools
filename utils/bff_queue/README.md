# README

This is the README file for `bff-queue` utility.

## Background 

It's very likely that you will need to process many VCF files with the **B2RI** data ingestion tools.

Because processing these files takes time, it is also likely that you will have in mind some sort of _parallel processing_ for the files. It's also worth noting that because the jobs are independent, you can **split VCFs per chromosome** to further speed up the calculation.

Depending on your logistics, you may have some sort of **HPC** at your institution (e.g., [PBS](https://en.wikipedia.org/wiki/Portable_Batch_System)). If you have access to it and it's secure enough for your needs then you don't need to keep reading.

Generally, **B2RI** is going to be installed in a _workstation_ or a _server_ which probably will not have access to HPC at all.

Here we provide a few solutions to speed up the calculation time:

## How to run multiple jobs in your workstation/server

Well, we have some options here:

1. Run the jobs in serial
 
    - For instance, by using a `for` loop in `bash`. 

2. Run the jobs in parallel

    - Use `xargs` or `parallel`.
    - Use the included utility `bff-queue`.

## GNU-Parallel

[GNU-Parallel](https://www.gnu.org/software/parallel) is a shell tool for executing jobs in parallel using one or more computers. 

In the exmple below we are going to let `parallel` to process all 24 VCFs (one per chromosome). `parallel` will send 1 job to each available core and take care of the rest as if it was a _light_ queue system.

    $ parallel "./beacon vcf -n 1 -i chr{}.vcf.gz  > chr{}.log 2>&1" ::: {1..22} X Y

**GNU-Parallel** is awesome and I totally recommend it. 

## BFF-Queue (included utility)

All the previous options are fine, but now we're going to go a bit further.

We're going to be using an _open source_ queue system/task manager based on **Mojolicius** [Minion](https://metacpan.org/dist/Minion).

![Minion](https://raw.githubusercontent.com/mojolicious/minion/main/examples/admin.png)

[Minion](https://metacpan.org/dist/Minion) is a queue system written in Perl, similar to those existing for other languages (Python's [Celery](https://docs.celeryproject.org/en/stable/getting-started/introduction.html), [RQ](https://python-rq.org/docs/monitoring) or JavaScript's [Bull](https://optimalbits.github.io/bull)).

All of these queue systems use some sort of _back-end_ to keep track of the data, usually being SQL or non-SQL databases, or [Redis](https://redis.io).

Ok, no more talking. Let's get started:

### Installation

Here, to simplify things we will be using [SQLite](https://www.sqlite.org/index.html) as a _back-end_. Note, however, that Minion accepts many other back-ends (PosgreSQL, MongoDB, Redis, etc).

    $ cpanm Minion Minion::Backend::SQLite

### Usage

The first thing is to start a worker:

    $ ./bff_queue/bff-queue minion worker -j 8 -q beacon # To use 8 cores simultaneusly and queue <beacon>

In another terminal, we'll start the UI with:

    $ ./bff_queue/minion_ui.pl daemon # You will able to access it at http://localhost:3000

Yes, the UI is **phenomenal**.

Alternatively (in production), you can run the UI by using:

    $ hypnotoad minion_ui.pl # You will able to access it at http://localhost:8080

_NB:_ If you want to know more about Minion UI deployment please read [this](https://docs.mojolicious.org/Mojolicious/Guides/Cookbook#DEPLOYMENT).

Great, now you go to the directory where you have your VCF files:

    $ cd my_vcf_file_directory

And send a job from there:

    (please change the paths to match yours)

    $ /pro/beacon-2.0.0/utils/bff_queue/bff-queue minion job -q beacon -e beacon_task -a '["cd my_vcf_file_directory ; /pro/beaco-2.0.0/beacon vcf -i in.vcf.gz -p param.in -n 1 > beacon.log 2>&1"]'

**NB:** If you are in trouble simply delete the file `minion.db` at `bff_queue` directory.

Enjoy!

Manu

### Credits

Let's give a round of applause to all the [contributors](https://github.com/mojolicious/minion) of **Minion** and in particular to [Sebastian Riedel](https://github.com/kraih).
