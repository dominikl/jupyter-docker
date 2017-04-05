FROM jupyter/notebook:latest

RUN mkdir /omero-install
WORKDIR /omero-install
RUN git clone git://github.com/ome/omero-install .
WORKDIR /omero-install/linux
RUN \
	bash -eux step01_ubuntu_init.sh && \
	bash -eux step01_ubuntu_java_deps.sh && \
	bash -eux step01_ubuntu_deps.sh && \
	ICEVER=ice36 bash -eux step01_ubuntu_ice_deps.sh && \
	OMERO_DATA_DIR=/home/omero/data bash -eux step02_all_setup.sh

# Require for matplotlib
RUN apt-get install -y libpng-dev libjpeg8-dev libfreetype6-dev

USER omero
WORKDIR /home/omero
RUN virtualenv --system-site-packages /home/omero/omeroenv && /home/omero/omeroenv/bin/pip install omego==0.5.0
RUN /home/omero/omeroenv/bin/omego download server --release 5.3.0 --ice 3.6  --sym auto
RUN /home/omero/omeroenv/bin/pip install markdown
RUN /home/omero/omeroenv/bin/pip install -U matplotlib
RUN /home/omero/omeroenv/bin/pip install pandas sklearn seaborn
RUN /home/omero/omeroenv/bin/pip install joblib

USER root
RUN apt-get install -y libigraph0-dev
RUN add-apt-repository ppa:igraph/ppa
RUN apt-get update
RUN apt-get install python-igraph

USER omero
RUN /home/omero/omeroenv/bin/pip install py2cytoscape
RUN echo 'export PYTHONPATH=$HOME/OMERO.server/lib/python' >> $HOME/.bashrc

# Add a notebook profile.
WORKDIR /notebooks
RUN mkdir -p -m 700 $HOME/.jupyter/ && \
    echo "c.NotebookApp.ip = '*'" >> $HOME/.jupyter/jupyter_notebook_config.py

RUN mkdir -p /home/omero/.local/share/jupyter/kernels/python2/
COPY kernel.json /home/omero/.local/share/jupyter/kernels/python2/kernel.json

# RISE
RUN git clone https://github.com/damianavila/RISE /tmp/RISE && \
    cd /tmp/RISE && /home/omero/omeroenv/bin/python setup.py install

CMD ["env", "PYTHONPATH=/home/omero/OMERO.server/lib/python", "/home/omero/omeroenv/bin/python", "/usr/local/bin/jupyter", "notebook", "--no-browser", "--ip=0.0.0.0"]
