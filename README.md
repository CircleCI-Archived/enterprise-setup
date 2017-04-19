# enterprise-setup
Installation resources for CircleCI Enterprise
import threading
from IPython.display import display
import ipywidgets as widgets
import time
def get_ioloop():
import IPython, zmq
ipython = IPython.get_ipython()
if ipython and hasattr(ipython,
'kernel'):
return zmq.eventloop.ioloop.IOLoop.instance()
ioloop = get_ioloop()
thread_safe = True
def work():
for i in range(10):
def update_progress(i=i):
print "calling from thread"
, threading.currentThread()
progress.value = (i+1)/10.
print i
time.sleep(0.5)
if thread_safe:
get_ioloop().add_callback(update_progress)
else:
update_progress()
print "we are in thread"
, threading.currentThread()
thread = threading.Thread(target=work)
progress = widgets.FloatProgress(value=0.0, min=0.0, max=1.0, step=0.01)
display(progress)
thread.start()
