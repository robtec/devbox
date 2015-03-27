FROM debian:jessie
MAINTAINER Tom Barlow <tomwbarlow@gmail.com>

ENV FISH_VERSION 2.1.2
ENV GO_VERSION 1.3.3

RUN apt-get update
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get install -y \
    build-essential \
    gcc \
    libncurses5-dev \
    make \
    tmux \
    wget \
    curl \
    sudo \
    vim \
    mercurial \
    git-core \
    golang 

# dev user configuration
RUN useradd dev
RUN echo "ALL            ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers
WORKDIR /home/dev
ENV HOME /home/dev

# dotfiles
RUN git clone https://github.com/tombee/dotfiles /home/dev/.dotfiles
RUN cd /home/dev/.dotfiles && git submodule init && git submodule update && cd /home/dev

# Install and run rcm
RUN wget https://thoughtbot.github.io/rcm/debs/rcm_1.2.3-1_all.deb && dpkg -i rcm_1.2.3-1_all.deb && rm rcm_1.2.3-1_all.deb 
RUN ln -s /home/dev/.dotfiles/rcrc /home/dev/.rcrc
RUN rcup

# fish shell
RUN (cd /tmp && wget http://fishshell.com/files/${FISH_VERSION}/fish-${FISH_VERSION}.tar.gz && \
    tar zxf fish-${FISH_VERSION}.tar.gz && \
    cd fish-${FISH_VERSION} && \
    ./configure --prefix=/usr/local && \
    make install && \
    rm /tmp/fish-${FISH_VERSION}.tar.gz && \
    echo '/usr/local/bin/fish' | tee -a /etc/shells && \
    chsh -s /usr/local/bin/fish dev)

# go
RUN wget https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz && \
    tar -C /usr/local -xvf /tmp/go.tar.gz && rm /tmp/go.tar.gz
ENV GOROOT /usr/local/go
ENV GOPATH $HOME/dev/gocode
ENV PATH /usr/local/go/bin:$GOPATH/bin:$PATH
RUN go get github.com/tools/godep && \
    go get code.google.com/p/go.tools/cmd/present

# latest docker binary
RUN wget https://get.docker.io/builds/Linux/x86_64/docker-latest -O /usr/local/bin/docker && \
    chmod +x /usr/local/bin/docker

RUN chown -R dev:dev $HOME && \
    groupadd -g 999 vboxsf && \
    groupadd -g 1002 docker && \
    usermod -aG vboxsf dev && \
    usermod -aG docker dev
VOLUME /home/dev
USER dev
CMD ["/usr/local/bin/fish"]
