@tool
extends MeshInstance3D


@export var grid_width = 10:
    set(value):
        if value != grid_width:
            grid_width = value
            _update_mesh()


@export var grid_height = 1:
    set(value):
        if value != grid_height:
            grid_height = value
            _update_mesh()


@export var grid_depth = 10:
    set(value):
        if value != grid_depth:
            grid_depth = value
            _update_mesh()


func _ready():
    _update_mesh()


func _update_mesh():
    var im = ImmediateMesh.new()
    im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

    var offset := Vector3(grid_width/2, grid_height/2, grid_depth/2)

    for x in range(grid_width):
        for y in range(grid_height):
            for z in range(grid_depth):
                var pos := Vector3(x,y,z) - offset
                var index = MarchingCube.get_combination_index_at_corners([4,5,6,7])
                var info = MarchingCube.get_meshinfo_at_combination_index(index)
                for i in range(0, len(info.verts)):
                    var vert = info.verts[i]
                    var norm = info.normals[i]
                    var uv = info.uvs[i]

                    im.surface_set_normal(norm)
                    im.surface_set_uv(uv)
                    im.surface_add_vertex(vert + pos)
    
    im.surface_end()
    mesh = im