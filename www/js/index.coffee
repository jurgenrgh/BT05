# Copyright 2016 Franco Bugnano
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

'use strict'

app = {}
window.app = app

if window.TextEncoder
	textEncoder = new TextEncoder('utf-8')
	textDecoder = new TextDecoder('utf-8')

	app.StringFromArrayBuffer = (buf) ->
		return textDecoder.decode(new Uint8Array(buf))

	app.ArrayBufferFromString = (str) ->
		return textEncoder.encode(str).buffer
else
	app.StringFromArrayBuffer = (buf) ->
		return String.fromCharCode.apply(null, new Uint8Array(buf))

	app.ArrayBufferFromString = (str) ->
		strLen = str.length
		buf = new ArrayBuffer(strLen)
		bufView = new Uint8Array(buf)

		for i in [0...strLen] by 1
			bufView[i] = str.charCodeAt(i)

		return buf

# Bind any events that are required on startup. Common events are:
# 'load', 'deviceready', 'offline', and 'online'.
document.addEventListener('deviceready', () ->
	domIds = [
		'adapterEvent'
		'adapterAddress'
		'adapterName'
		'adapterEnabled'
		'adapterDiscovering'
		'adapterDiscoverable'
		'deviceAddress'
		'deviceName'
		'devicePaired'
		'deviceUuids'
		'receiveErrorCount'
		'receiveErrorSocketId'
		'receiveErrorMessage'
		'acceptErrorCount'
		'acceptErrorSocketId'
		'acceptErrorMessage'
		'createSocketId'
		'clientSocketId'
		'connected'
		'txCount'
		'rxCount'
		'rxDataLen'
		'rxData'
		'pingTime'
	]

	dom = {}
	for id in domIds
		dom[id] = document.getElementById(id)

	# Adapter state
	onAdapterStateChangedCounter = 0

	networking.bluetooth.getAdapterState((adapter) ->
		dom.adapterEvent.innerHTML = 'getAdapterState'
		dom.adapterAddress.innerHTML = String(adapter.address)
		dom.adapterName.innerHTML = String(adapter.name)
		dom.adapterEnabled.innerHTML = String(adapter.enabled)
		dom.adapterDiscovering.innerHTML = String(adapter.discovering)
		dom.adapterDiscoverable.innerHTML = String(adapter.discoverable)
		return
	)

	networking.bluetooth.onAdapterStateChanged.addListener((adapter) ->
		onAdapterStateChangedCounter += 1
		dom.adapterEvent.innerHTML = ['onAdapterStateChanged', String(onAdapterStateChangedCounter)].join(' ')
		dom.adapterAddress.innerHTML = String(adapter.address)
		dom.adapterName.innerHTML = String(adapter.name)
		dom.adapterEnabled.innerHTML = String(adapter.enabled)
		dom.adapterDiscovering.innerHTML = String(adapter.discovering)
		dom.adapterDiscoverable.innerHTML = String(adapter.discoverable)
		return
	)

	# Devices
	app.nextID = 0
	app.devices = {}
	app.selectedDevice = null

	app.showDeviceInfo = (e) ->
		btn = e.target
		id = btn.getAttribute('id')
		device = app.devices[id]
		app.selectedDevice = device

		dom.deviceAddress.innerHTML = String(device.address)
		dom.deviceName.innerHTML = String(device.name)
		dom.devicePaired.innerHTML = String(device.paired)
		dom.deviceUuids.innerHTML = String(device.uuids)
		return

	lstKnownDevs = document.getElementById('lstKnownDevs')
	networking.bluetooth.getDevices((devices) ->
		for device in devices
			btn = document.createElement('button')
			btn.setAttribute('type', 'button')
			btn.classList.add('list-group-item')
			id = ['btDev', String(app.nextID)].join('')
			btn.setAttribute('id', id)
			btn.innerHTML = [String(device.address), String(device.name)].join(' ')
			lstKnownDevs.appendChild(btn)
			btn.addEventListener('click', app.showDeviceInfo)
			app.nextID += 1
			app.devices[id] = device

		return
	)

	btnRequestDiscoverable = document.getElementById('btnRequestDiscoverable')
	btnRequestDiscoverable.addEventListener('click', () ->
		networking.bluetooth.requestDiscoverable()
		return
	)

	lstDiscoveredDevs = document.getElementById('lstDiscoveredDevs')
	networking.bluetooth.onDeviceAdded.addListener((device) ->
		btn = document.createElement('button')
		btn.setAttribute('type', 'button')
		btn.classList.add('list-group-item')
		id = ['btDev', String(app.nextID)].join('')
		btn.setAttribute('id', id)
		btn.innerHTML = [String(device.address), String(device.name)].join(' ')
		lstDiscoveredDevs.appendChild(btn)
		btn.addEventListener('click', app.showDeviceInfo)
		app.nextID += 1
		app.devices[id] = device
		return
	)

	btnStartDiscovery = document.getElementById('btnStartDiscovery')
	btnStartDiscovery.addEventListener('click', () ->
		networking.bluetooth.startDiscovery()
		return
	)

	btnStopDiscovery = document.getElementById('btnStopDiscovery')
	btnStopDiscovery.addEventListener('click', () ->
		networking.bluetooth.stopDiscovery()
		return
	)

	# Socket
	btnListen = document.getElementById('btnListen')
	btnConnect = document.getElementById('btnConnect')
	btnPing = document.getElementById('btnPing')

	app.receive_error_count = 0
	app.accept_error_count = 0
	app.tx_count = 0
	app.rx_count = 0
	app.socketId = null
	app.clientSocketId = null
	app.uuid = '94f39d29-7d6d-437d-973b-fba39e49d4ee'
	app.listening = false
	app.connected = false
	app.pingStr = 'Hello, world\n'
	app.pongStr = 'Goodbye, world\n'
	app.pingData = app.ArrayBufferFromString(app.pingStr)
	app.pongData = app.ArrayBufferFromString(app.pongStr)
	app.startTime = performance.now()

	dom.connected.innerHTML = String(app.connected)

	networking.bluetooth.onReceiveError.addListener((errorInfo) ->
		console.log(errorInfo)

		app.receive_error_count += 1

		dom.receiveErrorCount.innerHTML = String(app.receive_error_count)
		dom.receiveErrorSocketId.innerHTML = String(errorInfo.socketId)
		dom.receiveErrorMessage.innerHTML = String(errorInfo.errorMessage)

		return
	)

	networking.bluetooth.onAcceptError.addListener((errorInfo) ->
		console.log(errorInfo)

		app.accept_error_count += 1

		dom.acceptErrorCount.innerHTML = String(app.accept_error_count)
		dom.acceptErrorSocketId.innerHTML = String(errorInfo.socketId)
		dom.acceptErrorMessage.innerHTML = String(errorInfo.errorMessage)

		return
	)

	btnListen.addEventListener('click', () ->
		if not app.listening
			networking.bluetooth.listenUsingRfcomm(app.uuid, (socketId) ->
				app.socketId = socketId
				dom.createSocketId.innerHTML = String(socketId)

				app.listening = true

				networking.bluetooth.onAccept.addListener((acceptInfo) ->
					if acceptInfo.socketId != app.socketId
						console.log('onAccept -- acceptInfo.socketId != app.socketId')
						return

					dom.clientSocketId.innerHTML = String(acceptInfo.clientSocketId)
					app.clientSocketId = acceptInfo.clientSocketId

					return
				)

				return
			, (errorMessage) ->
				console.error(errorMessage)
				dom.createSocketId.innerHTML = String("ERROR: #{errorMessage}")
				return
			)

		return
	)

	btnConnect.addEventListener('click', () ->
		if not app.connected
			device = app.selectedDevice
			networking.bluetooth.connect(device.address, app.uuid, (socketId) ->
				app.socketId = socketId
				dom.createSocketId.innerHTML = String(socketId)

				app.connected = true
				dom.connected.innerHTML = String(app.connected)

				return
			, (errorMessage) ->
				console.error(errorMessage)
				dom.createSocketId.innerHTML = String("ERROR: #{errorMessage}")
				return
			)

		return
	)

	btnPing.addEventListener('click', () ->
		if app.clientSocketId != null
			socket_id = app.clientSocketId
		else if app.connected
			socket_id = app.socketId
		else
			console.log('btnPing -- No socket ID')
			return

		app.tx_count += 1
		dom.txCount.innerHTML = String(app.tx_count)

		app.startTime = performance.now()
		networking.bluetooth.send(socket_id, app.pingData)

		return
	)

	networking.bluetooth.onReceive.addListener((receiveInfo) ->
		ping_time = performance.now() - app.startTime

		if app.clientSocketId != null
			socket_id = app.clientSocketId
		else if app.connected
			socket_id = app.socketId
		else
			console.log('onReceive -- No socket ID')
			return

		if receiveInfo.socketId != socket_id
			console.log('onReceive -- receiveInfo.socketId != socket_id')
			return

		data = app.StringFromArrayBuffer(receiveInfo.data)

		if data == app.pingStr
			networking.bluetooth.send(socket_id, app.pongData)
		else
			dom.pingTime.innerHTML = String(ping_time)

		app.rx_count += 1
		dom.rxCount.innerHTML = String(app.rx_count)
		dom.rxDataLen.innerHTML = String(data.length)
		dom.rxData.innerHTML = String(data)

		return
	)

	app.testHugeBuffer = () ->
		buf = new ArrayBuffer(4096)
		bufView = new Uint8Array(buf)

		for i in [0...bufView.length] by 1
			bufView[i] = 0x55

		if app.clientSocketId != null
			socket_id = app.clientSocketId
		else
			socket_id = app.socketId

		startTime = performance.now()
		networking.bluetooth.send(socket_id, buf, (num_byte) ->
			end_time = performance.now() - startTime
			console.log("success: #{num_byte}")
			console.log("end_time: #{end_time}")
		, (errorMessage) ->
			end_time = performance.now() - startTime
			console.log("error: #{errorMessage}")
			console.log("end_time: #{end_time}")
		)
		send_time = performance.now() - startTime

		console.log("send_time: #{send_time}")
		return
, false)

