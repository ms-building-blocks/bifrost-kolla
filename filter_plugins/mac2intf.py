def nodes_as_dict(nodes):
    """Convert nodes list to dict indexed on nodes name

    Args:
        nodes: the nodes list

    Returns:
        dictionnary of nodes
    """
    return {n['name']: n for n in nodes}


def get_bridges(inventory_hostname, hostvars, network_profiles, nodes):
    """Get the bridges needed for a node within its profile

    Args:
        inventory_hostname: the node name
        hostvars: the ansible hostvars of the node
        network_profiles: the network_profiles associating brige name to
            server group
        nodes: a dict of nodes

    Returns:
        list of bridges on the node
    """
    br = []
    for node_type in nodes[hostvars[inventory_hostname]['ansible_hostname']]:
        br.extend(x for x in network_profiles[node_type] if x not in br)
    return br


def target_interfaces(inventory_hostname, hostvars, servers):
    """Get the macs used on the node

    Args:
        inventory_hostname: the node name
        hostvars: the ansible hostvars of the node
        servers: the servers list

    Returns:
        list of macs of interfaces plugged on the node
    """
    return [i['mac'] for i in servers[hostvars[inventory_hostname][
        'ansible_hostname']]['interfaces']]


def mac2intf(inventory_hostname, hostvars, servers):
    """Get the mac associate to the interface name

    Args:
        inventory_hostname: the node name
        hostvars: the ansible hostvars of the node
        servers: the servers list

    Returns:
        list of macs of interfaces plugged on the node, linked with the
        interfaces name
    """
    intf_list = hostvars[inventory_hostname]['ansible_interfaces']
    target_interfaces = [i['mac'] for i in servers[hostvars[
        inventory_hostname]['ansible_hostname']]['interfaces']]
    macs = {}
    for intf in intf_list:
        # only recover phsical interfaces
        if (intf.startswith('en') or intf.startswith('eth')) and \
                '.' not in intf:
            mac = hostvars[inventory_hostname]["ansible_{}".format(intf)
                                               ]['macaddress']
            if mac in target_interfaces:
                macs[mac] = intf
    return macs


class FilterModule(object):
    '''
    Functions linked to node network interfaces
    '''

    def filters(self):
        return {
            'nodes_as_dict': nodes_as_dict,
            'get_bridges': get_bridges,
            'target_interfaces': target_interfaces,
            'mac2intf': mac2intf,
        }
