docker-haproxy
==============

Docker image for haproxy that uses serf (http://serfdom.io) to discover web server containers.

## Getting things going

First, build it:

            sudo docker build -t democracyworks/haproxy-serf .

To actually use it you'll need someone to start a serf cluster. 
For this I recommend using the image `ctlc/serf` from the docker registry. 
You can also build it yourself if you prefer from https://github.com/CenturyLinkLabs/docker-serf.

Start a serf cluster using:

            sudo docker run -d -name serf_1 -p 7946 -p 7373 ctlc/serf
            
Now you just need to start haproxy:

            sudo docker run -P -t -i -v /my/config:/config -link serf_1:serf_1 haproxy-serf
            
This will start a docker container running a serf agent that will connect to the cluster provided
by serf_1 and a haproxy instance with no registered servers. Servers are added to haproxy by serf.
Whenever a node with the role `xweb` joins the cluster, the serf handler will add it to the list
of available servers. Likewise, whenever an `xweb` node leaves (or fails out of) the cluster, the serf
handler will remove it from the haproxy server list.

So, supposing you had a docker container with a webserver running on port 8080
and serf agent connecting to serf_1 (just like this container), you could add it to the pool with

            sudo docker run -P -link serf_1:serf_1 -d my-web-server
            
The haproxy container will update it's haproxy.conf, restart itself, and start serving up content.
The haproxy container will use the IP address associated with the serf node and the port specified
in the `port` tag on the node. Add/remove new `my-web-server` containers at will and it all just works.

## Config

The first thing the serf handler does is load a file at `/config/config.lisp`. You can use this to plug in your
own configuration at docker run time. From my example above, I mounted `/my/config` to load a custom config.
One way to use this is to change the role that our serf handler is listening for. For example:
```lisp
(defvar *web-role* "payment-api")
```
would make the haproxy container only add nodes with the role `payment-api` to its server pool. With this you 
can run multiple haproxy containers for balancing different service endpoints all on the same serf cluster.
