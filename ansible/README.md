This folder contains the Anisble Infrastructure Code to configure the sinatra servers.
There are a few roles :

  sinatra.yml contains all the roles and variables require to run the code.  to run this playbook :

    ansible

  aws-cfn-bootstrap :
    Installs cfn-init and friends on the CentOS AMI that I am using... it installs from a tarball rather than from
    an rpm... because the rpm is broken.. well at least for CentOS.
    It creates systemd services and installs in the default location of /opt/aws/bin

  git:

    This is a small one I though I was going to add more but my ideas pivoted, and I didn't, anyway it just installs git on the host.

  nginx

    Installs NGINX on to the host and configures it to proxy_pass to the Sinatra server listening on localhost:9292. It adds a locked
    down config file... it's fairly basic, but it works.

  ruby

    Installs ruby 2.2 and from a special Redhat repo.. CentOS 7 only support ruby 2.0... and its always a pain to use anything else.
    This sets up the new repo, installs Ruby and Bundler and gets it ready for Sinatra

  security

    This one configures firewalld opening port 22 and port 80... I reckon I could add in a bit more in this role to lock down the
     host further. Things like running the CIS Security Benchmarks. I ran out of time add this in, but would definitely be running this in a really situation.

  sinatra

    The one were it all happens... it downloads the simple-sinatra-app from git hub, sets up some directories runs bundler and creates a
    systemd service to start the server (rackup)... I would probably replace this role and the ruby role with a docker container to make
    deployment easier.

  test

    Test to see if sinatra is actually up and running on the localhost port and that NINX is proxying through to it.
