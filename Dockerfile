FROM pytorch/pytorch:2.1.1-cuda12.1-cudnn8-runtime

# ARGS
ARG INSTALLDIR="/webui" \
  RUN_UID=1000 \
  DEBIAN_FRONTEND=noninteractive
ENV INSTALLDIR=$INSTALLDIR \
  RUN_UID=$RUN_UID \
  DATA_DIR=$INSTALLDIR/data \
  TZ=Etc/UTC

# Install dependencies (apt)
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  wget git libgl1 libglib2.0-0 \
  # necessary for extensions
  ffmpeg libglfw3-dev libgles2-mesa-dev pkg-config libcairo2 libcairo2-dev \
  build-essential \
  libgoogle-perftools-dev

# Setup user which will run the service
RUN useradd -m -u $RUN_UID webui-user
USER webui-user

# Copy Local Files to Container
COPY --chown=webui-user . $INSTALLDIR

# Setup venv and pip cache
RUN mkdir -p $INSTALLDIR/cache/pip \
  && mkdir -p $DATA_DIR

ENV PIP_CACHE_DIR=$INSTALLDIR/cache/pip

# Install dependencies (pip, wheel)
RUN pip install -U pip wheel

WORKDIR $INSTALLDIR
# Start container as root in order to enable bind-mounts
USER root
ENV TORCH_CUDA_ARCH_LIST=All
ENV MAX_JOBS=4
ENV LD_PRELOAD=libtcmalloc.so
RUN ${INSTALLDIR}/entrypoint.sh --test --upgrade --skip-torch
RUN WITH_CUDA=0 pip install -v -U git+https://github.com/chengzeyi/stable-fast.git@v1.0.4#egg=stable-fast

ARG GIT_SHA
ENV GIT_SHA=$GIT_SHA

ENTRYPOINT ["/bin/bash", "-c", "${INSTALLDIR}/entrypoint.sh \"$0\" \"$@\""]

CMD ["--listen", "--docs", "--skip-requirements", "--skip-extensions", "--skip-tests", "--skip-git", "--skip-torch", "--quick"]