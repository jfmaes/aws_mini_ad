# aws_mini_ad
An Infrastructure as code proof of concept to deploy a bare minimum AD environment in AWS.


The infrastructure is built with terraform and ansible and is divided into a production and dev environment. 
The dev environment starts from bare bones clean windows AMI base images and require ansible to provision the environment. a sample playbook is provided. 
The prod environment spins up a preprovisioned (snapshotted) range that was provisioned with the ansible playbooks in the dev folder. 
Several helper scripts are also available to create snapshots yourself, make AMI's public and duplicate them accross regions. 


To spin up the AWS AD environment you can use 

```Python
python3 manager.py deploy -r <your region> -t <your version tag>
```

At this point in time the following regions are supported:
us-east-1,us-west-1,eu-west-1 

The current version tag is v0.1


There is a walkthrough with some demonstration attack paths in this range using Empire available here: <br>
https://logout.gitbook.io/ad-privesc-with-empire


The lab environment consists of three domains:

- sandbox.pwnzone.lab
- pwnzone.lab
- treasureisland.lab 

There is 1 workstation in the domain:

- ws01.sandbox.pwnzone.lab

The 3 domaincontrollers are:

- sandbox-dc01.sandbox.pwnzone.lab
- pwnzone-dc01.pwnzone.lab
- treasure-dc01.treasureisland.lab

There is a bastion host that will provide an openvpn file to connect into the environment. This is the only entry point into the environment as non of the other systems are provisioned with a public IP address in AWS. 

An overview of credentials can be found in the files directory of the dev folder. 
