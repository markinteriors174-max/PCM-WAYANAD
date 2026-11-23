
class GltfPrimitive {
  final String material;
  final List<int> indices;
  final List<double> positions; // flat flat coordinates [x, y, z]

  GltfPrimitive({
    required this.material,
    required this.indices,
    required this.positions,
  });
}

class GltfMesh {
  final String name;
  final List<GltfPrimitive> primitives;

  GltfMesh({
    required this.name,
    required this.primitives,
  });
}

class GltfModel {
  final String name;
  final List<GltfMesh> meshes;

  GltfModel({
    required this.name,
    required this.meshes,
  });
}

class GltfParser {
  // Pre-parsed static models for synchronous, instantaneous 60fps rendering in paint() loops
  static final Map<String, GltfModel> staticLibrary = _initStaticLibrary();

  static GltfModel? getModel(String id) {
    if (id.contains('bed')) return staticLibrary['bed'];
    if (id.contains('sofa')) return staticLibrary['sofa'];
    if (id.contains('tv_unit') || id.contains('TV Console') || id.contains('TV Unit')) return staticLibrary['tv_unit'];
    if (id.contains('curtain') || id.contains('Curtain')) return staticLibrary['curtain'];
    if (id.contains('plant') || id.contains('Plant')) return staticLibrary['plant'];
    if (id.contains('fan') || id.contains('ceiling_fan') || id.contains('Fan')) return staticLibrary['ceiling_fan'];
    return null;
  }

  static Map<String, GltfModel> _initStaticLibrary() {
    return {
      'ceiling_fan': GltfModel(
        name: 'Ceiling Fan',
        meshes: [
          GltfMesh(
            name: 'Rod',
            primitives: [
              GltfPrimitive(
                material: 'metal_rod',
                indices: [0, 1, 2, 0, 2, 3],
                positions: [
                  -0.1, 0.0, -0.1,
                   0.1, 0.0, -0.1,
                   0.1, 1.5,  0.1,
                  -0.1, 1.5,  0.1,
                ],
              ),
            ],
          ),
          GltfMesh(
            name: 'Hub',
            primitives: [
              GltfPrimitive(
                material: 'fan_hub',
                indices: [0, 1, 2, 0, 2, 3],
                positions: [
                  -0.6, 0.0, -0.6,
                   0.6, 0.0, -0.6,
                   0.6, 0.2,  0.6,
                  -0.6, 0.2,  0.6,
                ],
              ),
            ],
          ),
          GltfMesh(
            name: 'Blades',
            primitives: [
              GltfPrimitive(
                material: 'fan_blade',
                indices: [0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7, 8, 9, 10, 8, 10, 11],
                positions: [
                  -0.15, 0.1,  0.4,
                   0.15, 0.1,  0.4,
                   0.15, 0.1,  2.0,
                  -0.15, 0.1,  2.0,
                  -1.5,  0.1, -0.9,
                  -1.2,  0.1, -1.3,
                   0.1,  0.1, -0.1,
                  -0.1,  0.1,  0.1,
                   1.2,  0.1, -1.3,
                   1.5,  0.1, -0.9,
                   0.1,  0.1,  0.1,
                  -0.1,  0.1, -0.1,
                ],
              ),
            ],
          ),
        ],
      ),
      'bed': GltfModel(
        name: 'Bed',
        meshes: [
          GltfMesh(
            name: 'Frame',
            primitives: [
              GltfPrimitive(
                material: 'wood',
                indices: [0,1,2, 0,2,3, 4,5,6, 4,6,7, 8,9,10, 8,10,11],
                positions: [
                  -3.0, 0.0, -3.2,  3.0, 0.0, -3.2,  3.0, 0.8, -3.2, -3.0, 0.8, -3.2,
                  -3.1, 0.0, -3.3, -3.1, 1.8, -3.3,  3.1, 1.8, -3.3,  3.1, 0.0, -3.3,
                  -3.0, 0.0,  3.2,  3.0, 0.0,  3.2,  3.0, 0.4,  3.2, -3.0, 0.4,  3.2
                ],
              ),
            ],
          ),
          GltfMesh(
            name: 'Mattress',
            primitives: [
              GltfPrimitive(
                material: 'fabric_mattress',
                indices: [0,1,2, 0,2,3],
                positions: [
                  -2.8, 0.5, -3.0,  2.8, 0.5, -3.0,  2.8, 0.5,  3.0, -2.8, 0.5,  3.0
                ],
              ),
            ],
          ),
          GltfMesh(
            name: 'Pillows',
            primitives: [
              GltfPrimitive(
                material: 'fabric_pillow',
                indices: [0,1,2, 0,2,3, 4,5,6, 4,6,7],
                positions: [
                  -2.2, 0.7, -2.8, -0.2, 0.7, -2.8, -0.2, 0.7, -1.8, -2.2, 0.7, -1.8,
                   0.2, 0.7, -2.8,  2.2, 0.7, -2.8,  2.2, 0.7, -1.8,  0.2, 0.7, -1.8
                ],
              ),
            ],
          ),
        ],
      ),
      'sofa': GltfModel(
        name: 'Sofa',
        meshes: [
          GltfMesh(
            name: 'Base',
            primitives: [
              GltfPrimitive(
                material: 'fabric_cushion',
                indices: [0,1,2, 0,2,3],
                positions: [
                  -3.0, 0.4, -1.2,  3.0, 0.4, -1.2,  3.0, 0.4,  1.2, -3.0, 0.4,  1.2
                ],
              ),
            ],
          ),
          GltfMesh(
            name: 'Backrest',
            primitives: [
              GltfPrimitive(
                material: 'fabric_back',
                indices: [0,1,2, 0,2,3],
                positions: [
                  -3.0, 0.4, -1.3,  3.0, 0.4, -1.3,  3.0, 1.6, -1.3, -3.0, 1.6, -1.3
                ],
              ),
            ],
          ),
          GltfMesh(
            name: 'Armrests',
            primitives: [
              GltfPrimitive(
                material: 'fabric_arm',
                indices: [0,1,2, 0,2,3, 4,5,6, 4,6,7],
                positions: [
                  -3.2, 0.0, -1.3, -3.0, 0.0, -1.3, -3.0, 1.0,  1.3, -3.2, 1.0,  1.3,
                   3.0, 0.0, -1.3,  3.2, 0.0, -1.3,  3.2, 1.0,  1.3,  3.0, 1.0,  1.3
                ],
              ),
            ],
          ),
        ],
      ),
      'tv_unit': GltfModel(
        name: 'TV Unit',
        meshes: [
          GltfMesh(
            name: 'Cabinet',
            primitives: [
              GltfPrimitive(
                material: 'wood',
                indices: [0,1,2, 0,2,3],
                positions: [
                  -2.5, 0.0, -0.6,  2.5, 0.0, -0.6,  2.5, 0.8,  0.6, -2.5, 0.8,  0.6
                ],
              ),
            ],
          ),
          GltfMesh(
            name: 'Screen',
            primitives: [
              GltfPrimitive(
                material: 'glass_dark',
                indices: [0,1,2, 0,2,3],
                positions: [
                  -1.8, 1.2,  0.0,  1.8, 1.2,  0.0,  1.8, 2.8,  0.0, -1.8, 2.8,  0.0
                ],
              ),
            ],
          ),
        ],
      ),
      'curtain': GltfModel(
        name: 'Curtains',
        meshes: [
          GltfMesh(
            name: 'Panels',
            primitives: [
              GltfPrimitive(
                material: 'fabric_curtain',
                indices: [0,1,2, 0,2,3, 4,5,6, 4,6,7],
                positions: [
                  -3.0, 0.0,  0.0, -2.0, 0.0,  0.0, -2.0, 6.0,  0.0, -3.0, 6.0,  0.0,
                   2.0, 0.0,  0.0,  3.0, 0.0,  0.0,  3.0, 6.0,  0.0,  2.0, 6.0,  0.0
                ],
              ),
            ],
          ),
        ],
      ),
      'plant': GltfModel(
        name: 'Indoor Plant',
        meshes: [
          GltfMesh(
            name: 'Pot',
            primitives: [
              GltfPrimitive(
                material: 'clay_pot',
                indices: [0,1,2, 0,2,3],
                positions: [
                  -0.6, 0.0, -0.6,  0.6, 0.0, -0.6,  0.6, 1.2,  0.6, -0.6, 1.2,  0.6
                ],
              ),
            ],
          ),
          GltfMesh(
            name: 'Leaves',
            primitives: [
              GltfPrimitive(
                material: 'leaf_green',
                indices: [0,1,2, 0,2,3, 4,5,6, 4,6,7],
                positions: [
                  -0.2, 1.2,  0.0,  0.2, 1.2,  0.0,  1.2, 2.5,  0.8, -0.8, 2.5,  0.8,
                  -0.2, 1.2,  0.0,  0.2, 1.2,  0.0, -0.8, 2.5, -0.8,  0.8, 2.5, -0.8
                ],
              ),
            ],
          ),
        ],
      ),
    };
  }
}
