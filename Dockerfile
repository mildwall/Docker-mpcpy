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
RUN sed -i "350 i \\\n        if isinstance(self.model, fmi.FMUModelME2):\n            self.model.event_update()" $JMODELICA_HOME/Python/pyfmi/fmi_algorithm_drivers.py

USER developer

WORKDIR $HOME

RUN pip install --user flask-restful==0.3.9 pandas==0.24.2 flask_cors==3.0.10 requests==2.27.1 matplotlib==2.0.2 numpy==1.16.6 python-dateutil==2.6.1 pytz==2017.2 scikit-learn==0.18.2 sphinx==1.6.3 numpydoc==0.7.0 tzwhere==2.3 pyDOE==0.3.8 netCDF4==1.4.2 cftime==1.0.4.2 pvlib==0.6.0 siphon==0.8.0 protobuf==3.17.3

RUN mkdir models && \
    mkdir doc

USER root

RUN apt-get -y update && apt-get -y install curl && apt-get -qq -y install curl

RUN apt-get -y install nano && apt-get -qq -y install nano

RUN apt-get -y install libgeos-dev && apt-get -qq -y install libgeos-dev

RUN apt-get -y install git && apt-get -qq -y install git

ENV PYTHONPATH $PYTHONPATH:$HOME

CMD python restapi.py && bash

EXPOSE 5000
