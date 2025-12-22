extends Node3D


class_name Station


signal warp_to(to_station: NodePath)


@export_color_no_alpha var station_color: Color


func request_warp(to_station: NodePath, from_gate: WarpGate) -> void:
	warp_to.emit(to_station, from_gate)


func get_station_path(station: Station) -> String:
	var station_path: String = station.get_script().resource_path
	station_path = station_path.rstrip(".gd") + ".tscn"
	return station_path
