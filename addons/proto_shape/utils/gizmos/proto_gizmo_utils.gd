var gizmo_ids_given = 0

# Generates a list of unique gizmo ids
func generate_gizmo_ids(number_of_gizmos: int) -> Array[int]:
    var gizmo_ids = []
    for i in range(number_of_gizmos):
        gizmo_ids.append(gizmo_ids_given)
        gizmo_ids_given += 1
    return gizmo_ids
