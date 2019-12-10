docker run --rm -it -v $PWD:/workspace  marquisrobb/alpine_32 /bin/sh /workspace/build_all.sh && \
docker run --rm -it -v $PWD:/workspace  marquisrobb/alpine_64 /bin/sh /workspace/build_all.sh && \
docker run --rm -it -v $PWD:/workspace  marquisrobb/bionic_32 /bin/sh /workspace/build_all.sh && \
docker run --rm -it -v $PWD:/workspace  marquisrobb/bionic_64 /bin/sh /workspace/build_all.sh && \
docker run --rm -it -v $PWD:/workspace  marquisrobb/centos_32 /bin/sh /workspace/build_all.sh && \
docker run --rm -it -v $PWD:/workspace  marquisrobb/centos_64 /bin/sh /workspace/build_all.sh
