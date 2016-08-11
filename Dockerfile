FROM ubuntu:trusty
MAINTAINER Dario Andrei <wouldgo84@gmail.com>

ENV TERM xterm
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y git \
  libtool \
  automake \
  pkg-config \
  libcurl4-gnutls-dev \
  sudo \
  build-essential \
  libboost1.54-all-dev \
  software-properties-common \
  wget

RUN git clone --depth=1 --recurse-submodules --single-branch --branch=master https://github.com/valhalla/mjolnir.git && \
  cd mjolnir && \
  ./scripts/dependencies.sh && \
  ./scripts/install.sh && \
  cd ..

RUN git clone --depth=1 --recurse-submodules --single-branch --branch=master https://github.com/valhalla/tools.git && \
  cd tools && \
  ./scripts/dependencies.sh && \
  ./scripts/install.sh && \
  cd ..

ADD ./conf /conf

RUN ldconfig

# Get Data for PA
RUN wget http://download.geofabrik.de/north-america/us/pennsylvania-latest.osm.pbf

RUN mkdir -p /data/valhalla
RUN valhalla_build_admins -c conf/valhalla.json *.pbf
RUN valhalla_build_tiles -c conf/valhalla.json *.pbf

RUN apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Edit max_time for Isochrone to be 600 minutes & max_contours to 10
RUN sed -i 's/"max_time": 120/"max_time": 600/g' conf/valhalla.json && \
sed -i 's/"max_contours": 4/"max_contours": 10/g' conf/valhalla.json


EXPOSE 8002
CMD ["tools/valhalla_route_service", "conf/valhalla.json"]
