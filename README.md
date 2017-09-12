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


Basic design :

    I didn't use Docker/containers as part of this submission but there would have been advantages if I did. eg:
    Bundling up all the Ruby dependencies in a container, but I wanted to limit the tooling as much as possible..
    so running sinatra on the VM seemed a leaner approach.

    I have 1 test Cloud Formation script : cloudformation\EC2instance.json which is just single host wrapped up in a
    security group. I used that to test the infra code on.

    The Cloud Formation setup for "production" uses an ELB and an auto-scaling group with some limits how many hosts
    it can scale too.  


    The design is relatively simple, and a quick way to deploy the sinatra app to the internet, since the app itself
    was quiet basic there weren't too many dependencies.  I decided that a simple config as illustrated would be
    sufficient.
    I tier design with a loadbalancer in front  This represents a classic DMZ design.  However if there were DBs in
    the picture the result would have been quiet different, involving at least another network layer below this one,
    for the DBs to be hosted in.

    The Autoscalling group is enough to scale the application (by default build on t2.small hosts) and since there is
    no state, a simple round robin policy ( the default ) is fine, again if state or connection persistency was an
    issue the design would have involved a different LB configuration.

    The hosts themselves are running firewalld to limit their exposure, I think that more could be done here to improve
    security, for example running the CIS security benchmark on the server to ensure better hardening.

    So how does the app get on the server ? ... The ansbile code is first tested on the test stack, once it succeeds the
    code can then be transferred to an S3 bucket ready for deployment on the production host.

    I don't have a pipe line for the, but the make files could be used for such a purpose. Also there are no server spec
    test here. But I believe they could be applied to this model I have created as aswell as kicking of e2e test via the
    test stack.

    To get the code on the the production server at deploy time, I have placed a small script within the userdata  of
    the instance config on the production cloudformation template, I tired to keep this script as small as possible and
    have most of the infrastructure code within Ansible. At provision time the hosts will pull the code from s3 and apply
    it to themselves.

    Code updates can be applied directly to the hosts again, but I would recommend instance rebuilds over reapplying the
     Anisble over the top.... That about sums it up, there is more information about in the steps below that will give
     you more context on how it works.

  Let's get started.
  =================

  Prerequisites:

  Deployment can happen from any Linux hosting or equivalent (CentOS is preferred) provided you have the following
  prerequisites:
   - Connection to the internet

   - These Packages:.
      Make, jq, python, pypthon-pip, awscli, ansible (for local tests), SSH, bash


  Getting Set Up
  ================
  Install and configure the awscli:  (for details on installing the awscli, look in the awscli folder)
  ---------------------------------

  Configure the AWS cli with the provided access keys.

  #> aws configure

    AWS Access Key ID:
    AWS Secret Access Key:
    Default region name:   ap-southeast-2
    Default output format: json

  Setup your server access key (filename : rea_access_key.pem contained in the submission email)
  ----------------------------

  To access the AWS hosts you will need a copy of the server access key.  The default location for this is in your
  homedir.( ~ )  
  You can modify the default path via editing AWS_SERVER_SSH_KEY_FILE variable directly within the make file.


  Clone the repo
  --------------
  Assuming you have install the above, just clone this repo to get started

  Git clone http....

  All builds are executed via make.

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
  CF_TEST_TEMPLATE          # test Cloudformation template
  CF_TEMPLATE               # production cloudformation template
  STACK_NAME                # prod stack name
  TEST_STACK_NAME           # test stack name
  Subnets_2a                # predified subnets in the aws account
  Subnets_2b                # predified subnets in the aws account
  VpcId                     # predified Vpc in the aws account
  ansible_user              # the CentOS default user, use by ansible
  S3_bucket=a               # s3 bucket location where we deploy the ansible code too for production.


  For our example the AWS Vpc and subnets have already been defined and defaulted above no need to change them for the
  given account.


  Let's start building!
  ---------------------

  Okay now for the fun stuff: First let's build our test stacks to test the Ansible infra code.

  #> make build_test_infra
  Building testsinatrastack infrastructure...
  .....
  Waiting... this may take a while
  testsinatrastack Created!
  Your Test URL is :
  ec2-54-252-173-67.ap-southeast-2.compute.amazonaws.com

    Assuming you have set both HTTPLocation and SSHLocation to your network location you can use the url above to access
    the server.  There wont be anything on the http endpoint until you deploy the Ansible code so the url wont work in a
    browser.  However you can use to access the machine via ssh using the supplied pem key, but its just a plain CentOS
    image at the moment.

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
    execute it.  Check the results... browse to http://ec2-54-252-173-67.ap-southeast-2.compute.amazonaws.com If all
    is okay you can upload the code to the S3 bucket for production deployments.  ^thats not the real url

    NOTE: I copy the code to the host rather than using the Ansible locally to push the code, because I was experiencing
    some intermit internet issues and it seem to apply very slowly over the remote connection.
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
    able to jump on the hosts to have a look at the server configuration... should be exactly the same as
    test.... you'll need to fish the external IPs for the servers out of the aws console.

    So what just happened ?
    -----------------------

      The cloudformation template provisioned an ELB pointing to an autoscalling server group.  The autoscalling
      group spins up at least 2 servers in the stack for HA locked down by a security group.
      I put as little as possible into the cloudformation template as far as operating system configuration,
      there is a small script in the user data section that basically :

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
