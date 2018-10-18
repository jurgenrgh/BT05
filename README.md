# B05 - Bluetooth Peer-to-Peer Communications
The intention was to link 4 android devices in a circular arrangement, where each device has
a right and a left neighbor, with whom it can exchange text information symmetrically.

It turns out that symmetric communication between 2 devices works essentially as described by Bugnano, the author of the cordova plugin. His sample works after some tweeking. However, chaining 3 or more devices fails in unpredictable ways, usually with the error message "invalid socket id".

There is an android bluetooth chat sample by Google:
https://github.com/googlesamples/android-BluetoothChat 
which also only deals with 2 participants.

The technical descriptions of Bluetooth PAN or "piconet" refer to an asymmetric structure, where one device is the server and the others are clients, though it is not clear what the constraints are that disallow e.g. a daisy chain of 3 devices while allowing 2.
