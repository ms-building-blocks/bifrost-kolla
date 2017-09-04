import struct
import socket
import ipaddress


def ip2int(ipstr):
    return struct.unpack('!I', socket.inet_aton(ipstr))[0]


def int2ip(n):
    return socket.inet_ntoa(struct.pack('!I', n))


def ipadd(ip, add):
    return int2ip(int(ipaddress.ip_address(ip2int(ip))+add))


def get_nodes_names(nodes):
    return sorted(node['name'] for node in nodes)


def node_ips(nodes, netw, shift):
    nodes_ips = {}
    index = 1
    for srv_name in get_nodes_names(nodes):
        nodes_ips[srv_name] = {'ip': ipadd(netw, shift + index),
                               'index': index}
        index += 1
    return nodes_ips


def job2nodes(nodes):
    jobs = {'controller': [],
            'compute': [],
            'storage': [],
            'network': []}
    for srv in sorted(nodes, key=lambda node: node['name']):
        for funct in srv['functions']:
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
