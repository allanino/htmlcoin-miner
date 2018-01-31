# HTMLCOIN Miner

This is just a Dockerfile to build the HTMLCOIN bineries optimized for mining.

Besides the [Dockerfile](Dockerfile) we have just a [start.sh](start.sh) script to run the HTMLCOIN
daemon and to start the miners.

This script was copied from [cl04ker/HTMLCOIN-Script](https://github.com/cl04ker/HTMLCOIN-Scripts)
with minor modifications to work seamlessly with Docker. Thanks for the great work @cl04ker.

## Usage

Just change the `MINERS` to match the number of CPU cores you want to use and the `ADDRESS` to put your wallet address (or leave it as it is to mine for me :P):

```
docker run -e MINERS=8 -e ADDRESS=Hkoc1w4A29nbm8aBGeSUJ6hD2qHtx7PFRd allanino/htmlcoin-miner
```

If you want to persist the blocks in the host to allow faster reinitialization, just add `-v $HOME/.htmlcoin-docker:/root/.htmlcoin` to the above command:

```
docker run -e MINERS=8 -e ADDRESS=Hkoc1w4A29nbm8aBGeSUJ6hD2qHtx7PFRd -v $HOME/.htmlcoin-docker:/root/.htmlcoin allanino/htmlcoin-miner
```

The data will be stored in `$HOME/.htmlcoin-docker` in the above example.

## Build

To build the image yourself, just clone this repo and run `docker build -t htmlcoin-miner .`.
