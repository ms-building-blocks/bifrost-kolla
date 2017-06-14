#!/bin/sh

rm ~/.ssh/known_hosts
for node in node0 node1 node2 node3 node4; do
    gw=$(ip r l | grep default | cut -d \  -f3)
    ssh $node "ip r d default && ip r a default via $gw"
    scp prepare_target.sh $node:
    scp net-config.yaml $node:
    scp osa.cfg $node:
    scp generate_netconfig.py $node:
    echo
    echo ###########################
    echo prepare $node
    echo ###########################
    ssh $node ./prepare_target.sh
    ssh $node "rm /etc/network/interfaces.d/*"
    ssh $node "./generate_netconfig.py"
    # ssh $node "service networking restart"
done
