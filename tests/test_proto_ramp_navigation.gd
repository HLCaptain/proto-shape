extends SceneTree

const EXAMPLE := "res://addons/proto_shape/proto_ramp/example/proto_ramp_example.tscn"

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var example: Node = load(EXAMPLE).instantiate()
	root.add_child(example)
	await process_frame

	var region := example.get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	_expect(region != null, "Ramp example must retain its NavigationRegion3D")
	if region != null:
		_expect(region.navigation_mesh != null, "NavigationRegion3D must retain its NavigationMesh resource")
		if region.navigation_mesh != null:
			_expect(region.navigation_mesh.get_vertices().is_empty(), "Example NavigationMesh must remain intentionally unbaked")
			_expect(region.navigation_mesh.get_polygon_count() == 0, "Example NavigationMesh must not ship stale polygons")

		var ramp = region.get_node_or_null("ProtoRamp")
		_expect(ramp != null, "NavigationRegion3D must retain the ProtoRamp source geometry")
		if ramp != null:
			_expect(ramp.collisions_enabled, "Example ramp must remain collision-enabled")
			_expect(ramp.shape_polygon != null and ramp.shape_polygon.use_collision, "Generated ramp geometry must be ready for collision and baking")

	_expect(_count_navigation_agents(example) == 0, "Collision sample must not imply agent navigation")
	example.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: ramp navigation setup")
	quit(1 if failures else 0)

func _count_navigation_agents(node: Node) -> int:
	var count := 1 if node is NavigationAgent3D else 0
	for child in node.get_children():
		count += _count_navigation_agents(child)
	return count

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
