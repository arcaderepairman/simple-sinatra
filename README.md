This is my submission to the REA Systems Engineer practical task.
 https://github.com/rea-cruitment/simple-sinatra-app

NOTES:
- All functions for this project can be initiated via a central make file... but more on that later.

- In each directory there are other README files that contain specific information for that directory's function.

- All hosts are locked down via network ACLs, to get external access I restricted them to my gateway IP.  By default hosts
granted access to 172.31.0.0/16 which is the VPC network, (for ssh and http in test and ssh only in prod) you can pass in
other ranges by modifying the SSHLocation and HTTPLocation variables in the make file.

- I will send AWS access details in the submission email, however this should be able to run on any AWS account provided
it has a Vpc configured over at least 2 AZs with 2 subnets, one in each AZ and you provide the make file with vaild subnet
ids and Vpc id.

- I have configured my solution to run in AWS ap-southeast-2 only, using some simple cloud formation templates, Ansible
and a make file, to "make" it all run. The server builds are based on CentOS 7 AMI (ami-34171d57) and hasn't been tested
on any other OS.


Design considerations :

    I didn't use Docker/containers as part of this submission but there would have been advantages if I did.
    eg: Bundling up all the Ruby dependencies in a container.  I wanted to limit the tooling as much as possible..
    so running sinatra on the VM seemed a leaner approach.

    I have 1 test Cloud Formation script : cloudformation\EC2instance.json which is just single host wrapped up in a
    security group. I used that to test the infra code on.

    The Cloud Formation setup for "production" uses an ELB and an auto-scaling group with some maximum and minimum limits.

    The design is relatively simple, and a quick way to deploy the sinatra app to the internet. Since the app itself
    was quiet basic there weren't too many dependencies.  I decided that a simple config as illustrated would be
    sufficient. (see photo in the repo)
    Its a 2 tier design with a loadbalancer in front classic kind of single DMZ design.  However if there were database
    servers involved the result would have been quiet different, involving at least another network layer DMZ for the
    database servers to be hosted in.

    The Autoscalling group is enough to scale the application (by default build on t2.small hosts) and since there is
    no state, a simple round robin policy ( the default ) is fine, again if state or connection persistency was an
    issue the design would have involved a different LB configuration.

    The hosts themselves are running firewalld to limit their exposure, I think that more could be done here to improve
    security, for example running the CIS security benchmark on the server to ensure better hardening.

    So how does the app get on the server ? ...  The Ansible infrastructure code has a sinatra role that runs a
    git clone from the simple-sinatra-app repo.  

    How does the Ansible code get on the server ?... The Ansbile code is transferred as a tarball to an S3 bucket
    once testing is complete. The production hosts will pull the tarball down and execute it upon deployment.  This
    runs on first boot (when the cloudformation template is deployed) and is kicked off by a small script in the
    userdata.  I tired to keep this script as small as possible and have kept most of the infrastructure code within
    Ansible.

    I don't have a pipe line for the the testing past, but the make files could be used for such a purpose. Also
    there are no server spec test. But I believe they could be applied to this model.  Also e2e tests could be part
    of that pipeline via the test stack.

    Code updates can be applied directly to the hosts after deployment, via the Ansible code, but I would recommend
    instance rebuilds over this.

    That about sums it up, there is more information about the inner working within the steps below that will give
    you more context on how it works.


  Let's get started.
  =================

  Prerequisites:

  Deployment can happen from any Linux hosting or equivalent (CentOS is preferred) provided you have the following
  prerequisites:

   - Connection to the internet

   - These Packages installed:.
      git make, jq, python, pypthon-pip, awscli, ansible (for local tests), ssh, bash

      if your running CentOS (which I am) you need the epel-release repo too.

      This should get you going :

      #> yum install epel-release

      #> yum install make jq python pypthon-pip awscli ansible ssh bash git
      

  Getting Set Up
  ================
  Install and configure the awscli:  
  for details on installing the awscli via pip, look in the awscli folder but you can use the rpm too
  ---------------------------------

  Configure the AWS cli with the provided access keys.

  #> aws configure

    AWS Access Key ID:
    AWS Secret Access Key:
    Default region name:   ap-southeast-2
    Default output format: json

  Setup your server access key (filename : rea_access_key.pem contained in the submission email)
  ----------------------------

  To access the AWS hosts you will need a copy of the server access key.
  The default location for this is in your homedir ( ~/ )  
  You can modify the default path via editing AWS_SERVER_SSH_KEY_FILE variable directly within the make file.


  Clone the repo
  --------------
  Assuming you have install the above, just clone this repo to get started

    #> git clone https://github.com/arcaderepairman/simple-sinatra.git

  All builds/process are executed via make, I find it a simple way to bundle together a bunch of things that need to be done.

  Run make to see help on the available options.


    #> make

    build_test_infra:      Using cloud formation build test infrastructure stack testsinatrastack
    delete_test_infra:     Delete the test stack testsinatrastack
    validate_test_cf:      Validate the test stack cloudformation json
    build_infra:           Using cloud formation build production infrastructure stack prodsinatrastack
    delete_infra:          Delete the production stack prodsinatrastack
    validate_cf:           Validate the production stack cloudformation json
    deploy_test_config:    Deploy the test ansible code to the test stack testsinatrastack
    deploy_config_local:   Run the ansible code on the local host
    help:                  Print this menu to the screen


  Understanding the defaults
  ---------------------------

  These variable are located at the top of the make file and can be modified to suit your environment.

      SSHLocation               # IP range that allows ssh to the sinatra servers set this to your internet getaway
      HTTPLocation              # same as above but for http, but only for the test stack
      AWS_SERVER_SSH_KEY        # default filename for the server ssh key
      AWS_SERVER_SSH_KEY_FILE   # default filename location the server ssh key ~
      CF_TEST_TEMPLATE          # test Cloudformation template filename
      CF_TEMPLATE               # production cloudformation template filename
      STACK_NAME                # production stack name
      TEST_STACK_NAME           # test stack name
      Subnets_2a                # predefined subnets in the aws account
      Subnets_2b                # predefined subnets in the aws account
      VpcId                     # predefined Vpc in the aws account
      ansible_user              # the CentOS default user, used by ansible
      S3_bucket=a               # s3 bucket location where we deploy the ansible code too for production.


  For our example the AWS Vpc and subnets have already been defined and defaulted above no need to change them for the
  given account.


  Let's start building!
  ---------------------

  Okay now for the fun stuff: First let's build our test stack to test the Ansible infrastructure code.

    #> cd <repo directory>
    #> make build_test_infra
    Building testsinatrastack infrastructure...
    .....
    Waiting... this may take a while
    testsinatrastack Created!
    Your Test URL is :
    ec2-54-252-173-67.ap-southeast-2.compute.amazonaws.com

    Assuming you have set both HTTPLocation and SSHLocation to your network gateway (internet IP) you can use the url
    above to access the server via ssh.  There wont be anything on the http endpoint until you deploy the Ansible code
    so the url wont work in a browser.  However you can use to access the machine via ssh using the supplied pem key,
    but its just a plain CentOS image at the moment.

      To ssh in : #> ssh -i ~/rea_access_key.pem centos@ec2-54-252-173-67.ap-southeast-2.compute.amazonaws.com

  Let's test our Ansible code:

    #> make deploy_test_config
    Deploying infra code to testsinatrastack
    .........
    PLAY RECAP **************************************************************************************************
    localhost                  : ok=28   changed=27   unreachable=0    failed=0

    ------------------------------------------------------------
    What's happening here :
    This will tar up the Ansible source code and upload it to the test Sinatra server in the stack you just built and
    execute it.  Check the results... browse to your url
    (in this case http://ec2-54-252-173-67.ap-southeast-2.compute.amazonaws.com ) If all is okay you can upload the
    code to the S3 bucket for production deployments.

    NOTE: I copy the code to the host rather than using the Ansible locally to push the code, because I was experiencing
    some intermit internet issues causing very slow ansible runs.
    If your having trouble connection check the value of SSHLocation in the make file.
    -----------------------------------------------------------

  Okay let's upload the code to S3 for the production stack :

    #> make cp_s3

    ./ansible/roles/sinatra/vars/
    ./ansible/roles/sinatra/vars/main.yml
    ./ansible/sinatra.yml
    aws s3 cp ./ansible.tar s3://simple-sinatra/ansible.tar
    upload: ./ansible.tar to s3://simple-sinatra/ansible.tar

    ---------------------------------------------------
    You are now ready to deploy the product ion stack.
    --------------------------------------------------

    #> make build_infra
    Building prodsinatrastack infrastructure...
    .....
    Waiting... this may take a while
    prodsinatrastack Created!
    Your Test URL is :
    http://prods-Appli-34BZII2L2DSX-594734399.ap-southeast-2.elb.amazonaws.com

  Browsing to that url should show you the "hello world" sinatra page... if not something has gone wrong
  or maybe your just too quick, the stack takes about 6.5 mins to come up.
  Have a look around the console, if you have enable ssh access via the SSHLocation variable you should be
  able to jump on the hosts to have a look at the servers... they should be exactly the same as
  test.... you'll need to fish the external IPs for the servers out of the AWS console.

  So what just happened ?
  -----------------------

    The cloudformation template provisioned an ELB pointing to an autoscalling server group.  The autoscalling
    group spins up at least 2 servers in the stack for HA locked down by a security group.
    I put as little as possible into the cloudformation template as far as operating system configuration,
    there is a small script in the user data section that does the following :

      - installs ansible
      - pulls the ansible code from the S3 bucket
      - runs ansible with the pulled code.
      - run cfn-init to complete the setup of the load balancing group

    For more details on what the ansible code does, check out the README.md in the ansbile folder.

  Okay time to clean up, these commands will decommission the cloudformation stacks we provisioned earlier :

  Delete test stack

    #> make delete_test_infra    
    Deleting testsinatrastack infrastructure...
    Waiting... this may take a while
    testsinatrastack Deleted!


  Delete production stack

    #> make delete_infra
    Deleting prodsinatrastack infrastructure...
    Waiting... this may take a while
    prodsinatrastack Deleted!


  And that's it!
