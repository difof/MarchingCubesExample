@tool
extends MeshInstance3D


@export var active_vertices = [false, false, false, false, true, true, true, true]:
    set(value):
        if len(value) == 8:
            active_vertices = value
            _draw_surface()

@export var show_labels: bool = true:
    set(value):
        show_labels = value
        _label_container.visible = value


@onready var _label_container: Node3D = $LabelContainer
@onready var _surface_mesh: MeshInstance3D = $SurfaceMesh
@onready var _vertex_mesh_container: Node3D = $VertexMeshContainer
@onready var _normals_mesh: MeshInstance3D = $NormalsMesh

var _active_vertex_mat := StandardMaterial3D.new()
var _inactive_vertex_mat := StandardMaterial3D.new()


func _ready():
    _active_vertex_mat.albedo_color = Color.LIME
    _inactive_vertex_mat.albedo_color = Color.BLACK
    
    _build_cube_mesh()
    _draw_surface()


func _draw_surface():
    _reset_vertex_mesh_states()
    
    var im_sur := ImmediateMesh.new()
    im_sur.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

    # convert active_vertices to int list
    var active_vert_ids = []
    for i in range(active_vertices.size()):
        if active_vertices[i]:
            active_vert_ids.append(i)
            _activate_vertex_mesh(i)

    var index = MarchingCube.get_combination_index_at_corners(active_vert_ids)
    var info = MarchingCube.get_meshinfo_at_combination_index(index)
    print("index: %s, verts: %s" % [index, info.verts])

    var im_norms := ImmediateMesh.new()
    im_norms.surface_begin(Mesh.PRIMITIVE_LINES)
    
    for i in range(0, len(info.verts)):
        var vert = info.verts[i]
        var norm = info.normals[i]

        im_sur.surface_add_vertex(vert)

        im_norms.surface_add_vertex(vert)
        im_norms.surface_add_vertex(vert + norm * .3)

    im_norms.surface_end()
    im_sur.surface_end()

    _surface_mesh.mesh = im_sur
    _normals_mesh.mesh = im_norms


func _build_cube_mesh():
    var im_edges_wireframe := ImmediateMesh.new()
    im_edges_wireframe.surface_begin(Mesh.PRIMITIVE_LINES)

    var processed = []
    for vi in range(0, MarchingCube.edge_vertices.size(), 2):
        var vertex: Vector3 = MarchingCube.edge_vertices[vi]
        var next_v: Vector3 = MarchingCube.edge_vertices[vi + 1]
        
        if not processed.has(vertex):
            processed.append(vertex)
            # add vertex label
            var vertex_label := Label3D.new()
            vertex_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
            vertex_label.position = vertex + .3 * vertex
            vertex_label.text = "vertex %s %s" % [vi/2, vertex]
            _label_container.add_child(vertex_label)

            # add vertex point
            var vertex_mesh_instance := MeshInstance3D.new()
            vertex_mesh_instance.position = vertex
            var vertex_mesh := SphereMesh.new()
            vertex_mesh.radius = 0.05
            vertex_mesh.height = vertex_mesh.radius * 2
            vertex_mesh.material = _inactive_vertex_mat
            vertex_mesh_instance.mesh = vertex_mesh
            _vertex_mesh_container.add_child(vertex_mesh_instance)
            
            # _draw_vertex_normal(im_edges_wireframe, vertex)

        # add edge labels
        var edge_label := Label3D.new()
        edge_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        var mid = vertex + vertex.direction_to(next_v)
        edge_label.position = Vector3.ZERO.direction_to(vertex + mid) * 0.3 + mid
        edge_label.text = "e %s" % [vi/2]
        _label_container.add_child(edge_label)

        # add edges
        im_edges_wireframe.surface_add_vertex(vertex)
        im_edges_wireframe.surface_add_vertex(next_v)

    # _draw_face_normals(im_edges_wireframe)

    # use edge mesh as this node's mesh
    im_edges_wireframe.surface_end()
    mesh = im_edges_wireframe


func _draw_face_normals(im: ImmediateMesh):
    for vec in MarchingCube.face_normals:
        im.surface_add_vertex(vec)
        im.surface_add_vertex(vec+vec*.3)


func _draw_vertex_normal(im: ImmediateMesh, vert: Vector3):
    var dir = Vector3.ZERO.direction_to(vert)
    im.surface_add_vertex(vert)
    im.surface_add_vertex(vert + dir * .3)


func _reset_vertex_mesh_states():
    for child in _vertex_mesh_container.get_children():
        child.mesh.material = _inactive_vertex_mat


func _activate_vertex_mesh(index: int):
    var child = _vertex_mesh_container.get_child(index)
    child.mesh.material = _active_vertex_mat
