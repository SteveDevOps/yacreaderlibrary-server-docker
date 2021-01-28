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
 cd /src/git/ && \
 git clone https://github.com/selmf/unarr && \
 cd /src/git/unarr/ && \
 mkdir build && \
 cd /src/git/unarr/build && \
 cmake .. -DENABLE_7Z=ON -DBUILD_SHARED_LIBS=ON && \
 make && \
 make install && \
 printenv LD_LIBRARY_PATH && \
 ldconfig -V && \
 ln -s /src/git/unarr/unarr.h /usr/include/unarr.h && \
 ln -s /usr/local/lib/libunarr.so /usr/lib/x86_64-linux-gnu/libunarr.so && \
 ln -s /usr/local/lib/pkgconfig/libunarr.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libunarr.pc

RUN \
 echo "**** building YACReaderServerLibrary ****" && \
 cd /src/git/YACReaderLibraryServer && \
 qmake "CONFIG+=server_standalone" YACReaderLibraryServer.pro && \
 make && \
 make install

ADD YACReaderLibrary.ini /root/.local/share/YACReader/YACReaderLibrary/

VOLUME /comics

EXPOSE 8080

ENV LC_ALL=C.UTF8

ENTRYPOINT ["YACReaderLibraryServer","start"]
