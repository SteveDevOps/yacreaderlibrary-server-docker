FROM debian:buster

ARG YACR_COMMIT
LABEL maintainer="xthursdayx"

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
    build-essential	
RUN \
 echo "**** install YACReader ****" && \
 if [ -z ${YACR_COMMIT+x} ]; then \
	YACR_COMMIT=$(curl -sX GET https://api.github.com/repos/YACReader/yacreader/commits/develop \
	| awk '/sha/{print $4;exit}' FS='[""]'); \
 fi && \
 git clone -b develop --single-branch https://github.com/YACReader/yacreader.git . && \
 git checkout ${YACR_COMMIT}
RUN \
 cd compressed_archive/unarr/ && \
 wget https://github.com/selmf/unarr/archive/master.zip && \
 unzip master.zip  && \
 rm master.zip && \
 cd unarr-master/lzmasdk && \
 ln -s 7zTypes.h Types.h
RUN \
 cd /src/git/YACReaderLibraryServer && \
 qmake "CONFIG+=server_standalone" YACReaderLibraryServer.pro && \
 make  && \
 make install

ADD YACReaderLibrary.ini /root/.local/share/YACReader/YACReaderLibrary/

VOLUME /comics

EXPOSE 8080

ENV LC_ALL=C.UTF8

ENTRYPOINT ["YACReaderLibraryServer","start"]
