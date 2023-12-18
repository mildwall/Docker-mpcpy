FROM michaelwetter/ubuntu-1804_jmodelica_trunk

ENV ROOT_DIR /usr/local
ENV JMODELICA_HOME $ROOT_DIR/JModelica
ENV IPOPT_HOME $ROOT_DIR/Ipopt-3.12.4
ENV SUNDIALS_HOME $JMODELICA_HOME/ThirdParty/Sundials
ENV SEPARATE_PROCESS_JVM /usr/lib/jvm/java-8-openjdk-amd64/
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
ENV PYTHONPATH $PYTHONPATH:$JMODELICA_HOME/Python:$JMODELICA_HOME/Python/pymodelica
ENV MODELICAPATH $JMODELICA_HOME/ThirdParty/MSL

USER root
# Edit pyfmi to event update at start of simulation for ME2
# RUN sed -i "350 i \\\n        if isinstance(self.model, fmi.FMUModelME2):\n            self.model.event_update()" $JMODELICA_HOME/Python/pyfmi/fmi_algorithm_drivers.py

WORKDIR $ROOT_DIR

RUN apt-get -y update && apt-get -y install curl && apt-get -qq -y install curl && \
    apt-get -y install nano && apt-get -qq -y install nano && \
    apt-get -y install libgeos-dev && apt-get -qq -y install libgeos-dev && \
    apt-get -y install git && apt-get -qq -y install git && \
    apt-get -y install pkg-config && apt-get -qq -y install pkg-config && \
    apt-get -y install liblapack-dev && apt-get -qq -y install liblapack-dev && \
    apt-get -y install libmetis-dev && apt-get -qq -y install libmetis-dev

RUN cd $ROOT_DIR && \
    wget wget -O - http://www.coin-or.org/download/source/Ipopt/Ipopt-3.12.4.tgz | tar xzf - && \
    cd $ROOT_DIR/Ipopt-3.12.4/ThirdParty/Blas && \
    ./get.Blas && \
    cd $ROOT_DIR/Ipopt-3.12.4/ThirdParty/Lapack && \
    ./get.Lapack && \
    cd $ROOT_DIR/Ipopt-3.12.4/ThirdParty && \
    rm -r Mumps && \
    git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git &&\
    mv ThirdParty-Mumps Mumps && \
    cd Mumps && \
    ./get.Mumps && \
    ./configure && \
    make && \
    make install && \
    cd $ROOT_DIR/Ipopt-3.12.4/ThirdParty/Metis && \
    ./get.Metis && \
    cd $ROOT_DIR/Ipopt-3.12.4/ThirdParty &&\
    git clone https://github.com/coin-or-tools/ThirdParty-HSL.git

COPY ./coinhsl.tar.gz $ROOT_DIR/Ipopt-3.12.4/ThirdParty/ThirdParty-HSL

RUN cd $ROOT_DIR/Ipopt-3.12.4/ThirdParty/ThirdParty-HSL && \
    tar xvf coinhsl.tar.gz && \
    mv coinhsl-2021.05.05 coinhsl && \
    ./configure --prefix=$IPOPT_HOME && \
    #find $IPOPT_HOME/ThirdParty/HSL/coinhsl/build -type f -name "Makefile" -exec sed -i 's/aclocal-1.14/aclocal-1.15/g' {} + &&\
    #find $IPOPT_HOME/ThirdParty/HSL/coinhsl/build -type f -name "Makefile" -exec sed -i 's/automake-1.14/automake-1.15/g' {} + &&\
    make &&\
    make install &&\
    cd $ROOT_DIR/Ipopt-3.12.4 && \
    mkdir build &&\
    cd build && \
    ../configure --prefix=/usr/local/Ipopt-3.12.4 && \
    make install 

# Replace 'solver_object.output' with 'solver_object.getOutput' in all .py files throughout the entire image and miniconda install
RUN find / -type f -name "*.py" -exec sed -i 's/solver_object.output/solver_object.getOutput/g' {} + && \
    mkdir -p ~/miniconda3 && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh && \
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3 && \
    rm -rf ~/miniconda3/miniconda.sh && \
    ~/miniconda3/bin/conda init bash && \
    ~/miniconda3/bin/conda init zsh

# Create conda environment
COPY py27.yml /home/developer
COPY py310.yml /home/developer

WORKDIR $HOME

RUN ~/miniconda3/bin/conda env create -f ~/py27.yml -n py27 && \
    ~/miniconda3/bin/conda env create -f ~/py310.yml -n py310 && \
    /bin/bash -c "source ~/miniconda3/bin/activate py27" && \
    ~/miniconda3/envs/py27/bin/pip install flask-restful==0.3.9 flask_cors==3.0.10 scikit-learn==0.18.2 tzwhere==2.3 pyDOE==0.3.8 pvlib==0.6.0 siphon==0.8.0 protobuf==3.17.3

RUN mkdir models && \
    mkdir doc && \
    git clone https://github.com/lbl-srg/EstimationPy.git && \
    git clone https://github.com/lbl-srg/MPCPy.git

RUN mkdir $HOME/MODELICAPATH && mkdir git && \
    cd git && \
    git clone https://github.com/lbl-srg/modelica-buildings.git && cd modelica-buildings && git checkout 891d0c21cdbed09e7eaed0e0196ba02f85e6bc8e && cd .. && \
    ln -s $HOME/git/modelica-buildings/Buildings $HOME/MODELICAPATH/Buildings && \
    ln -s $ROOT_DIR/JModelica/ThirdParty/MSL/Modelica $HOME/MODELICAPATH/Modelica && \
    ln -s $ROOT_DIR/JModelica/ThirdParty/MSL/ModelicaServices $HOME/MODELICAPATH/ModelicaServices && \
    ln -s $ROOT_DIR/JModelica/ThirdParty/MSL/Complex.mo $HOME/MODELICAPATH/Complex.mo

ENV PYTHONPATH $PYTHONPATH:$HOME/EstimationPy:$HOME/MPCPy 
ENV MODELICAPATH $HOME/MODELICAPATH:$ROOT_DIR/JModelica/ThirdParty/MSL
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$IPOPT_HOME/lib:$JMODELICA_HOME/ThirdParty/CasADi/lib:$SUNDIALS_HOME/lib

# CMD python restapi.py && bash

EXPOSE 5000
