import struct
import socket
import ipaddress


def ip2packed(ipstr):
    """Convert an IPv4 address from dotted-quad string
    (for example, '123.45.67.89') to 32-bit packed binary format, as a string
    four characters in length.

    Args:
        ipstr: IP as a dotted string

    Returns:
        a packed ip
    """
    return struct.unpack('!I', socket.inet_aton(ipstr))[0]


def packed2ip(n):
    """Convert a 32-bit packed IPv4 address (a string four characters in length)
    to its standard dotted-quad string representation
    (for example, '123.45.67.89').

    Args:
        n: IP as an int

    Returns:
        ip as a dotted string
    """
    return socket.inet_ntoa(struct.pack('!I', n))


def ipadd(ip, add):
    """Increment an dotted string ip with a value

    Args:
        ip: IP as a dotted string
        add: the increment value

    Returns:
        IP as a dotted string
    """
    return packed2ip(int(ipaddress.ip_address(ip2packed(ip))+add))


def get_nodes_names(nodes):
    """Get a sorted list of nodes names

    Args:
        nodes: nodes list from PDF

    Returns:
        A sorted list of hosts names
    """
    return sorted(node['name'] for node in nodes)


def node_ips(nodes, netw, shift):
    """Get a dictionnary containing the main ip of a node, and the index of
    this node in the list

    Args:
        nodes: nodes list from PDF
        network: the network of the main ip
        shift: the increment to apply to the network for all ips

    Returns:
        { <node_name>: { 'ip': <nodeip>, 'index': <index of the node>}}
    """
    nodes_ips = {}
    for index, srv_name in enumerate(get_nodes_names(nodes)):
        nodes_ips[srv_name] = {'ip': ipadd(netw, shift+index+1),
                               'index': index+1}
    return nodes_ips


def job2nodes(nodes):
    """Get a dictionnary containing nodes associate to a function

    Args:
        nodes: nodes list from PDF

    Returns:
        {'controller': [], 'compute': [], 'storage': [], 'network': []...}
    """
    jobs = {}
    for srv in sorted(nodes, key=lambda node: node['name']):
        for funct in srv['functions']:
            if funct not in jobs.keys():
                jobs[funct] = []
            jobs[funct].append(srv['name'])
    return jobs


class FilterModule(object):
    '''
    Functions linked to node network interfaces
    '''

    def filters(self):
        return {
            'ipadd': ipadd,
            'node_ips': node_ips,
            'job2nodes': job2nodes,
        }
