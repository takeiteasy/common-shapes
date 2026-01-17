;;;; generators-3d.lisp
;;;; 3D shape generators for common-shapes

(in-package #:common-shapes)

(defun make-plane (width height slices stacks &key normals tex-coords)
  "Generate a flat plane mesh on the XY plane centered at origin.
   SLICES: divisions along X axis
   STACKS: divisions along Y axis

   Options:
   - NORMALS: Generate per-vertex normals (all pointing +Z)
   - TEX-COORDS: Generate texture coordinates"
  (let* ((cols (1+ slices))
         (rows (1+ stacks))
         (vertex-count (* cols rows))
         (tri-count (* 2 slices stacks))
         (vertices (make-vertex-array vertex-count 3))
         (indices (make-index-array (* tri-count 3)))
         (norms (when normals (make-vertex-array vertex-count 3)))
         (uvs (when tex-coords (make-texcoord-array vertex-count)))
         (hw (/ (sf width) 2.0))
         (hh (/ (sf height) 2.0)))

    ;; Generate vertices
    (dotimes (j rows)
      (dotimes (i cols)
        (let* ((idx (+ i (* j cols)))
               (u (/ (sf i) (sf slices)))
               (v (/ (sf j) (sf stacks)))
               (x (- (* u (sf width)) hw))
               (y (- (* v (sf height)) hh)))
          (set-vertex-3d vertices idx x y 0.0)
          (when normals
            (set-vertex-3d norms idx 0.0 0.0 1.0))
          (when tex-coords
            (set-texcoord uvs idx u v)))))

    ;; Generate triangles
    (let ((tri-idx 0))
      (dotimes (j stacks)
        (dotimes (i slices)
          (let ((bl (+ i (* j cols)))
                (br (+ i 1 (* j cols)))
                (tl (+ i (* (1+ j) cols)))
                (tr (+ i 1 (* (1+ j) cols))))
            (set-triangle indices tri-idx bl br tr)
            (incf tri-idx)
            (set-triangle indices tri-idx bl tr tl)
            (incf tri-idx)))))

    (make-mesh :vertices vertices
               :indices indices
               :normals norms
               :tex-coords uvs
               :dimensions 3)))

(defun make-box (width height depth &key normals tex-coords)
  "Generate a rectangular box centered at origin.
   Each face has its own vertices for correct normals.

   Options:
   - NORMALS: Generate per-vertex normals
   - TEX-COORDS: Generate texture coordinates"
  (let* ((vertex-count 24)  ; 4 vertices per face * 6 faces
         (tri-count 12)     ; 2 triangles per face * 6 faces
         (vertices (make-vertex-array vertex-count 3))
         (indices (make-index-array (* tri-count 3)))
         (norms (when normals (make-vertex-array vertex-count 3)))
         (uvs (when tex-coords (make-texcoord-array vertex-count)))
         (hw (/ (sf width) 2.0))
         (hh (/ (sf height) 2.0))
         (hd (/ (sf depth) 2.0)))

    ;; Helper to add a face (quad as two triangles)
    (labels ((add-face (face-idx
                        v0x v0y v0z v1x v1y v1z
                        v2x v2y v2z v3x v3y v3z
                        nx ny nz)
               (let ((base (* face-idx 4))
                     (tri-base (* face-idx 2)))
                 ;; Vertices (counter-clockwise)
                 (set-vertex-3d vertices base v0x v0y v0z)
                 (set-vertex-3d vertices (+ base 1) v1x v1y v1z)
                 (set-vertex-3d vertices (+ base 2) v2x v2y v2z)
                 (set-vertex-3d vertices (+ base 3) v3x v3y v3z)
                 ;; Triangles
                 (set-triangle indices tri-base base (+ base 1) (+ base 2))
                 (set-triangle indices (1+ tri-base) base (+ base 2) (+ base 3))
                 ;; Normals
                 (when normals
                   (dotimes (i 4)
                     (set-vertex-3d norms (+ base i) nx ny nz)))
                 ;; Tex coords
                 (when tex-coords
                   (set-texcoord uvs base 0.0 0.0)
                   (set-texcoord uvs (+ base 1) 1.0 0.0)
                   (set-texcoord uvs (+ base 2) 1.0 1.0)
                   (set-texcoord uvs (+ base 3) 0.0 1.0)))))

      ;; Front face (+Z)
      (add-face 0
                (- hw) (- hh) hd   hw (- hh) hd
                hw hh hd          (- hw) hh hd
                0.0 0.0 1.0)
      ;; Back face (-Z)
      (add-face 1
                hw (- hh) (- hd)   (- hw) (- hh) (- hd)
                (- hw) hh (- hd)   hw hh (- hd)
                0.0 0.0 -1.0)
      ;; Right face (+X)
      (add-face 2
                hw (- hh) hd       hw (- hh) (- hd)
                hw hh (- hd)       hw hh hd
                1.0 0.0 0.0)
      ;; Left face (-X)
      (add-face 3
                (- hw) (- hh) (- hd)   (- hw) (- hh) hd
                (- hw) hh hd           (- hw) hh (- hd)
                -1.0 0.0 0.0)
      ;; Top face (+Y)
      (add-face 4
                (- hw) hh hd       hw hh hd
                hw hh (- hd)       (- hw) hh (- hd)
                0.0 1.0 0.0)
      ;; Bottom face (-Y)
      (add-face 5
                (- hw) (- hh) (- hd)   hw (- hh) (- hd)
                hw (- hh) hd           (- hw) (- hh) hd
                0.0 -1.0 0.0))

    (make-mesh :vertices vertices
               :indices indices
               :normals norms
               :tex-coords uvs
               :dimensions 3)))

(defun make-cube (size &key normals tex-coords)
  "Generate a cube with given SIZE centered at origin.

   Options:
   - NORMALS: Generate per-vertex normals
   - TEX-COORDS: Generate texture coordinates"
  (make-box size size size :normals normals :tex-coords tex-coords))

(defun make-sphere (radius slices stacks &key normals tex-coords)
  "Generate a UV sphere with given RADIUS.
   SLICES: longitude divisions
   STACKS: latitude divisions

   Options:
   - NORMALS: Generate per-vertex normals
   - TEX-COORDS: Generate texture coordinates"
  (let* ((vertex-count (* (1+ slices) (1+ stacks)))
         (tri-count (* 2 slices stacks))
         (vertices (make-vertex-array vertex-count 3))
         (indices (make-index-array (* tri-count 3)))
         (norms (when normals (make-vertex-array vertex-count 3)))
         (uvs (when tex-coords (make-texcoord-array vertex-count)))
         (r (sf radius)))

    ;; Generate vertices
    (dotimes (j (1+ stacks))
      (dotimes (i (1+ slices))
        (let* ((idx (+ i (* j (1+ slices))))
               (u (/ (sf i) (sf slices)))
               (v (/ (sf j) (sf stacks)))
               (theta (* u +tau+))
               (phi (* v +pi+))
               (sin-phi (sin phi))
               (cos-phi (cos phi))
               (nx (* sin-phi (cos theta)))
               (ny cos-phi)
               (nz (* sin-phi (sin theta)))
               (x (* r nx))
               (y (* r ny))
               (z (* r nz)))
          (set-vertex-3d vertices idx x y z)
          (when normals
            (set-vertex-3d norms idx nx ny nz))
          (when tex-coords
            (set-texcoord uvs idx u v)))))

    ;; Generate triangles
    (let ((tri-idx 0)
          (cols (1+ slices)))
      (dotimes (j stacks)
        (dotimes (i slices)
          (let ((bl (+ i (* j cols)))
                (br (+ i 1 (* j cols)))
                (tl (+ i (* (1+ j) cols)))
                (tr (+ i 1 (* (1+ j) cols))))
            (set-triangle indices tri-idx bl br tr)
            (incf tri-idx)
            (set-triangle indices tri-idx bl tr tl)
            (incf tri-idx)))))

    (make-mesh :vertices vertices
               :indices indices
               :normals norms
               :tex-coords uvs
               :dimensions 3)))

(defun make-hemisphere (radius slices stacks &key normals tex-coords)
  "Generate a hemisphere (dome) with given RADIUS, open at the bottom.
   SLICES: longitude divisions
   STACKS: latitude divisions (for the half-sphere)

   Options:
   - NORMALS: Generate per-vertex normals
   - TEX-COORDS: Generate texture coordinates"
  (let* ((vertex-count (* (1+ slices) (1+ stacks)))
         (tri-count (* 2 slices stacks))
         (vertices (make-vertex-array vertex-count 3))
         (indices (make-index-array (* tri-count 3)))
         (norms (when normals (make-vertex-array vertex-count 3)))
         (uvs (when tex-coords (make-texcoord-array vertex-count)))
         (r (sf radius)))

    ;; Generate vertices (only upper half, phi from 0 to pi/2)
    (dotimes (j (1+ stacks))
      (dotimes (i (1+ slices))
        (let* ((idx (+ i (* j (1+ slices))))
               (u (/ (sf i) (sf slices)))
               (v (/ (sf j) (sf stacks)))
               (theta (* u +tau+))
               (phi (* v (/ +pi+ 2.0)))  ; 0 to pi/2
               (sin-phi (sin phi))
               (cos-phi (cos phi))
               (nx (* sin-phi (cos theta)))
               (ny cos-phi)
               (nz (* sin-phi (sin theta)))
               (x (* r nx))
               (y (* r ny))
               (z (* r nz)))
          (set-vertex-3d vertices idx x y z)
          (when normals
            (set-vertex-3d norms idx nx ny nz))
          (when tex-coords
            (set-texcoord uvs idx u v)))))

    ;; Generate triangles
    (let ((tri-idx 0)
          (cols (1+ slices)))
      (dotimes (j stacks)
        (dotimes (i slices)
          (let ((bl (+ i (* j cols)))
                (br (+ i 1 (* j cols)))
                (tl (+ i (* (1+ j) cols)))
                (tr (+ i 1 (* (1+ j) cols))))
            (set-triangle indices tri-idx bl br tr)
            (incf tri-idx)
            (set-triangle indices tri-idx bl tr tl)
            (incf tri-idx)))))

    (make-mesh :vertices vertices
               :indices indices
               :normals norms
               :tex-coords uvs
               :dimensions 3)))

(defun make-cylinder (radius height slices stacks &key normals tex-coords)
  "Generate a cylinder along the Y axis centered at origin.
   SLICES: radial divisions
   STACKS: height divisions

   Options:
   - NORMALS: Generate per-vertex normals
   - TEX-COORDS: Generate texture coordinates"
  (let* (;; Body vertices
         (body-verts (* (1+ slices) (1+ stacks)))
         ;; Top and bottom caps: center + ring vertices each
         (cap-verts (* 2 (1+ slices)))
         (vertex-count (+ body-verts cap-verts))
         ;; Body triangles + cap triangles
         (body-tris (* 2 slices stacks))
         (cap-tris (* 2 slices))
         (tri-count (+ body-tris cap-tris))
         (vertices (make-vertex-array vertex-count 3))
         (indices (make-index-array (* tri-count 3)))
         (norms (when normals (make-vertex-array vertex-count 3)))
         (uvs (when tex-coords (make-texcoord-array vertex-count)))
         (r (sf radius))
         (hh (/ (sf height) 2.0)))

    ;; Body vertices
    (dotimes (j (1+ stacks))
      (dotimes (i (1+ slices))
        (let* ((idx (+ i (* j (1+ slices))))
               (u (/ (sf i) (sf slices)))
               (v (/ (sf j) (sf stacks)))
               (theta (* u +tau+))
               (nx (cos theta))
               (nz (sin theta))
               (x (* r nx))
               (y (- (* v (sf height)) hh))
               (z (* r nz)))
          (set-vertex-3d vertices idx x y z)
          (when normals
            (set-vertex-3d norms idx nx 0.0 nz))
          (when tex-coords
            (set-texcoord uvs idx u v)))))

    ;; Body triangles
    (let ((tri-idx 0)
          (cols (1+ slices)))
      (dotimes (j stacks)
        (dotimes (i slices)
          (let ((bl (+ i (* j cols)))
                (br (+ i 1 (* j cols)))
                (tl (+ i (* (1+ j) cols)))
                (tr (+ i 1 (* (1+ j) cols))))
            (set-triangle indices tri-idx bl br tr)
            (incf tri-idx)
            (set-triangle indices tri-idx bl tr tl)
            (incf tri-idx))))

      ;; Top cap
      (let ((base-idx body-verts))
        ;; Center vertex
        (set-vertex-3d vertices base-idx 0.0 hh 0.0)
        (when normals
          (set-vertex-3d norms base-idx 0.0 1.0 0.0))
        (when tex-coords
          (set-texcoord uvs base-idx 0.5 0.5))
        ;; Ring vertices
        (dotimes (i slices)
          (let* ((vidx (+ base-idx 1 i))
                 (theta (* +tau+ (/ (sf i) (sf slices))))
                 (x (* r (cos theta)))
                 (z (* r (sin theta))))
            (set-vertex-3d vertices vidx x hh z)
            (when normals
              (set-vertex-3d norms vidx 0.0 1.0 0.0))
            (when tex-coords
              (set-texcoord uvs vidx
                            (+ 0.5 (* 0.5 (cos theta)))
                            (+ 0.5 (* 0.5 (sin theta)))))))
        ;; Top cap triangles
        (dotimes (i slices)
          (let ((next (mod (1+ i) slices)))
            (set-triangle indices tri-idx base-idx
                          (+ base-idx 1 next)
                          (+ base-idx 1 i))
            (incf tri-idx))))

      ;; Bottom cap
      (let ((base-idx (+ body-verts 1 slices)))
        ;; Center vertex
        (set-vertex-3d vertices base-idx 0.0 (- hh) 0.0)
        (when normals
          (set-vertex-3d norms base-idx 0.0 -1.0 0.0))
        (when tex-coords
          (set-texcoord uvs base-idx 0.5 0.5))
        ;; Ring vertices
        (dotimes (i slices)
          (let* ((vidx (+ base-idx 1 i))
                 (theta (* +tau+ (/ (sf i) (sf slices))))
                 (x (* r (cos theta)))
                 (z (* r (sin theta))))
            (set-vertex-3d vertices vidx x (- hh) z)
            (when normals
              (set-vertex-3d norms vidx 0.0 -1.0 0.0))
            (when tex-coords
              (set-texcoord uvs vidx
                            (+ 0.5 (* 0.5 (cos theta)))
                            (+ 0.5 (* 0.5 (sin theta)))))))
        ;; Bottom cap triangles (reversed winding)
        (dotimes (i slices)
          (let ((next (mod (1+ i) slices)))
            (set-triangle indices tri-idx base-idx
                          (+ base-idx 1 i)
                          (+ base-idx 1 next))
            (incf tri-idx)))))

    (make-mesh :vertices vertices
               :indices indices
               :normals norms
               :tex-coords uvs
               :dimensions 3)))

(defun make-cone (radius height slices stacks &key normals tex-coords)
  "Generate a cone along the Y axis with base centered at origin.
   SLICES: radial divisions
   STACKS: height divisions

   Options:
   - NORMALS: Generate per-vertex normals
   - TEX-COORDS: Generate texture coordinates"
  ;; Body vertices: (stacks+1) rings, but top ring is a single point
  (let* ((body-verts (+ (* slices stacks) 1))
         ;; Bottom cap
         (cap-verts (1+ slices))
         (vertex-count (+ body-verts cap-verts))
         (body-tris (* 2 slices (1- stacks)))
         (top-tris slices)  ; triangles meeting at apex
         (cap-tris slices)
         (tri-count (+ body-tris top-tris cap-tris))
         (vertices (make-vertex-array vertex-count 3))
         (indices (make-index-array (* tri-count 3)))
         (norms (when normals (make-vertex-array vertex-count 3)))
         (uvs (when tex-coords (make-texcoord-array vertex-count)))
         (r (sf radius))
         (h (sf height))
         ;; Normal slope angle
         (slope-angle (atan r h))
         (ny (sin slope-angle))
         (nr (cos slope-angle)))

    ;; Body vertices (rings from bottom to top, apex is last)
    (let ((vidx 0))
      (dotimes (j stacks)
        (let* ((v (/ (sf j) (sf stacks)))
               (ring-r (* r (- 1.0 v)))
               (y (* v h)))
          (dotimes (i slices)
            (let* ((u (/ (sf i) (sf slices)))
                   (theta (* u +tau+))
                   (cos-t (cos theta))
                   (sin-t (sin theta))
                   (x (* ring-r cos-t))
                   (z (* ring-r sin-t)))
              (set-vertex-3d vertices vidx x y z)
              (when normals
                (set-vertex-3d norms vidx (* nr cos-t) ny (* nr sin-t)))
              (when tex-coords
                (set-texcoord uvs vidx u v))
              (incf vidx)))))
      ;; Apex vertex
      (set-vertex-3d vertices vidx 0.0 h 0.0)
      (when normals
        (set-vertex-3d norms vidx 0.0 1.0 0.0))
      (when tex-coords
        (set-texcoord uvs vidx 0.5 1.0)))

    ;; Body triangles
    (let ((tri-idx 0)
          (apex-idx (* slices stacks)))
      ;; Quad strips for rings (except last ring to apex)
      (dotimes (j (1- stacks))
        (dotimes (i slices)
          (let ((bl (+ i (* j slices)))
                (br (+ (mod (1+ i) slices) (* j slices)))
                (tl (+ i (* (1+ j) slices)))
                (tr (+ (mod (1+ i) slices) (* (1+ j) slices))))
            (set-triangle indices tri-idx bl br tr)
            (incf tri-idx)
            (set-triangle indices tri-idx bl tr tl)
            (incf tri-idx))))
      ;; Triangles to apex
      (let ((last-ring-base (* slices (1- stacks))))
        (dotimes (i slices)
          (let ((curr (+ last-ring-base i))
                (next (+ last-ring-base (mod (1+ i) slices))))
            (set-triangle indices tri-idx curr next apex-idx)
            (incf tri-idx))))

      ;; Bottom cap
      (let ((base-idx (1+ apex-idx)))
        ;; Center vertex
        (set-vertex-3d vertices base-idx 0.0 0.0 0.0)
        (when normals
          (set-vertex-3d norms base-idx 0.0 -1.0 0.0))
        (when tex-coords
          (set-texcoord uvs base-idx 0.5 0.5))
        ;; Ring vertices
        (dotimes (i slices)
          (let* ((vidx (+ base-idx 1 i))
                 (theta (* +tau+ (/ (sf i) (sf slices))))
                 (x (* r (cos theta)))
                 (z (* r (sin theta))))
            (set-vertex-3d vertices vidx x 0.0 z)
            (when normals
              (set-vertex-3d norms vidx 0.0 -1.0 0.0))
            (when tex-coords
              (set-texcoord uvs vidx
                            (+ 0.5 (* 0.5 (cos theta)))
                            (+ 0.5 (* 0.5 (sin theta)))))))
        ;; Bottom cap triangles (reversed winding)
        (dotimes (i slices)
          (let ((next (mod (1+ i) slices)))
            (set-triangle indices tri-idx base-idx
                          (+ base-idx 1 i)
                          (+ base-idx 1 next))
            (incf tri-idx)))))

    (make-mesh :vertices vertices
               :indices indices
               :normals norms
               :tex-coords uvs
               :dimensions 3)))

(defun make-torus (major-radius minor-radius slices stacks &key normals tex-coords)
  "Generate a torus centered at origin in the XZ plane.
   MAJOR-RADIUS: distance from center to tube center
   MINOR-RADIUS: tube radius
   SLICES: divisions around the tube
   STACKS: divisions around the torus

   Options:
   - NORMALS: Generate per-vertex normals
   - TEX-COORDS: Generate texture coordinates"
  (let* ((vertex-count (* (1+ slices) (1+ stacks)))
         (tri-count (* 2 slices stacks))
         (vertices (make-vertex-array vertex-count 3))
         (indices (make-index-array (* tri-count 3)))
         (norms (when normals (make-vertex-array vertex-count 3)))
         (uvs (when tex-coords (make-texcoord-array vertex-count)))
         (R (sf major-radius))
         (r (sf minor-radius)))

    ;; Generate vertices
    (dotimes (j (1+ stacks))
      (dotimes (i (1+ slices))
        (let* ((idx (+ i (* j (1+ slices))))
               (u (/ (sf i) (sf slices)))
               (v (/ (sf j) (sf stacks)))
               (theta (* u +tau+))  ; angle around tube
               (phi (* v +tau+))    ; angle around torus
               (cos-theta (cos theta))
               (sin-theta (sin theta))
               (cos-phi (cos phi))
               (sin-phi (sin phi))
               ;; Center of tube ring at this phi
               (cx (* R cos-phi))
               (cz (* R sin-phi))
               ;; Point on tube surface
               (x (* (+ R (* r cos-theta)) cos-phi))
               (y (* r sin-theta))
               (z (* (+ R (* r cos-theta)) sin-phi))
               ;; Normal
               (nx (* cos-theta cos-phi))
               (ny sin-theta)
               (nz (* cos-theta sin-phi)))
          (set-vertex-3d vertices idx x y z)
          (when normals
            (set-vertex-3d norms idx nx ny nz))
          (when tex-coords
            (set-texcoord uvs idx u v)))))

    ;; Generate triangles
    (let ((tri-idx 0)
          (cols (1+ slices)))
      (dotimes (j stacks)
        (dotimes (i slices)
          (let ((bl (+ i (* j cols)))
                (br (+ i 1 (* j cols)))
                (tl (+ i (* (1+ j) cols)))
                (tr (+ i 1 (* (1+ j) cols))))
            (set-triangle indices tri-idx bl br tr)
            (incf tri-idx)
            (set-triangle indices tri-idx bl tr tl)
            (incf tri-idx)))))

    (make-mesh :vertices vertices
               :indices indices
               :normals norms
               :tex-coords uvs
               :dimensions 3)))

(defun make-icosphere (radius subdivisions &key normals tex-coords)
  "Generate an icosphere by subdividing an icosahedron.
   SUBDIVISIONS: number of subdivision iterations (0 = icosahedron)

   Options:
   - NORMALS: Generate per-vertex normals
   - TEX-COORDS: Generate texture coordinates"
  ;; Start with icosahedron vertices
  (let* ((t-val (/ (+ 1.0 (sqrt 5.0)) 2.0))  ; golden ratio
         (initial-verts (list
                         ;; Vertices on XY plane rectangles
                         (list (- 1.0) t-val 0.0)
                         (list 1.0 t-val 0.0)
                         (list (- 1.0) (- t-val) 0.0)
                         (list 1.0 (- t-val) 0.0)
                         ;; Vertices on XZ plane rectangles
                         (list 0.0 (- 1.0) t-val)
                         (list 0.0 1.0 t-val)
                         (list 0.0 (- 1.0) (- t-val))
                         (list 0.0 1.0 (- t-val))
                         ;; Vertices on YZ plane rectangles
                         (list t-val 0.0 (- 1.0))
                         (list t-val 0.0 1.0)
                         (list (- t-val) 0.0 (- 1.0))
                         (list (- t-val) 0.0 1.0)))
         (initial-faces (list
                         ;; Faces around vertex 0
                         '(0 11 5) '(0 5 1) '(0 1 7) '(0 7 10) '(0 10 11)
                         ;; Adjacent faces
                         '(1 5 9) '(5 11 4) '(11 10 2) '(10 7 6) '(7 1 8)
                         ;; Faces around vertex 3
                         '(3 9 4) '(3 4 2) '(3 2 6) '(3 6 8) '(3 8 9)
                         ;; Adjacent faces
                         '(4 9 5) '(2 4 11) '(6 2 10) '(8 6 7) '(9 8 1)))
         (vert-cache (make-hash-table :test 'equal))
         (current-verts (make-array 12 :adjustable t :fill-pointer 0))
         (current-faces (make-array 20 :adjustable t :fill-pointer 0)))

    ;; Initialize vertices (normalized to unit sphere)
    (dolist (v initial-verts)
      (multiple-value-bind (nx ny nz)
          (vec3-normalize (sf (first v)) (sf (second v)) (sf (third v)))
        (vector-push-extend (list nx ny nz) current-verts)))

    ;; Initialize faces
    (dolist (f initial-faces)
      (vector-push-extend f current-faces))

    ;; Subdivision
    (labels ((midpoint-index (i1 i2)
               ;; Get or create midpoint vertex between vertices i1 and i2
               (let ((key (if (< i1 i2) (cons i1 i2) (cons i2 i1))))
                 (or (gethash key vert-cache)
                     (let* ((v1 (aref current-verts i1))
                            (v2 (aref current-verts i2))
                            (mx (/ (+ (first v1) (first v2)) 2.0))
                            (my (/ (+ (second v1) (second v2)) 2.0))
                            (mz (/ (+ (third v1) (third v2)) 2.0)))
                       (multiple-value-bind (nx ny nz) (vec3-normalize mx my mz)
                         (let ((idx (fill-pointer current-verts)))
                           (vector-push-extend (list nx ny nz) current-verts)
                           (setf (gethash key vert-cache) idx)
                           idx)))))))

      (dotimes (sub subdivisions)
        (let ((new-faces (make-array (* 4 (length current-faces))
                                     :adjustable t :fill-pointer 0)))
          (loop for face across current-faces do
            (let* ((i0 (first face))
                   (i1 (second face))
                   (i2 (third face))
                   (a (midpoint-index i0 i1))
                   (b (midpoint-index i1 i2))
                   (c (midpoint-index i2 i0)))
              (vector-push-extend (list i0 a c) new-faces)
              (vector-push-extend (list i1 b a) new-faces)
              (vector-push-extend (list i2 c b) new-faces)
              (vector-push-extend (list a b c) new-faces)))
          (setf current-faces new-faces)
          (clrhash vert-cache))))

    ;; Build final mesh
    (let* ((vertex-count (length current-verts))
           (tri-count (length current-faces))
           (vertices (make-vertex-array vertex-count 3))
           (indices (make-index-array (* tri-count 3)))
           (norms (when normals (make-vertex-array vertex-count 3)))
           (uvs (when tex-coords (make-texcoord-array vertex-count)))
           (r (sf radius)))

      ;; Copy vertices, scaled by radius
      (loop for i from 0 below vertex-count
            for v = (aref current-verts i) do
              (let ((nx (first v))
                    (ny (second v))
                    (nz (third v)))
                (set-vertex-3d vertices i (* r nx) (* r ny) (* r nz))
                (when normals
                  (set-vertex-3d norms i nx ny nz))
                (when tex-coords
                  ;; Spherical UV mapping
                  (let ((u (+ 0.5 (/ (atan nz nx) +tau+)))
                        (v (+ 0.5 (/ (asin ny) +pi+))))
                    (set-texcoord uvs i u v)))))

      ;; Copy faces
      (loop for i from 0 below tri-count
            for f = (aref current-faces i) do
              (set-triangle indices i (first f) (second f) (third f)))

      (make-mesh :vertices vertices
                 :indices indices
                 :normals norms
                 :tex-coords uvs
                 :dimensions 3))))

(defun make-capsule (radius height slices stacks &key normals tex-coords)
  "Generate a capsule (pill shape) along the Y axis centered at origin.
   RADIUS: radius of the capsule (both cylinder and hemisphere caps)
   HEIGHT: height of the cylindrical part (total height = height + 2*radius)
   SLICES: radial divisions
   STACKS: divisions for each hemisphere cap

   Options:
   - NORMALS: Generate per-vertex normals
   - TEX-COORDS: Generate texture coordinates"
  ;; Cylinder body vertices (without caps, just the tube)
  (let* ((body-rows 2)  ; top and bottom edge rings
         (body-verts (* (1+ slices) body-rows))
         ;; Each hemisphere cap
         (cap-verts (* (1+ slices) (1+ stacks)))
         (total-verts (+ body-verts (* 2 cap-verts)))
         ;; Body triangles
         (body-tris (* 2 slices))
         ;; Each hemisphere cap triangles
         (cap-tris (* 2 slices stacks))
         (total-tris (+ body-tris (* 2 cap-tris)))
         (vertices (make-vertex-array total-verts 3))
         (indices (make-index-array (* total-tris 3)))
         (norms (when normals (make-vertex-array total-verts 3)))
         (uvs (when tex-coords (make-texcoord-array total-verts)))
         (r (sf radius))
         (hh (/ (sf height) 2.0)))

    ;; Cylinder body vertices (two rings)
    (dotimes (j body-rows)
      (dotimes (i (1+ slices))
        (let* ((idx (+ i (* j (1+ slices))))
               (u (/ (sf i) (sf slices)))
               (theta (* u +tau+))
               (nx (cos theta))
               (nz (sin theta))
               (x (* r nx))
               (y (if (zerop j) (- hh) hh))
               (z (* r nz)))
          (set-vertex-3d vertices idx x y z)
          (when normals
            (set-vertex-3d norms idx nx 0.0 nz))
          (when tex-coords
            (set-texcoord uvs idx u (if (zerop j) 0.25 0.75))))))

    ;; Cylinder body triangles
    (let ((tri-idx 0)
          (cols (1+ slices)))
      (dotimes (i slices)
        (let ((bl i)
              (br (1+ i))
              (tl (+ i cols))
              (tr (+ i 1 cols)))
          (set-triangle indices tri-idx bl br tr)
          (incf tri-idx)
          (set-triangle indices tri-idx bl tr tl)
          (incf tri-idx)))

      ;; Top hemisphere (above y = hh)
      (let ((base-idx body-verts))
        (dotimes (j (1+ stacks))
          (dotimes (i (1+ slices))
            (let* ((idx (+ base-idx i (* j (1+ slices))))
                   (u (/ (sf i) (sf slices)))
                   (v (/ (sf j) (sf stacks)))
                   (theta (* u +tau+))
                   (phi (* v (/ +pi+ 2.0)))  ; 0 to pi/2
                   (sin-phi (sin phi))
                   (cos-phi (cos phi))
                   (nx (* cos-phi (cos theta)))
                   (ny sin-phi)
                   (nz (* cos-phi (sin theta)))
                   (x (* r nx))
                   (y (+ hh (* r ny)))
                   (z (* r nz)))
              (set-vertex-3d vertices idx x y z)
              (when normals
                (set-vertex-3d norms idx nx ny nz))
              (when tex-coords
                (set-texcoord uvs idx u (+ 0.75 (* 0.25 v)))))))
        ;; Top hemisphere triangles
        (dotimes (j stacks)
          (dotimes (i slices)
            (let ((bl (+ base-idx i (* j (1+ slices))))
                  (br (+ base-idx i 1 (* j (1+ slices))))
                  (tl (+ base-idx i (* (1+ j) (1+ slices))))
                  (tr (+ base-idx i 1 (* (1+ j) (1+ slices)))))
              (set-triangle indices tri-idx bl br tr)
              (incf tri-idx)
              (set-triangle indices tri-idx bl tr tl)
              (incf tri-idx)))))

      ;; Bottom hemisphere (below y = -hh)
      (let ((base-idx (+ body-verts cap-verts)))
        (dotimes (j (1+ stacks))
          (dotimes (i (1+ slices))
            (let* ((idx (+ base-idx i (* j (1+ slices))))
                   (u (/ (sf i) (sf slices)))
                   (v (/ (sf j) (sf stacks)))
                   (theta (* u +tau+))
                   (phi (* v (/ +pi+ 2.0)))  ; 0 to pi/2
                   (sin-phi (sin phi))
                   (cos-phi (cos phi))
                   (nx (* cos-phi (cos theta)))
                   (ny (- sin-phi))  ; pointing down
                   (nz (* cos-phi (sin theta)))
                   (x (* r nx))
                   (y (- (- hh) (* r sin-phi)))
                   (z (* r nz)))
              (set-vertex-3d vertices idx x y z)
              (when normals
                (set-vertex-3d norms idx nx ny nz))
              (when tex-coords
                (set-texcoord uvs idx u (- 0.25 (* 0.25 v)))))))
        ;; Bottom hemisphere triangles (reversed winding)
        (dotimes (j stacks)
          (dotimes (i slices)
            (let ((bl (+ base-idx i (* j (1+ slices))))
                  (br (+ base-idx i 1 (* j (1+ slices))))
                  (tl (+ base-idx i (* (1+ j) (1+ slices))))
                  (tr (+ base-idx i 1 (* (1+ j) (1+ slices)))))
              (set-triangle indices tri-idx bl tr br)
              (incf tri-idx)
              (set-triangle indices tri-idx bl tl tr)
              (incf tri-idx))))))

    (make-mesh :vertices vertices
               :indices indices
               :normals norms
               :tex-coords uvs
               :dimensions 3)))
