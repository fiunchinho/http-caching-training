# HTTP Caching
This is a training to learn the basics of HTTP Caching. In this training we cover three different layers of HTTP Caching:
- Browser Caching
- Proxy Caching using **Amazon CloudFront**
- Gateway Caching using **Varnish**

Navigate to the different folders to find out more.

## Deployment
If you want to deploy the content of this repository to an EC2 instance to test the caching mechanisms, like CloudFront, follow these simple steps.
Go to the AWS Console and start a new EC2 micro instance. Choose the default VPC. To be able to later access the machine, create a new pair of SSH keys or choose an already existing pair. Wait for it to be available.

While this happens, install [Ansible](https://docs.ansible.com/ansible/) and [Ansistrano](https://github.com/ansistrano/deploy) on your Vagrant

```bash
$ sudo easy_install pip
$ sudo pip install ansible
$ ansible-galaxy install carlosbuenosvinos.ansistrano-deploy carlosbuenosvinos.ansistrano-rollback
```

The EC2 instance should be available now. Go to the AWS Console and then to Security Groups. Choose the security group that you are using for the instance and allow all traffic from the internet to the machine. This is insecure but it's just for this training.
Try sshing into the machine selecting your pem key. Choose the key that you selected while creating the instance. Remember that for Ubuntu instances, the SSH user is `ubuntu`.

```bash
$ ssh -i $HOME/.ssh/personal.pem ubuntu@52.123.456.78
```

Edit the `deploy.yml` and `rollback` files, mainly updating the `ansistrano_deploy_to` variable. This is the path where your application will be deployed.
There is an `infrastructure.yml` that makes sure that your server has php and apache installed, which is executed every time we deploy.

Finally, execute Ansible to deploy

```bash
$ ansible-playbook --private-key $HOME/.ssh/personal.pem -u ubuntu -i 52.48.238.88, deploy.yml
```

Try to deploy several times and watch the `releases` folder grow. Where is the current folder pointing to? What happens when you execute the `rollback.yml` playbook?