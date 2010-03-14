OctoSquashes
=============

An experimental visualization of github timeline.
You can visit the live website [Github](http://octos.quash.es)
This project is an extration of the code running on the actual website.

Requirements
-------

  * the following ruby gems

    superfeedr-rb
    restclient
    json

  * an installation of couchdb v 0.10.0 (or greater) running on localhost

  * Nginx running on the localhost address


Install
-------

  * checkout the code from Github

    git checkout git://github.com/hungryblank/octo_squash_es.git

  * configure nginx so the config file `config/nginx.conf` is loaded
  * add an entry in your /etc/hosts so local.quash.es points to 127.0.0.1
  * run the deploy rake task from the root dir of the project

    rake deploy

  * open an account at http://superfeedr.com and subscribe to the feed
  * in superfeedr dashboard subscribe to the github timeline

    http://github.com/timeline.atom

  * start the script to feed the database

    export SUPERFEEDR_USER=your_username@superfeedr.com
    export SUPERFEEDR_PWD=superfeedr_pwd

    ruby squasher.rb

  * after a while you should see entries appearing in couchdb

    http://127.0.0.1/squasher

  * and you should be able to see the actual application visiting

   http://local.quash.es

Copyright
---------

Copyright (c) 2009 hungryblank. See LICENSE for details.
