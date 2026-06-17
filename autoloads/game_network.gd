extends Node

signal on_load_scene

const GAME_PORT := 13020
const SEARCH_PORT := 13019
var peer: ENetMultiplayerPeer

func get_private_ip() -> String:
	
	var ips := IP.get_local_addresses()
	
	for ip in ips:
		
		if ip.begins_with("192.168.") or ip.begins_with("10."):
			return ip
	
	return ""

##Create server that listens to connections via port. The port needs to be an available, unused port between 0 and 65535. Note that ports below 1024 are privileged and may require elevated permissions depending on the platform. To change the interface the server listens on, use set_bind_ip(). The default IP is the wildcard "*", which listens on all available interfaces. max_clients is the maximum number of clients that are allowed at once, any number up to 4095 may be used, although the achievable number of simultaneous clients may be far lower and depends on the application. For additional details on the bandwidth parameters, see create_client(). Returns OK if a server was created, ERR_ALREADY_IN_USE if this ENetMultiplayerPeer instance already has an open connection (in which case you need to call MultiplayerPeer.close() first) or ERR_CANT_CREATE if the server could not be created.
func create_server(
	max_clients := 32,
	max_channels := 0,
	in_bandwidth := 0,
	out_bandwidth := 0
) -> ENetMultiplayerPeer:
	
	peer = ENetMultiplayerPeer.new()
	peer.create_server(GAME_PORT, max_clients, max_channels, in_bandwidth, out_bandwidth)
	multiplayer.multiplayer_peer = peer
	
	return peer

##Create client that connects to a server at address using specified port. The given address needs to be either a fully qualified domain name (e.g. "www.example.com") or an IP address in IPv4 or IPv6 format (e.g. "192.168.1.1"). The port is the port the server is listening on. The channel_count parameter can be used to specify the number of ENet channels allocated for the connection. The in_bandwidth and out_bandwidth parameters can be used to limit the incoming and outgoing bandwidth to the given number of bytes per second. The default of 0 means unlimited bandwidth. Note that ENet will strategically drop packets on specific sides of a connection between peers to ensure the peer's bandwidth is not overwhelmed. The bandwidth parameters also determine the window size of a connection which limits the amount of reliable packets that may be in transit at any given time. Returns OK if a client was created, ERR_ALREADY_IN_USE if this ENetMultiplayerPeer instance already has an open connection (in which case you need to call MultiplayerPeer.close() first) or ERR_CANT_CREATE if the client could not be created. If local_port is specified, the client will also listen to the given port; this is useful for some NAT traversal techniques.
func create_client(
	address: String,
	channel_count := 0,
	in_bandwidth := 0,
	out_bandwidth := 0,
	local_port := 0
) -> ENetMultiplayerPeer:
	
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, GAME_PORT, channel_count, in_bandwidth, out_bandwidth, local_port)
	multiplayer.multiplayer_peer = peer
	
	return peer

func close() -> Error:
	
	if not peer:
		return Error.FAILED
	
	peer.close()
	return Error.OK

func search_clients_udp(address := "255.255.255.255") -> PacketPeerUDP:
	
	var broadcaster := PacketPeerUDP.new()
	broadcaster.set_broadcast_enabled(true)
	broadcaster.set_dest_address(address, SEARCH_PORT)
	
	return broadcaster

func get_listener() -> PacketPeerUDP:
	
	var listener := PacketPeerUDP.new()
	var error := listener.bind(SEARCH_PORT)
	
	if error != Error.OK:
		return null
	
	return listener

@rpc("authority", "reliable")
func _change_client_scene_file(scene: StringName) -> void:
	
	await get_tree().process_frame
	
	get_tree().change_scene_to_file(scene)

	await get_tree().process_frame
	
	on_load_scene.emit()
