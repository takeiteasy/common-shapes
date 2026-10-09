;;;; types.lisp
;;;; Mesh data structure definitions for cl-meshgen

(in-package #:cl-meshgen)

(defstruct mesh
  "A triangle mesh with vertices, indices, and optional normals and texture coordinates.
   - vertices: Flat array of coordinates (X Y for 2D, X Y Z for 3D)
   - indices: Flat array of triangle indices (I J K I J K...)
   - normals: Optional per-vertex normals
   - tex-coords: Optional texture coordinates (U V U V...)
   - dimensions: 2 for 2D mesh, 3 for 3D mesh"
  (vertices nil :type (or null (simple-array single-float (*))))
  (indices nil :type (or null (simple-array (unsigned-byte 32) (*))))
  (normals nil :type (or null (simple-array single-float (*))))
  (tex-coords nil :type (or null (simple-array single-float (*))))
  (dimensions 2 :type (integer 2 3)))

(defun vertex-count (mesh)
  "Return the number of vertices in a mesh."
  (let ((verts (mesh-vertices mesh)))
    (if verts
        (floor (length verts) (mesh-dimensions mesh))
        0)))

(defun triangle-count (mesh)
  "Return the number of triangles in a mesh."
  (let ((indices (mesh-indices mesh)))
    (if indices
        (floor (length indices) 3)
        0)))

(defun make-vertex-array (count dimensions)
  "Create a vertex array for COUNT vertices with DIMENSIONS components each."
  (make-array (* count dimensions)
              :element-type 'single-float
              :initial-element 0.0))

(defun make-index-array (count)
  "Create an index array for COUNT indices."
  (make-array count
              :element-type '(unsigned-byte 32)
              :initial-element 0))

(defun make-texcoord-array (count)
  "Create a texture coordinate array for COUNT vertices (2 components each)."
  (make-array (* count 2)
              :element-type 'single-float
              :initial-element 0.0))
