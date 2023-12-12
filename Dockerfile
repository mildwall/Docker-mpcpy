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

USER developer

WORKDIR $HOME

RUN pip install --user flask-restful==0.3.9 pandas==0.20.3 flask_cors==3.0.10 requests==2.27.1 matplotlib==2.0.2 numpy==1.16.6 python-dateutil==2.6.1 pytz==2017.2 scikit-learn==0.18.2 sphinx==1.6.3 numpydoc==0.7.0 tzwhere==2.3 pyDOE==0.3.8 netCDF4==1.4.2 cftime==1.0.4.2 pvlib==0.6.0 siphon==0.8.0 protobuf==3.17.3

RUN mkdir models && \
    mkdir doc

USER root

RUN apt-get -y update && apt-get -y install curl && apt-get -qq -y install curl

RUN apt-get -y install nano && apt-get -qq -y install nano

RUN apt-get -y install libgeos-dev && apt-get -qq -y install libgeos-dev

RUN apt-get -y install git && apt-get -qq -y install git

RUN git clone https://github.com/lbl-srg/EstimationPy.git \
    && git clone https://github.com/lbl-srg/MPCPy.git

ENV ROOT_DIR /usr/local

WORKDIR $HOME

RUN mkdir $HOME/MODELICAPATH && mkdir git && \
    cd git && \
    git clone https://github.com/lbl-srg/modelica-buildings.git && cd modelica-buildings && git checkout 891d0c21cdbed09e7eaed0e0196ba02f85e6bc8e && cd .. && \
    ln -s $HOME/git/modelica-buildings/Buildings $HOME/MODELICAPATH/Buildings && \
    ln -s $ROOT_DIR/JModelica/ThirdParty/MSL/Modelica $HOME/MODELICAPATH/Modelica && \
    ln -s $ROOT_DIR/JModelica/ThirdParty/MSL/ModelicaServices $HOME/MODELICAPATH/ModelicaServices && \
    ln -s $ROOT_DIR/JModelica/ThirdParty/MSL/Complex.mo $HOME/MODELICAPATH/Complex.mo
ENV MODELICAPATH $HOME/MODELICAPATH:$ROOT_DIR/JModelica/ThirdParty/MSL

WORKDIR $ROOT_DIR

ENV PYTHONPATH $PYTHONPATH:$HOME/EstimationPy:$HOME/MPCPy 

# Replace 'solver_object.output' with 'solver_object.getOutput' in all .py files throughout the entire image
RUN find / -type f -name "*.py" -exec sed -i 's/solver_object.output/solver_object.getOutput/g' {} +

COPY ./coinhsl-2021.05.05 $IPOPT_HOME/include/coin/ThirdParty
RUN cd $IPOPT_HOME/include/coin/ThirdParty && \
    #tar xvf coinhsl.tar.gz && \
    mv coinhsl-2021.05.05 HSL && \
    cd HSL && \
    mkdir build && \
    cd build && \
    ../configure --prefix=$IPOPT_HOME && \
    find $IPOPT_HOME/include/coin/ThirdParty/HSL/build -type f -name "Makefile" -exec sed -i 's/aclocal-1.14/aclocal-1.15/g' {} + &&\
    find $IPOPT_HOME/include/coin/ThirdParty/HSL/build -type f -name "Makefile" -exec sed -i 's/automake-1.14/automake-1.15/g' {} + &&\
    make &&\
    make install

ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$IPOPT_HOME/lib:$JMODELICA_HOME/ThirdParty/CasADi/lib:$SUNDIALS_HOME/lib

# CMD python restapi.py && bash

EXPOSE 5000
