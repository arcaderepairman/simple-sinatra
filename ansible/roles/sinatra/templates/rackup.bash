#!/bin/bash
# start up script for sinatra rackup
cd {{ www_dir }}/{{ sinatra_dir }}

/bin/scl enable rh-ruby22 '../{{ bundle_dir }}/rackup --host {{ rack_bind }} -p {{ rack_port }}'
