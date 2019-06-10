# images
FROM ubuntu:latest

# source files
ADD . /opt/crawlab

# set as non-interactive
ENV DEBIAN_FRONTEND noninteractive

# environment variables
ENV NVM_DIR /usr/local/nvm  
ENV NODE_VERSION 8.12.0
ENV WORK_DIR /opt/crawlab

# install pkg
RUN apt-get update \
	&& apt-get install -y curl git net-tools iputils-ping ntp gnupg2 nginx redis python python3 python3-pip \
	&& service redis-server start \
	&& cp $WORK_DIR/crawlab.conf /etc/nginx/conf.d \
	&& service nginx reload \
	&& ln -s /usr/bin/pip3 /usr/local/bin/pip \
	&& ln -s /usr/bin/python3 /usr/local/bin/python

# install mongodb
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4 \ 
	&& echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.0.list \
	&& apt-get update \
	&& apt-get install -y mongodb-org
RUN mongod >> /var/log/mongod.log 2>&1 &

# install python
#RUN git clone git://github.com/yyuu/pyenv.git ~/.pyenv
#ENV PYENV_ROOT "$HOME/.pyenv"
#ENV PATH "$PYENV_ROOT/bin:$PATH"
#RUN eval "$(pyenv init -)"
#RUN pyenv install 3.6.8
#RUN pyenv local 3.6.8

# install nvm
RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.24.0/install.sh | bash \  
    && . $NVM_DIR/nvm.sh \
    && nvm install v$NODE_VERSION \
    && nvm use v$NODE_VERSION \
    && nvm alias default v$NODE_VERSION
ENV NODE_PATH $NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules  
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# install frontend
RUN npm install -g yarn pm2 --registry=https://registry.npm.taobao.org \
	&& cd /opt/crawlab/frontend \
	&& yarn install --registry=https://registry.npm.taobao.org

# install backend
RUN pip install -U setuptools -i https://pypi.tuna.tsinghua.edu.cn/simple \
	&& pip install -r /opt/crawlab/crawlab/requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple


# start backend
EXPOSE 8080
EXPOSE 8000
WORKDIR /opt/crawlab
ENTRYPOINT ["/bin/sh", "/opt/crawlab/docker_init.sh"]