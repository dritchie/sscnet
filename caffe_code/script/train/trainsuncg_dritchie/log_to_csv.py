import re


logfile = open('log.txt', 'r')
log = logfile.read()
logfile.close()

p = re.compile('Iteration \d+, loss = (\d+\.\d+)')
loss_strs = p.findall(log)
loss_vals = [float(s) for s in loss_strs]

csvfile = open('loss.csv', 'w')
csvfile.write('iteration,loss\n')
for i in range(len(loss_vals)):
	loss = loss_vals[i]
	csvfile.write('{},{}\n'.format(i,loss))
csvfile.close()