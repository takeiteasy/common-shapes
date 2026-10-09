;;;; generators-2d.lisp
;;;; 2D shape generators for cl-meshgen

(in-package #:cl-meshgen)

(defun make-polygon-2d (n-sides radius &key 3d normals tex-coords)
  "Generate a regular polygon mesh with N-SIDES sides and given RADIUS.
   Uses fan triangulation from center vertex.

   Options:
   - 3D: Output 3D vertices with z=0 (default is 2D x,y only)
   - NORMALS: Generate per-vertex normals (all pointing +Z)
   - TEX-COORDS: Generate texture coordinates"
  (let* ((dims (if 3d 3 2))
         (vertex-count (1+ n-sides))  ; center + outer vertices
         (tri-count n-sides)
         (vertices (make-vertex-array vertex-count dims))
         (indices (make-index-array (* tri-count 3)))
         (norms (when normals (make-vertex-array vertex-count 3)))
         (uvs (when tex-coords (make-texcoord-array vertex-count)))
         (r (sf radius)))

    ;; Center vertex at origin
    (if 3d
        (set-vertex-3d vertices 0 0.0 0.0 0.0)
        (set-vertex-2d vertices 0 0.0 0.0))

    ;; Generate outer vertices
    (dotimes (i n-sides)
      (let* ((angle (* +tau+ (/ (sf i) (sf n-sides))))
             (x (* r (cos angle)))
             (y (* r (sin angle))))
        (if 3d
            (set-vertex-3d vertices (1+ i) x y 0.0)
            (set-vertex-2d vertices (1+ i) x y))))

    ;; Generate triangles (fan from center)
    (dotimes (i n-sides)
      (let ((next (1+ (mod (1+ i) n-sides))))
        (set-triangle indices i 0 (1+ i) next)))

    ;; Generate normals (all point +Z)
    (when normals
      (dotimes (i vertex-count)
        (set-vertex-3d norms i 0.0 0.0 1.0)))

    ;; Generate texture coordinates
    (when tex-coords
      (set-texcoord uvs 0 0.5 0.5)  ; center
      (dotimes (i n-sides)
        (let* ((angle (* +tau+ (/ (sf i) (sf n-sides))))
               (u (+ 0.5 (* 0.5 (cos angle))))
               (v (+ 0.5 (* 0.5 (sin angle)))))
          (set-texcoord uvs (1+ i) u v))))

    (make-mesh :vertices vertices
               :indices indices
               :normals norms
               :tex-coords uvs
               :dimensions dims)))

(defun make-circle-2d (radius segments &key 3d normals tex-coords)
  "Generate a circle/disk mesh with given RADIUS and SEGMENTS.
   A circle is just a polygon with many sides.

   Options:
   - 3D: Output 3D vertices with z=0
   - NORMALS: Generate per-vertex normals
   - TEX-COORDS: Generate texture coordinates"
  (make-polygon-2d segments radius :3d 3d :normals normals :tex-coords tex-coords))

(defun make-rectangle-2d (width height &key 3d normals tex-coords)
  "Generate a rectangle mesh centered at origin.

   Options:
   - 3D: Output 3D vertices with z=0
   - NORMALS: Generate per-vertex normals
   - TEX-COORDS: Generate texture coordinates"
  (let* ((dims (if 3d 3 2))
         (vertex-count 4)
         (tri-count 2)
         (vertices (make-vertex-array vertex-count dims))
         (indices (make-index-array (* tri-count 3)))
         (norms (when normals (make-vertex-array vertex-count 3)))
         (uvs (when tex-coords (make-texcoord-array vertex-count)))
         (hw (/ (sf width) 2.0))
         (hh (/ (sf height) 2.0)))

    ;; Vertices: counter-clockwise from bottom-left
    ;; 3---2
    ;; |   |
    ;; 0---1
    (if 3d
        (progn
          (set-vertex-3d vertices 0 (- hw) (- hh) 0.0)
          (set-vertex-3d vertices 1 hw (- hh) 0.0)
          (set-vertex-3d vertices 2 hw hh 0.0)
          (set-vertex-3d vertices 3 (- hw) hh 0.0))
        (progn
          (set-vertex-2d vertices 0 (- hw) (- hh))
          (set-vertex-2d vertices 1 hw (- hh))
          (set-vertex-2d vertices 2 hw hh)
          (set-vertex-2d vertices 3 (- hw) hh)))

    ;; Two triangles
    (set-triangle indices 0 0 1 2)
    (set-triangle indices 1 0 2 3)

    ;; Normals
    (when normals
      (dotimes (i vertex-count)
        (set-vertex-3d norms i 0.0 0.0 1.0)))

    ;; Texture coordinates
    (when tex-coords
      (set-texcoord uvs 0 0.0 0.0)
      (set-texcoord uvs 1 1.0 0.0)
      (set-texcoord uvs 2 1.0 1.0)
      (set-texcoord uvs 3 0.0 1.0))

    (make-mesh :vertices vertices
               :indices indices
               :normals norms
               :tex-coords uvs
               :dimensions dims)))

(defun make-ellipse-2d (rx ry segments &key 3d normals tex-coords)
  "Generate an ellipse mesh with radii RX and RY, using SEGMENTS for resolution.

   Options:
   - 3D: Output 3D vertices with z=0
   - NORMALS: Generate per-vertex normals
   - TEX-COORDS: Generate texture coordinates"
  (let* ((dims (if 3d 3 2))
         (vertex-count (1+ segments))
         (tri-count segments)
         (vertices (make-vertex-array vertex-count dims))
         (indices (make-index-array (* tri-count 3)))
         (norms (when normals (make-vertex-array vertex-count 3)))
         (uvs (when tex-coords (make-texcoord-array vertex-count)))
         (rx (sf rx))
         (ry (sf ry)))

    ;; Center vertex
    (if 3d
        (set-vertex-3d vertices 0 0.0 0.0 0.0)
        (set-vertex-2d vertices 0 0.0 0.0))

    ;; Outer vertices
    (dotimes (i segments)
      (let* ((angle (* +tau+ (/ (sf i) (sf segments))))
             (x (* rx (cos angle)))
             (y (* ry (sin angle))))
        (if 3d
            (set-vertex-3d vertices (1+ i) x y 0.0)
            (set-vertex-2d vertices (1+ i) x y))))

    ;; Triangles
    (dotimes (i segments)
      (let ((next (1+ (mod (1+ i) segments))))
        (set-triangle indices i 0 (1+ i) next)))

    ;; Normals
    (when normals
      (dotimes (i vertex-count)
        (set-vertex-3d norms i 0.0 0.0 1.0)))

    ;; Texture coordinates (map ellipse to unit square)
    (when tex-coords
      (set-texcoord uvs 0 0.5 0.5)
      (dotimes (i segments)
        (let* ((angle (* +tau+ (/ (sf i) (sf segments))))
               (u (+ 0.5 (* 0.5 (cos angle))))
               (v (+ 0.5 (* 0.5 (sin angle)))))
          (set-texcoord uvs (1+ i) u v))))

    (make-mesh :vertices vertices
               :indices indices
               :normals norms
               :tex-coords uvs
               :dimensions dims)))
