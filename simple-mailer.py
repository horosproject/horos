#!/usr/bin/env python

# simple-mailer by Peter Hosey
# https://bitbucket.org/boredzo/simple-mailer

# Usage: simple-mailer [--[no-]tls] username[:password]@server[:port] from to subject

import optparse
parser = optparse.OptionParser(usage='%prog [options] username[:password]@server[:port] from to subject', description='Sends an email message, reading the password (unless specified on the command line) and body from standard input. The server and port are those of the SMTP server you want to use, and the username is the one you want to log in to that server with.\n' 'Putting the password on the command line is not recommended, as that makes it visible to other processes.')
parser.add_option('--tls', action='store_true', default=True, help='Enable TLS (default)')
parser.add_option('--no-tls', action='store_false', dest='tls', help='Disable TLS')
parser.add_option('--user-agent', default=None, help='Set the User-Agent string')

import sys
opts, args = parser.parse_args()

try:
	hostspec, from_addr, to_addr, subject = args
except ValueError:
	parser.print_help()
	sys.exit(0)

u_p, s_p = hostspec.rsplit('@', 1)
try:
	username, password = u_p.split(':')
except ValueError:
	username = u_p
	import getpass
	password = getpass.getpass() if sys.stdin.isatty() else sys.stdin.readline().rstrip('\n')
else:
	print >>sys.stderr, 'warning: including the password on the command line is insecure (it will show up in ps)'
try:
	hostname, portstr = s_p.split(':')
except ValueError:
	hostname = s_p
	port = 587 if opts.tls else 25
else:
	port = int(portstr)

major, minor, incremental, type, iteration = sys.version_info
python_version = '.'.join(map(str, [major, minor, incremental]))
user_agent_product_tokens = ['simple-mailer/1.0', 'python-smtplib/' + python_version]
if opts.user_agent:
	if '/' not in opts.user_agent:
		# SMTP doesn't really define the User-Agent header, which is why this is a soft warning and not a hard error.
		print >>sys.stderr, 'warning: user-agent product token "%s" is not a valid product token, at least by the HTTP definition' % (opts.user_agent,)
	user_agent_product_tokens.insert(0, opts.user_agent)

import smtplib
smtp = smtplib.SMTP(hostname, port)
smtp.ehlo()
if opts.tls:
	smtp.starttls()
	smtp.ehlo()
smtp.login(username, password)
del password

msg_lines = []
msg_lines.append('From: ' + from_addr + '\r\n')
msg_lines.append('To: ' + to_addr + '\r\n')
msg_lines.append('Subject: ' + subject + '\r\n')
msg_lines.append('User-Agent: ' + ' '.join(user_agent_product_tokens) + '\r\n')
msg_lines.append('\r\n')
msg_lines += (line.rstrip('\r\n') + '\r\n' for line in sys.stdin)
smtp.sendmail(from_addr, [to_addr], ''.join(msg_lines))
smtp.quit()
