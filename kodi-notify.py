#!/usr/bin/python
import sys, os
import getopt
from socket import *
try:
    from kodi.xbmcclient import *
except:
    sys.path.append(os.path.join(os.path.realpath(os.path.dirname(__file__)), '../../lib/python'))
    from xbmcclient import *

def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "?pa:v", ["hosts=", "port=", "msg="])
    except getopt.GetoptError, err:
        print str(err)
        sys.exit(2)

    ips = []
    port = 9777
    actions = []
    verbose = False
    for o, a in opts:
        if o in ("-?", "--help"):	
            sys.exit()
        elif o == "--host":
            ips.append(a)
	elif o == "--hosts":
	    ips = a.split(",")
            #ips.append(a)
        elif o == "--port":
            port = int(a)
        elif o in ("--msg"):
	    print a
            actions.append("Notification(" + a + ",5000)")
        else:
            assert False, "unhandled option"
    
    
    sock = socket(AF_INET,SOCK_DGRAM)
    
    if len(actions) is 0:
        sys.exit(0)
    for ip in ips:
       addr = (ip, port)
       for action in actions:
		#print 'Sending action:', action
        	packet = PacketACTION(actionmessage=action, actiontype=ACTION_BUTTON)
        	packet.send(sock, addr)

if __name__=="__main__":
    main()
