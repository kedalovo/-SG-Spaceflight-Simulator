extends Node3D


class_name Station


signal warp_to(to_station: NodePath)


func request_warp(to_station: NodePath) -> void:
	warp_to.emit(to_station)
