FROM python:3.8

RUN apt-get update && apt-get upgrade && apt-get install -y libleveldb-dev
RUN git clone https://github.com/spesmilo/electrumx.git && cd electrumx && pip3 install .

