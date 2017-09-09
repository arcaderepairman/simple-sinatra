#!/bin/bash
#comment
cd /var/www/sinatra

/bin/scl enable rh-ruby22 '../bundle/rackup --host 0.0.0.0 -p 9292'
