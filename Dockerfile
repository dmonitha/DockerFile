# Copyright 2019-2024 The MathWorks, Inc.
# This Dockerfile allows you to build a Docker® image with MATLAB® installed using the MATLAB Package 
# Manager. Use the optional build arguments to customize the version of MATLAB, list of products to 
# install, and the location at which to install MATLAB.

# Here is an example docker build command with the optional build arguments.
# docker build --build-arg MATLAB_RELEASE=r2024a 
#              --build-arg MATLAB_PRODUCT_LIST="MATLAB Deep_Learning_Toolbox Symbolic_Math_Toolbox"
#              --build-arg MATLAB_INSTALL_LOCATION="/opt/matlab/R2024a"
#              --build-arg LICENSE_SERVER=12345@hostname.com 
#              -t my_matlab_image_name .

# To specify which MATLAB release to install in the container, edit the value of the MATLAB_RELEASE argument.
# Use lowercase to specify the release, for example: ARG MATLAB_RELEASE=r2021b
ARG MATLAB_RELEASE=R2024a


# Specify the list of products to install into MATLAB.
ARG MATLAB_PRODUCT_LIST="MATLAB Parallel_Computing_Toolbox"

# Specify MATLAB Install Location.
ARG MATLAB_INSTALL_LOCATION="/opt/matlab/${MATLAB_RELEASE}"

# Specify license server information using the format: port@hostname 
ARG LICENSE_SERVER


# When you start the build stage, this Dockerfile by default uses the Ubuntu-based matlab-deps image.
# To check the available matlab-deps images, see: https://hub.docker.com/r/mathworks/matlab-deps
FROM mathworks/matlab-deps:${MATLAB_RELEASE}

# Declare build arguments to use at the current build stage.
ARG MATLAB_RELEASE
ARG MATLAB_PRODUCT_LIST
ARG MATLAB_INSTALL_LOCATION
ARG LICENSE_SERVER

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=America
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
# Install mpm dependencies.
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install --no-install-recommends --yes \
    wget \
    ca-certificates \
    && apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

# Add "matlab" user and grant sudo permission.
RUN adduser --shell /bin/bash --disabled-password --gecos "" matlab \
    && echo "matlab ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/matlab \
    && chmod 0440 /etc/sudoers.d/matlab

# Set user and work directory.
USER matlab
WORKDIR /home/matlab

# Run mpm to install MATLAB in the target location and delete the mpm installation afterwards.
# If mpm fails to install successfully, then print the logfile in the terminal, otherwise clean up.
# Pass in $HOME variable to install support packages into the user's HOME folder.
RUN wget -q https://www.mathworks.com/mpm/glnxa64/mpm \ 
    && chmod +x mpm \
    && sudo HOME=${HOME} ./mpm install \
    --release=${MATLAB_RELEASE} \
    --destination=${MATLAB_INSTALL_LOCATION} \
    --products ${MATLAB_PRODUCT_LIST} \
    || (echo "MPM Installation Failure. See below for more information:" && cat /tmp/mathworks_root.log && false) \
    && sudo rm -rf mpm /tmp/mathworks_root.log \
    && sudo ln -s ${MATLAB_INSTALL_LOCATION}/bin/matlab /usr/local/bin/matlab

# Note: Uncomment one of the following two ways to configure the license server.

# Option 1. Specify the host and port of the machine that serves the network licenses
# if you want to store the license information in an environment variable. This
# is the preferred option. You can either use a build variable, like this: 
# --build-arg LICENSE_SERVER=27000@MyServerName or you can specify the license server 
# directly using: ENV MLM_LICENSE_FILE=27000@flexlm-server-name
ENV MLM_LICENSE_FILE=$LICENSE_SERVER

# Option 2. Alternatively, you can put a license file into the container.
# Enter the details of the license server in this file and uncomment the following line.
# COPY network.lic ${MATLAB_INSTALL_LOCATION}/licenses/

# The following environment variables allow MathWorks to understand how this MathWorks 
# product (MATLAB Dockerfile) is being used. This information helps us make MATLAB even better. 
# Your content, and information about the content within your files, is not shared with MathWorks. 
# To opt out of this service, delete the environment variables defined in the following line. 
# To learn more, see the Help Make MATLAB Even Better section in the accompanying README: 
# https://github.com/mathworks-ref-arch/matlab-dockerfile#help-make-matlab-even-better
ENV MW_DDUX_FORCE_ENABLE=true MW_CONTEXT_TAGS=MATLAB:DOCKERFILE:V1

ENTRYPOINT ["matlab"]

# ... [Your existing Dockerfile content]
USER root
RUN apt-get update && \
    apt-get install -y git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# Install required dependencies for MatConvNet
RUN sudo apt-get update && \
    sudo apt-get install --no-install-recommends --yes \
    libatlas-base-dev \
    libopencv-dev \
    && sudo apt-get clean

# Set environment variable for MatConvNet installation path
ENV MATCONVNET_ROOT="/home/matlab/matconvnet"

# # Clone MatConvNet repository
# RUN git clone https://github.com/vlfeat/matconvnet.git ${MATCONVNET_ROOT} && \
#     cd ${MATCONVNET_ROOT} && \
#     git checkout master
    # Specify the version/tag you want to install
    # cd ${MATCONVNET_ROOT} && 
# Download and extract MatConvNet
RUN wget -q http://www.vlfeat.org/matconvnet/download/matconvnet-1.0-beta17.tar.gz && \
    tar -xzf matconvnet-1.0-beta17.tar.gz && \
    mv matconvnet-1.0-beta17 ${MATCONVNET_ROOT} && \
    rm matconvnet-1.0-beta17.tar.gz

    # Start a MATLAB session to configure MEX
RUN sudo apt-get install -y wget build-essential libjpeg-turbo8-dev
RUN matlab -batch "addpath('${MATCONVNET_ROOT}/matlab'); mex -setup C++; exit;"

# Compile MatConvNet
RUN matlab -batch "addpath('${MATCONVNET_ROOT}/matlab'); vl_compilenn;"
# Compile MatConvNet
# RUN matlab -batch "addpath('${MATCONVNET_ROOT}/matlab'); vl_compilenn;"

# RUN cd ${MATCONVNET_ROOT} && \
#     sudo apt-get install build-essential libjpeg-turbo8-dev\
#     bash -c "matlab -batch \"addpath('${MATCONVNET_ROOT}/matlab');vl_setupnn "
# # run "${MATCONVNET_ROOT}/matab/vl_setupnn"
# # Add MatConvNet to MATLAB path
# RUN echo "addpath('${MATCONVNET_ROOT}/matlab'); savepath;" | matlab -batch

# ... [Rest of your Dockerfile content]

CMD [""]