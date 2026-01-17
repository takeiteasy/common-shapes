;;;; platonic.lisp
;;;; Platonic solid generators for common-shapes

(in-package #:common-shapes)

;;; Golden ratio for icosahedron and dodecahedron
(defconstant +phi+ (/ (+ 1.0 (sqrt 5.0)) 2.0)
  "Golden ratio, used for icosahedron and dodecahedron construction.")

(defun make-tetrahedron (radius &key normals tex-coords)
  "Generate a regular tetrahedron with vertices on a sphere of given RADIUS.
   4 triangular faces, 4 vertices, 6 edges.

   Options:
   - NORMALS: Generate per-vertex normals
   - TEX-COORDS: Generate texture coordinates"
  ;; Use unwelded vertices for correct face normals (4 faces * 3 vertices)
  (let* ((vertex-count 12)
         (tri-count 4)
         (vertices (make-vertex-array vertex-count 3))
         (indices (make-index-array (* tri-count 3)))
         (norms (when normals (make-vertex-array vertex-count 3)))
         (uvs (when tex-coords (make-texcoord-array vertex-count)))
         (r (sf radius))
         ;; Tetrahedron vertices inscribed in unit sphere, then scaled
         (a (/ 1.0 (sqrt 3.0)))
         (b (sqrt (/ 2.0 3.0)))
         (c (sqrt (/ 2.0 9.0)))
         ;; The four base vertices (normalized, then scaled)
         (v0 (v:v* (v:vunit (v:vec3 0.0 1.0 0.0)) r))
         (v1 (v:v* (v:vunit (v:vec3 (* 2.0 c) (/ -1.0 3.0) 0.0)) r))
         (v2 (v:v* (v:vunit (v:vec3 (- c) (/ -1.0 3.0) a)) r))
         (v3 (v:v* (v:vunit (v:vec3 (- c) (/ -1.0 3.0) (- a))) r)))

    ;; Define the 4 faces with their vertices
    ;; Each face gets its own copy of vertices for correct normals
    (labels ((add-face (face-idx va vb vc)
               (let ((base (* face-idx 3)))
                 ;; Set vertices
                 (set-vertex-3d-v vertices base va)
                 (set-vertex-3d-v vertices (+ base 1) vb)
                 (set-vertex-3d-v vertices (+ base 2) vc)
                 ;; Set indices
                 (set-triangle indices face-idx base (+ base 1) (+ base 2))
                 ;; Compute and set face normal
                 (when normals
                   (let ((n (triangle-normal va vb vc)))
                     (set-vertex-3d-v norms base n)
                     (set-vertex-3d-v norms (+ base 1) n)
                     (set-vertex-3d-v norms (+ base 2) n)))
                 ;; Set texture coordinates (simple triangle mapping)
                 (when tex-coords
                   (set-texcoord uvs base 0.5 1.0)
                   (set-texcoord uvs (+ base 1) 0.0 0.0)
                   (set-texcoord uvs (+ base 2) 1.0 0.0)))))

      ;; Define faces (counter-clockwise from outside)
      (add-face 0 v0 v1 v2)
      (add-face 1 v0 v2 v3)
      (add-face 2 v0 v3 v1)
      (add-face 3 v1 v3 v2))

    (make-mesh :vertices vertices
               :indices indices
               :normals norms
               :tex-coords uvs
               :dimensions 3)))

(defun make-octahedron (radius &key normals tex-coords)
  "Generate a regular octahedron with vertices on a sphere of given RADIUS.
   8 triangular faces, 6 vertices, 12 edges.

   Options:
   - NORMALS: Generate per-vertex normals
   - TEX-COORDS: Generate texture coordinates"
  ;; 8 faces * 3 vertices (unwelded for face normals)
  (let* ((vertex-count 24)
         (tri-count 8)
         (vertices (make-vertex-array vertex-count 3))
         (indices (make-index-array (* tri-count 3)))
         (norms (when normals (make-vertex-array vertex-count 3)))
         (uvs (when tex-coords (make-texcoord-array vertex-count)))
         (r (sf radius))
         ;; Six vertices on axes
         (verts (vector
                 (v:vec3 0.0 r 0.0)      ; top
                 (v:vec3 0.0 (- r) 0.0)  ; bottom
                 (v:vec3 r 0.0 0.0)      ; right
                 (v:vec3 (- r) 0.0 0.0)  ; left
                 (v:vec3 0.0 0.0 r)      ; front
                 (v:vec3 0.0 0.0 (- r)))) ; back
         ;; Face indices (vertex indices into verts array)
         (faces '((0 4 2) (0 2 5) (0 5 3) (0 3 4)   ; top 4 faces
                  (1 2 4) (1 5 2) (1 3 5) (1 4 3)))) ; bottom 4 faces

    (loop for face in faces
          for face-idx from 0 do
            (let* ((base (* face-idx 3))
                   (va (aref verts (first face)))
                   (vb (aref verts (second face)))
                   (vc (aref verts (third face))))
              ;; Set vertices
              (set-vertex-3d-v vertices base va)
              (set-vertex-3d-v vertices (+ base 1) vb)
              (set-vertex-3d-v vertices (+ base 2) vc)
              ;; Set indices
              (set-triangle indices face-idx base (+ base 1) (+ base 2))
              ;; Face normals
              (when normals
                (let ((n (triangle-normal va vb vc)))
                  (set-vertex-3d-v norms base n)
                  (set-vertex-3d-v norms (+ base 1) n)
                  (set-vertex-3d-v norms (+ base 2) n)))
              ;; Texture coordinates
              (when tex-coords
                (set-texcoord uvs base 0.5 1.0)
                (set-texcoord uvs (+ base 1) 0.0 0.0)
                (set-texcoord uvs (+ base 2) 1.0 0.0))))

    (make-mesh :vertices vertices
               :indices indices
               :normals norms
               :tex-coords uvs
               :dimensions 3)))

(defun make-icosahedron (radius &key normals tex-coords)
  "Generate a regular icosahedron with vertices on a sphere of given RADIUS.
   20 triangular faces, 12 vertices, 30 edges.

   Options:
   - NORMALS: Generate per-vertex normals
   - TEX-COORDS: Generate texture coordinates"
  ;; 20 faces * 3 vertices (unwelded for face normals)
  (let* ((vertex-count 60)
         (tri-count 20)
         (vertices (make-vertex-array vertex-count 3))
         (indices (make-index-array (* tri-count 3)))
         (norms (when normals (make-vertex-array vertex-count 3)))
         (uvs (when tex-coords (make-texcoord-array vertex-count)))
         (r (sf radius))
         ;; Icosahedron vertices using golden ratio
         (t-val +phi+)
         ;; Base vertices (will be normalized and scaled)
         (base-verts (vector
                      (v:vec3 (- 1.0) t-val 0.0)
                      (v:vec3 1.0 t-val 0.0)
                      (v:vec3 (- 1.0) (- t-val) 0.0)
                      (v:vec3 1.0 (- t-val) 0.0)
                      (v:vec3 0.0 (- 1.0) t-val)
                      (v:vec3 0.0 1.0 t-val)
                      (v:vec3 0.0 (- 1.0) (- t-val))
                      (v:vec3 0.0 1.0 (- t-val))
                      (v:vec3 t-val 0.0 (- 1.0))
                      (v:vec3 t-val 0.0 1.0)
                      (v:vec3 (- t-val) 0.0 (- 1.0))
                      (v:vec3 (- t-val) 0.0 1.0)))
         ;; Normalize and scale vertices
         (verts (map 'vector
                     (lambda (v) (v:v* (v:vunit v) r))
                     base-verts))
         ;; 20 face definitions
         (faces '(;; 5 faces around vertex 0
                  (0 11 5) (0 5 1) (0 1 7) (0 7 10) (0 10 11)
                  ;; 5 adjacent faces
                  (1 5 9) (5 11 4) (11 10 2) (10 7 6) (7 1 8)
                  ;; 5 faces around vertex 3
                  (3 9 4) (3 4 2) (3 2 6) (3 6 8) (3 8 9)
                  ;; 5 adjacent faces
                  (4 9 5) (2 4 11) (6 2 10) (8 6 7) (9 8 1))))

    (loop for face in faces
          for face-idx from 0 do
            (let* ((base (* face-idx 3))
                   (va (aref verts (first face)))
                   (vb (aref verts (second face)))
                   (vc (aref verts (third face))))
              ;; Set vertices
              (set-vertex-3d-v vertices base va)
              (set-vertex-3d-v vertices (+ base 1) vb)
              (set-vertex-3d-v vertices (+ base 2) vc)
              ;; Set indices
              (set-triangle indices face-idx base (+ base 1) (+ base 2))
              ;; Face normals
              (when normals
                (let ((n (triangle-normal va vb vc)))
                  (set-vertex-3d-v norms base n)
                  (set-vertex-3d-v norms (+ base 1) n)
                  (set-vertex-3d-v norms (+ base 2) n)))
              ;; Texture coordinates - spherical projection
              (when tex-coords
                (flet ((sphere-uv (v)
                         (let ((n (v:vunit v)))
                           (values (+ 0.5 (/ (atan (v:vz3 n) (v:vx3 n)) +tau+))
                                   (+ 0.5 (/ (asin (v:vy3 n)) +pi+))))))
                  (multiple-value-bind (u0 v0) (sphere-uv va)
                    (multiple-value-bind (u1 v1) (sphere-uv vb)
                      (multiple-value-bind (u2 v2) (sphere-uv vc)
                        (set-texcoord uvs base u0 v0)
                        (set-texcoord uvs (+ base 1) u1 v1)
                        (set-texcoord uvs (+ base 2) u2 v2))))))))

    (make-mesh :vertices vertices
               :indices indices
               :normals norms
               :tex-coords uvs
               :dimensions 3)))

(defun make-dodecahedron (radius &key normals tex-coords)
  "Generate a regular dodecahedron with vertices on a sphere of given RADIUS.
   12 pentagonal faces (triangulated to 36 triangles), 20 vertices.

   Options:
   - NORMALS: Generate per-vertex normals
   - TEX-COORDS: Generate texture coordinates"
  ;; 12 faces * 5 vertices per pentagon, but triangulated = 12 * 3 triangles
  ;; Each pentagon is split into 3 triangles = 36 triangles total
  ;; 36 triangles * 3 vertices = 108 vertices (unwelded)
  (let* ((tri-count 36)
         (vertex-count (* tri-count 3))
         (vertices (make-vertex-array vertex-count 3))
         (indices (make-index-array (* tri-count 3)))
         (norms (when normals (make-vertex-array vertex-count 3)))
         (uvs (when tex-coords (make-texcoord-array vertex-count)))
         (r (sf radius))
         ;; Dodecahedron vertex coordinates
         (phi +phi+)
         (inv-phi (/ 1.0 phi))
         ;; 20 vertices of dodecahedron
         (base-verts (vector
                      ;; Cube vertices (8)
                      (v:vec3 1.0 1.0 1.0)
                      (v:vec3 1.0 1.0 -1.0)
                      (v:vec3 1.0 -1.0 1.0)
                      (v:vec3 1.0 -1.0 -1.0)
                      (v:vec3 -1.0 1.0 1.0)
                      (v:vec3 -1.0 1.0 -1.0)
                      (v:vec3 -1.0 -1.0 1.0)
                      (v:vec3 -1.0 -1.0 -1.0)
                      ;; Rectangle on XY plane (4)
                      (v:vec3 0.0 phi inv-phi)
                      (v:vec3 0.0 phi (- inv-phi))
                      (v:vec3 0.0 (- phi) inv-phi)
                      (v:vec3 0.0 (- phi) (- inv-phi))
                      ;; Rectangle on XZ plane (4)
                      (v:vec3 inv-phi 0.0 phi)
                      (v:vec3 (- inv-phi) 0.0 phi)
                      (v:vec3 inv-phi 0.0 (- phi))
                      (v:vec3 (- inv-phi) 0.0 (- phi))
                      ;; Rectangle on YZ plane (4)
                      (v:vec3 phi inv-phi 0.0)
                      (v:vec3 phi (- inv-phi) 0.0)
                      (v:vec3 (- phi) inv-phi 0.0)
                      (v:vec3 (- phi) (- inv-phi) 0.0)))
         ;; Normalize and scale
         (verts (map 'vector
                     (lambda (v) (v:v* (v:vunit v) r))
                     base-verts))
         ;; 12 pentagonal faces (vertex indices)
         (pentagons '((0 8 4 13 12)
                      (0 12 2 17 16)
                      (0 16 1 9 8)
                      (1 16 17 3 14)
                      (1 14 15 5 9)
                      (2 12 13 6 10)
                      (2 10 11 3 17)
                      (3 11 7 15 14)
                      (4 8 9 5 18)
                      (4 18 19 6 13)
                      (5 15 7 19 18)
                      (6 19 7 11 10)))
         (tri-idx 0))

    ;; Triangulate each pentagon (fan from first vertex)
    (dolist (pent pentagons)
      (let* ((v0 (aref verts (first pent)))
             ;; Face normal from first triangle
             (face-normal (when normals
                            (triangle-normal v0
                                             (aref verts (second pent))
                                             (aref verts (third pent))))))
        ;; Create 3 triangles for the pentagon
        (loop for i from 1 to 3
              for vi = (nth i pent)
              for vj = (nth (1+ i) pent) do
                (let* ((va v0)
                       (vb (aref verts vi))
                       (vc (aref verts vj))
                       (base (* tri-idx 3)))
                  ;; Set vertices
                  (set-vertex-3d-v vertices base va)
                  (set-vertex-3d-v vertices (+ base 1) vb)
                  (set-vertex-3d-v vertices (+ base 2) vc)
                  ;; Set indices
                  (set-triangle indices tri-idx base (+ base 1) (+ base 2))
                  ;; Face normals (same for all triangles in pentagon)
                  (when normals
                    (set-vertex-3d-v norms base face-normal)
                    (set-vertex-3d-v norms (+ base 1) face-normal)
                    (set-vertex-3d-v norms (+ base 2) face-normal))
                  ;; Texture coordinates
                  (when tex-coords
                    (flet ((sphere-uv (v)
                             (let ((n (v:vunit v)))
                               (values (+ 0.5 (/ (atan (v:vz3 n) (v:vx3 n)) +tau+))
                                       (+ 0.5 (/ (asin (v:vy3 n)) +pi+))))))
                      (multiple-value-bind (u0 vv0) (sphere-uv va)
                        (multiple-value-bind (u1 vv1) (sphere-uv vb)
                          (multiple-value-bind (u2 vv2) (sphere-uv vc)
                            (set-texcoord uvs base u0 vv0)
                            (set-texcoord uvs (+ base 1) u1 vv1)
                            (set-texcoord uvs (+ base 2) u2 vv2))))))
                  (incf tri-idx)))))

    (make-mesh :vertices vertices
               :indices indices
               :normals norms
               :tex-coords uvs
               :dimensions 3)))
