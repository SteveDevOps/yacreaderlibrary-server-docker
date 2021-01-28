FROM debian:buster

ARG YACR_COMMIT
LABEL maintainer="wolgan"

WORKDIR /src/git

RUN \
 echo "**** install runtime packages ****" && \
 apt-get update && \
 apt-get install -y \
    curl \
    git \
    qt5-default \
    libpoppler-qt5-dev \
    libpoppler-qt5-1 \
    libqt5core5a \
    libqt5gui5 \       
    libqt5multimedia5 \
    libqt5opengl5 \
    libqt5network5 \
    libqt5quickcontrols2-5 \
    libqt5script5 \
    libqt5sql5-sqlite \
    libqt5sql5 \
    qt5-image-formats-plugins \
    qtdeclarative5-dev \
    sqlite3 \
    unzip \
    wget \   
    build-essential	\
    cmake \
    nano \
    zlib1g-dev \
    liblzma-dev \
    libbz2-dev

RUN \
 echo "**** clone YACReader locally****" && \
 if [ -z ${YACR_COMMIT+x} ]; then \
	YACR_COMMIT=$(curl -sX GET https://api.github.com/repos/YACReader/yacreader/commits/develop \
	| awk '/sha/{print $4;exit}' FS='[""]'); \
 fi && \
 git clone -b develop --single-branch https://github.com/YACReader/yacreader.git . && \
 git checkout ${YACR_COMMIT}

RUN \
 echo "**** install unarr libraries with 7zip support ****" && \
 LD_LIBRARY_PATH=/usr/local/lib/ && \
 export LD_LIBRARY_PATH && \
 cd /src/git/compressed_archive/ && \
 mv unarr/ unarr-bak && \
 git clone https://github.com/selmf/unarr && \
 cd /src/git/compressed_archive/unarr-bak/ && \
 cp * /src/git/compressed_archive/unarr/ && \
 cd /src/git/compressed_archive/unarr/ && \
 mkdir build && \
 cd /src/git/compressed_archive/unarr/build && \
 cmake .. -DENABLE_7Z=ON && \
 make && \
 make install && \
 ldconfig -V /usr/local/lib/

RUN \
 echo "**** building YACReaderServerLibrary ****" && \
 PATH=$PATH:~/usr/local/lib && \
 printenv LD_LIBRARY_PATH && \
 LD_LIBRARY_PATH=/usr/local/lib/ && \
 export LD_LIBRARY_PATH && \
 cd /src/git/YACReaderLibraryServer && \
 qmake "CONFIG+=server_standalone" YACReaderLibraryServer.pro && \
 make && \
 make install

ADD YACReaderLibrary.ini /root/.local/share/YACReader/YACReaderLibrary/

VOLUME /comics

RUN \
 YACReaderLibraryServer add-library Comic\ Libraries /comics/Libraries

EXPOSE 8080

ENV LC_ALL=C.UTF8

ENTRYPOINT ["YACReaderLibraryServer","start"]
