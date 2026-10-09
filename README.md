# cl-meshgen

A Common Lisp library for generating and manipulating triangle meshes for 2D and 3D shapes. 

## Installation

From the takeiteasy Quicklisp dist, which is served over HTTPS so Quicklisp needs [ql-https](https://github.com/takeiteasy/ql-dist#install):

```lisp
(ql-dist:install-dist "https://takeiteasy.github.io/ql-dist/dist/takeiteasy.txt")
(ql:quickload :cl-meshgen)
```

Or clone into Quicklisp's local-projects:

```sh
git clone https://github.com/takeiteasy/cl-meshgen ~/quicklisp/local-projects/cl-meshgen
```

## Features

- **2D** - Rectangle, circle, ellipse, and polygons
- **3D** - Cube, box, sphere, icosphere, cylinder, cone, torus, plane, hemisphere, capulse, platonic (4/8/12/20 polyhedrons)
- **Utilities** 
  - `compute-normals` - Compute per-vertex normals
  - `compute-aabb` - Calculate axis-aligned bounding box
  - `merge-meshes` - Combine multiple meshes
  - `flip-winding` - Reverse triangle winding order
- **Transformations**
  - `transform-mesh` - Apply arbitrary 4x4 transformation matrix
  - `translate-mesh` - Move mesh in 3D space
  - `scale-mesh` - Scale mesh uniformly or per-axis
  - `rotate-mesh-x/y/z` - Rotate around X, Y, or Z axis
  - `center-mesh` - Translate mesh to origin
  - `normalize-mesh` - Fit mesh in unit cube/square
- **CSG (Constructive Solid Geometry)**
  - `csg-union` - Boolean union of two meshes
  - `csg-intersection` - Boolean intersection of two meshes
  - `csg-difference` - Boolean difference of two meshes

### Mesh Structure

All generators return a `mesh` structure containing:

- `vertices` - Flat array of vertex coordinates (2D: x y x y..., 3D: x y z x y z...)
- `indices` - Triangle indices (i j k i j k...)
- `normals` - Optional per-vertex normals
- `tex-coords` - Optional texture coordinates
- `dimensions` - 2 or 3

## Dependencies

`cl-meshgen` has no runtime dependencies — vector and matrix math are
provided in-house. `fiveam` is required only to run the test suite.

### Matrix layout

Internally, matrices are always column-major with column-vector math
(`M*v`). The special variable `*matrix-layout*` (default `:column-major`)
controls only the flat 16-float array format used by `marr` (serializing a
matrix out) and `mat4-from-array` (reading a matrix in):

- `:column-major` — matches OpenGL / column-vector conventions (default).
- `:row-major` — matches WebGPU/WGSL / row-vector conventions.

The two layouts are transposes of each other and are geometrically
identical when paired with the matching vector convention in your shader.
Set it once for your target pipeline, e.g.
`(setf cl-meshgen:*matrix-layout* :row-major)`.

## Examples

### Basic 2D Shapes

```lisp
(ql:quickload :cl-meshgen)
(use-package :cl-meshgen)

;; Create a 2D rectangle
(let ((rect (make-rectangle-2d 2.0 1.0)))
  (format t "Rectangle: ~D vertices, ~D triangles~%"
          (vertex-count rect)
          (triangle-count rect)))

;; Create a circle with 32 segments
(let ((circle (make-circle-2d 1.0 32)))
  (format t "Circle: ~D vertices~%" (vertex-count circle)))

;; Create a regular hexagon
(let ((hexagon (make-polygon-2d 6 1.0)))
  (format t "Hexagon: ~D triangles~%" (triangle-count hexagon)))
```

### 3D Shapes

```lisp
;; Create a cube
(let ((cube (make-cube 1.0 :normals t :tex-coords t)))
  (format t "Cube: ~D vertices, ~D triangles~%"
          (vertex-count cube)
          (triangle-count cube)))

;; Create a sphere with normals
(let ((sphere (make-sphere 1.0 32 16 :normals t)))
  (multiple-value-bind (min-bounds max-bounds) (compute-aabb sphere)
    (format t "Sphere bounds: ~A to ~A~%" min-bounds max-bounds)))

;; Create a cylinder
(let ((cylinder (make-cylinder 0.5 2.0 16 4 :normals t)))
  (format t "Cylinder: ~D vertices~%" (vertex-count cylinder)))

;; Create an icosphere with 2 subdivision levels
(let ((icosphere (make-icosphere 1.0 2 :normals t)))
  (format t "Icosphere: ~D vertices~%" (vertex-count icosphere)))
```

### Platonic Solids

```lisp
;; Create platonic solids
(let ((tetrahedron (make-tetrahedron 1.0 :normals t))
      (octahedron (make-octahedron 1.0 :normals t))
      (icosahedron (make-icosahedron 1.0 :normals t))
      (dodecahedron (make-dodecahedron 1.0 :normals t)))
  (format t "Tetrahedron: ~D triangles~%" (triangle-count tetrahedron))
  (format t "Octahedron: ~D triangles~%" (triangle-count octahedron))
  (format t "Icosahedron: ~D triangles~%" (triangle-count icosahedron))
  (format t "Dodecahedron: ~D triangles~%" (triangle-count dodecahedron)))
```

### Mesh Transformations

```lisp
;; Create a cube and transform it
(let* ((cube (make-cube 1.0))
       ;; Translate 5 units along X axis
       (translated (translate-mesh cube 5.0 0.0 0.0))
       ;; Scale by 2x uniformly
       (scaled (scale-mesh cube 2.0))
       ;; Rotate 45 degrees around Y axis
       (rotated (rotate-mesh-y cube (/ pi 4)))
       ;; Center mesh at origin
       (centered (center-mesh cube))
       ;; Normalize to unit size
       (normalized (normalize-mesh cube)))
  ;; Use transformed meshes...
  )

;; Apply arbitrary transformation matrix
(let* ((mesh (make-sphere 1.0 16 8))
       (matrix (cl-meshgen:m* (cl-meshgen:mtranslation (cl-meshgen:vec3 1.0 2.0 3.0))
                                 (cl-meshgen:mrotation (cl-meshgen:vec3 0.0 1.0 0.0) (/ pi 2))))
       (transformed (transform-mesh mesh matrix)))
  ;; Use transformed mesh...
  )
```

### Mesh Utilities

```lisp
;; Compute normals if not present
(let* ((sphere (make-sphere 1.0 16 8))  ; no normals
       (with-normals (compute-normals sphere)))
  (format t "Has normals: ~A~%" (mesh-normals with-normals)))

;; Merge multiple meshes
(let* ((cube1 (make-cube 1.0))
       (cube2 (make-cube 1.0))
       (merged (merge-meshes cube1 cube2)))
  (format t "Merged mesh: ~D vertices, ~D triangles~%"
          (vertex-count merged)
          (triangle-count merged)))

;; Compute bounding box
(let ((box (make-box 4.0 2.0 1.0)))
  (multiple-value-bind (min-bounds max-bounds) (compute-aabb box)
    (format t "Min bounds: ~A~%" min-bounds)
    (format t "Max bounds: ~A~%" max-bounds)))

;; Flip triangle winding order
(let* ((mesh (make-cube 1.0 :normals t))
       (flipped (flip-winding mesh)))
  ;; Normals are also flipped
  )
```

### Working with Mesh Data

```lisp
;; Access mesh components
(let ((mesh (make-cube 1.0 :normals t :tex-coords t)))
  ;; Get vertex array
  (let ((vertices (mesh-vertices mesh)))
    (format t "First vertex: (~F ~F ~F)~%"
            (aref vertices 0)
            (aref vertices 1)
            (aref vertices 2)))
  
  ;; Get indices
  (let ((indices (mesh-indices mesh)))
    (format t "First triangle: (~D ~D ~D)~%"
            (aref indices 0)
            (aref indices 1)
            (aref indices 2)))
  
  ;; Check dimensions
  (format t "Mesh dimensions: ~D~%" (mesh-dimensions mesh))
  
  ;; Count vertices and triangles
  (format t "Vertices: ~D, Triangles: ~D~%"
          (vertex-count mesh)
          (triangle-count mesh)))
```

### Constructive Solid Geometry

```lisp
;; Create a cube and a sphere, then combine them
(let* ((cube (make-cube 1.0))
       (sphere (make-sphere 0.8 16 12))
       (moved (translate-mesh sphere 0.5 0.0 0.0)))
  
  ;; Union - merge two shapes together
  (let ((result (csg-union cube moved)))
    (format t "Union: ~D vertices, ~D triangles~%"
            (vertex-count result)
            (triangle-count result)))
  
  ;; Intersection - keep only overlapping volume
  (let ((result (csg-intersection cube moved)))
    (format t "Intersection: ~D vertices, ~D triangles~%"
            (vertex-count result)
            (triangle-count result)))
  
  ;; Difference - subtract one shape from another
  (let ((result (csg-difference cube moved)))
    (format t "Difference: ~D vertices, ~D triangles~%"
            (vertex-count result)
            (triangle-count result))))

;; Drill a hole through a cube with a cylinder
(let* ((cube (make-cube 2.0))
       (drill (make-cylinder 0.5 3.0 16 4))
       (result (csg-difference cube drill)))
  (format t "Cube with hole: ~D triangles~%" (triangle-count result)))
```

## Testing

The library includes a comprehensive test suite using FiveAM:

```lisp
(ql:quickload :cl-meshgen/test)
(cl-meshgen/test:run-tests)
```

This runs tests for all shape generators, platonic solids, and utility functions.

## License

```text
cl-meshgen

Copyright (C) 2025 George Watson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
```
