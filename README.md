# common-shapes

A Common Lisp library for generating and manipulating triangle meshes for 2D and 3D shapes. 

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

- `3d-vectors` - Vector operations
- `3d-matrices` - Matrix operations

## Examples

### Basic 2D Shapes

```lisp
(ql:quickload :common-shapes)
(use-package :common-shapes)

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
       (matrix (m:m* (m:mtranslation (v:vec3 1.0 2.0 3.0))
                     (m:mrotation (v:vec3 0.0 1.0 0.0) (/ pi 2))))
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
(ql:quickload :common-shapes/test)
(common-shapes/test:run-tests)
```

This runs tests for all shape generators, platonic solids, and utility functions.

## License

```
The MIT License (MIT)

Copyright (c) 2026 George Watson

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
