# LXC-to-GO [![Build Status](https://travis-ci.org/plitc/lxc-to-go.svg?branch=master)](https://travis-ci.org/plitc/lxc-to-go)

Example
=======
* bootstrap

```
    # ./lxc-to-go.sh bootstrap

        Stage 1 finished. Please Reboot your System immediately! and continue the bootstrap

    # ./lxc-to-go.sh bootstrap

    ### lxc-attach -n managed (or screen attach) ###

    lxc-to-go bootstrap finished.
```

* start

```
    # ./lxc-to-go.sh start
    FOUND:
    test1 test2 test3 test4 test5

    ... LXC Container (screen sessions): ...
        14608.test1     (04/22/15 10:19:39)     (Detached)
        14887.test2     (04/22/15 10:19:44)     (Detached)
        15147.test3     (04/22/15 10:19:49)     (Detached)
        15409.test4     (04/22/15 10:19:54)     (Detached)
        15671.test5     (04/22/15 10:19:59)     (Detached)

    lxc-to-go start finished.
```

* stop

```
    # ./lxc-to-go.sh stop
    FOUND (active):
    test1 test2 test3 test4 test5

    lxc-to-go stop finished.
```

* shutdown

```
    # ./lxc-to-go.sh shutdown


    lxc-to-go shutdown finished.
```

* create

```
    # ./lxc-to-go.sh create
    Please enter the new LXC Container name:
    test

    Choose the LXC template:
    1) wheezy
    2) jessie
    1
    select: wheezy
    Created container test as copy of deb7template

    Do you wish to start this LXC Container: test ? (y/n) y

    ... starting screen session ...
        3898.test        (04/22/15 08:03:34)     (Detached)

    Do you wanna use 'flavor hooks' ? (y/n) y

    ... please wait 15 seconds ...


    <--- --- --- flavor hooks // --- --- --->
    example
    <--- --- --- // flavor hooks --- --- --->

    lxc-to-go create finished.
```

* delete

```
    # ./lxc-to-go.sh delete
    test test1 test2

    Please enter the LXC Container name to DESTROY:
    test

    ... shutdown & delete the lxc container ...

    lxc-to-go delete finished.
```

* provisioning

```
    # ./lxc-to-go_provisioning.sh -n test3 -t deb8 -h yes -p 60003 -s yes
    Created container test3 as copy of deb8template

    ... starting screen session ...
          6743.test3     (04/24/15 00:48:53)    (Detached)


    ... please wait 15 seconds ...


    <--- --- --- provisioning hooks // --- --- --->
    example
    <--- --- --- // provisioning hooks --- --- --->


    lxc-to-go provisioning finished.
```

* show

```
    # ./lxc-to-go.sh show
    NAME          STATE    IPV4                              IPV6                                    AUTOSTART  PID    MEMORY    RAM       SWAP
    ---------------------------------------------------------------------------------------------------------------------------------------------
    managed       RUNNING  192.168.253.254, 192.168.254.254  fd00:aaaa:253::254, fd00:aaaa:254::254  NO         1124   8.16MB    8.16MB    0.0MB
    test1         RUNNING  192.168.254.126                   fd00:aaaa:254:0:aaa:1                   NO         10639  3.7MB     3.68MB    0.02MB
    test2         RUNNING  192.168.254.125                   fd00:aaaa:254:0:aaa:2                   NO         8309   4.05MB    4.04MB    0.01MB
    test3         STOPPED  -                                 -                                       NO         -      -         -         -
```

* login

```
    [DIALOG]
```

* lxc-in-lxc-webpanel

```
    LXC-Web-Panel:   http://192.168.253.254:5000
    Username:        admin
    Password:        admin
    default gateway: 192.168.252.254 (for the lxc-inside-lxc containers)
```

