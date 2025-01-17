FROM openvino/ubuntu18_runtime:2020.3

ADD . /app
WORKDIR /app

USER root
RUN apt-get update && apt-get -y upgrade && apt-get autoremove

#Pick up some TF dependencies
RUN apt-get install -y --no-install-recommends \
        build-essential \
        xdg-utils \
        apt-utils \
        cpio \
        curl \
        vim \
        git \
        lsb-release \
        pciutils \
        python3.5 \
        python3-pip \
        libgflags-dev \
        libboost-dev \
        libboost-log-dev \
        cmake \
        libx11-dev \
        libssl-dev \
        locales \
        libjpeg8-dev \
        libopenblas-dev \
        gnupg2 \
        sudo 

RUN pip3 install wheel
RUN pip3 install --upgrade pip setuptools wheel Flask==1.0.2 AWSIoTPythonSDK

WORKDIR /app/DriverBehavior
RUN git clone --recursive https://github.com/awslabs/aws-crt-cpp.git
RUN mkdir build

WORKDIR /app/DriverBehavior/third-party
RUN git clone https://github.com/davisking/dlib.git
RUN git clone https://github.com/open-source-parsers/jsoncpp.git
RUN mkdir jsoncpp/build/
WORKDIR /app/DriverBehavior/third-party/jsoncpp/build
RUN cmake -DCMAKE_BUILD_TYPE=debug -DJSONCPP_LIB_BUILD_STATIC=ON-DJSONCPP_LIB_BUILD_SHARED=OFF -G "Unix Makefiles" ../
RUN make
RUN make install

WORKDIR /app/DriverBehavior
RUN chmod +x /app/DriverBehavior/scripts/setupenv.sh

# Ros2
RUN locale-gen en_US en_US.UTF-8
RUN update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
RUN export LANG=en_US.UTF-8
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
RUN sh -c 'echo "deb http://packages.ros.org/ros2/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/ros2-latest.list'
ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y ros-crystal-ros-base

RUN apt update && apt install -y --no-install-recommends\
        python3-colcon-common-extensions \
        ros-crystal-rosbag2-test-common \
        ros-crystal-rosbag2-storage-default-plugins \
        ros-crystal-rosbag2-storage

RUN apt-get install -y --no-install-recommends \
        ros-crystal-sqlite3-vendor \
        ros-crystal-ros2bag*

# ETS-ROS2
RUN git clone https://github.com/HernanG234/ets_ros2/

WORKDIR /opt/intel/openvino/deployment_tools
RUN git clone https://github.com/opencv/open_model_zoo.git
WORKDIR /opt/intel/openvino/deployment_tools/open_model_zoo
RUN git checkout 2020.3
WORKDIR /opt/intel/openvino//deployment_tools/open_model_zoo/tools/downloader
RUN /bin/bash -c 'python3 -mpip install --user -r ./requirements.in'


WORKDIR /app/DriverBehavior/ets_ros2
RUN /bin/bash -c 'source /opt/intel/openvino/bin/setupvars.sh && source /opt/ros/crystal/setup.bash && colcon build --symlink-instal --parallel-workers 1 --cmake-args -DSIMULATOR=ON -DBUILD_DEPS=ON'

WORKDIR /app/DriverBehavior/build
RUN /bin/bash -c 'source /opt/ros/crystal/setup.bash && source /app/DriverBehavior/ets_ros2/install/setup.bash && source /opt/intel/openvino/bin/setupvars.sh && source /app/DriverBehavior/scripts/setupenv.sh && cmake -DCMAKE_BUILD_TYPE=Release -DSIMULATOR=ON -DBUILD_DEPS=ON ../ && make'
RUN /bin/bash -c 'source /opt/ros/crystal/setup.bash && source /app/DriverBehavior/ets_ros2/install/setup.bash && source /opt/intel/openvino/bin/setupvars.sh && source /app/DriverBehavior/scripts/download_models.sh'

WORKDIR /app/ActionRecognition
RUN /bin/bash -c 'source /opt/intel/openvino/bin/setupvars.sh && source /app/ActionRecognition/scripts/download_models.sh'

ENV LC_ALL=en_US.utf8

WORKDIR /app/UI
CMD ["/bin/bash"]
