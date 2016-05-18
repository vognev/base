FROM vognev/base

ADD https://getcomposer.org/composer.phar /usr/local/bin/composer

RUN chmod +x /usr/local/bin/composer && \
  apt-get update && apt-get install -y php5-cli php5-mysql && \
  rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y wget apt-transport-https && \
  wget -qO- https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
  echo 'deb https://deb.nodesource.com/node_4.x jessie main' > /etc/apt/sources.list.d/nodesource.list && \
  apt-get update && apt-get install -y nodejs && \
  npm install -g gulp-cli && \
  apt-get remove --purge -y wget apt-transport-https && \
  apt-get autoremove -y && rm -rf /var/lib/apt/lists/*  
