;;;; utilities.lisp
;;;; Mesh utility functions for common-shapes

(in-package #:common-shapes)

(defun compute-normals (mesh)
  "Compute per-vertex normals for a mesh by averaging adjacent face normals.
   Returns a new mesh with normals computed. Only works for 3D meshes."
  (unless (= (mesh-dimensions mesh) 3)
    (error "compute-normals only works with 3D meshes"))

  (let* ((vertices (mesh-vertices mesh))
         (indices (mesh-indices mesh))
         (vert-count (vertex-count mesh))
         (tri-count (triangle-count mesh))
         ;; Accumulate normals per vertex
         (normal-accum (make-array vert-count :initial-element nil)))

    ;; Initialize accumulators
    (dotimes (i vert-count)
      (setf (aref normal-accum i) (v:vec3 0.0 0.0 0.0)))

    ;; Compute and accumulate face normals
    (dotimes (tri tri-count)
      (let* ((base (* tri 3))
             (i0 (aref indices base))
             (i1 (aref indices (+ base 1)))
             (i2 (aref indices (+ base 2)))
             (v0 (get-vertex-3d vertices i0))
             (v1 (get-vertex-3d vertices i1))
             (v2 (get-vertex-3d vertices i2))
             (face-normal (triangle-normal v0 v1 v2)))
        ;; Add to each vertex's normal accumulator
        (setf (aref normal-accum i0) (v:v+ (aref normal-accum i0) face-normal))
        (setf (aref normal-accum i1) (v:v+ (aref normal-accum i1) face-normal))
        (setf (aref normal-accum i2) (v:v+ (aref normal-accum i2) face-normal))))

    ;; Normalize accumulated normals and build array
    (let ((normals (make-vertex-array vert-count 3)))
      (dotimes (i vert-count)
        (let ((n (v:vunit (aref normal-accum i))))
          (set-vertex-3d-v normals i n)))

      ;; Return new mesh with normals
      (make-mesh :vertices (copy-seq vertices)
                 :indices (copy-seq indices)
                 :normals normals
                 :tex-coords (when (mesh-tex-coords mesh)
                               (copy-seq (mesh-tex-coords mesh)))
                 :dimensions 3))))

(defun compute-aabb (mesh)
  "Compute the axis-aligned bounding box of a mesh.
   Returns two lists: (min-x min-y [min-z]) and (max-x max-y [max-z])."
  (let* ((vertices (mesh-vertices mesh))
         (dims (mesh-dimensions mesh))
         (count (vertex-count mesh)))

    (when (zerop count)
      (return-from compute-aabb
        (if (= dims 3)
            (values (list 0.0 0.0 0.0) (list 0.0 0.0 0.0))
            (values (list 0.0 0.0) (list 0.0 0.0)))))

    (if (= dims 3)
        (let ((min-x most-positive-single-float)
              (min-y most-positive-single-float)
              (min-z most-positive-single-float)
              (max-x most-negative-single-float)
              (max-y most-negative-single-float)
              (max-z most-negative-single-float))
          (dotimes (i count)
            (let ((v (get-vertex-3d vertices i)))
              (setf min-x (min min-x (v:vx3 v))
                    min-y (min min-y (v:vy3 v))
                    min-z (min min-z (v:vz3 v))
                    max-x (max max-x (v:vx3 v))
                    max-y (max max-y (v:vy3 v))
                    max-z (max max-z (v:vz3 v)))))
          (values (list min-x min-y min-z) (list max-x max-y max-z)))
        (let ((min-x most-positive-single-float)
              (min-y most-positive-single-float)
              (max-x most-negative-single-float)
              (max-y most-negative-single-float))
          (dotimes (i count)
            (let ((v (get-vertex-2d vertices i)))
              (setf min-x (min min-x (v:vx2 v))
                    min-y (min min-y (v:vy2 v))
                    max-x (max max-x (v:vx2 v))
                    max-y (max max-y (v:vy2 v)))))
          (values (list min-x min-y) (list max-x max-y))))))

(defun merge-meshes (mesh1 mesh2)
  "Combine two meshes into a single mesh. Both meshes must have the same dimensions."
  (unless (= (mesh-dimensions mesh1) (mesh-dimensions mesh2))
    (error "Cannot merge meshes with different dimensions"))

  (let* ((dims (mesh-dimensions mesh1))
         (vert-count1 (vertex-count mesh1))
         (vert-count2 (vertex-count mesh2))
         (tri-count1 (triangle-count mesh1))
         (tri-count2 (triangle-count mesh2))
         (total-verts (+ vert-count1 vert-count2))
         (total-tris (+ tri-count1 tri-count2))
         ;; New arrays
         (vertices (make-vertex-array total-verts dims))
         (indices (make-index-array (* total-tris 3)))
         ;; Optional arrays
         (has-normals (and (mesh-normals mesh1) (mesh-normals mesh2)))
         (has-texcoords (and (mesh-tex-coords mesh1) (mesh-tex-coords mesh2)))
         (normals (when has-normals (make-vertex-array total-verts 3)))
         (tex-coords (when has-texcoords (make-texcoord-array total-verts))))

    ;; Copy mesh1 vertices
    (replace vertices (mesh-vertices mesh1))
    ;; Copy mesh2 vertices (offset)
    (replace vertices (mesh-vertices mesh2) :start1 (* vert-count1 dims))

    ;; Copy mesh1 indices
    (replace indices (mesh-indices mesh1))
    ;; Copy mesh2 indices (with vertex offset)
    (dotimes (i (* tri-count2 3))
      (setf (aref indices (+ (* tri-count1 3) i))
            (+ (aref (mesh-indices mesh2) i) vert-count1)))

    ;; Copy normals if both have them
    (when has-normals
      (replace normals (mesh-normals mesh1))
      (replace normals (mesh-normals mesh2) :start1 (* vert-count1 3)))

    ;; Copy texture coordinates if both have them
    (when has-texcoords
      (replace tex-coords (mesh-tex-coords mesh1))
      (replace tex-coords (mesh-tex-coords mesh2) :start1 (* vert-count1 2)))

    (make-mesh :vertices vertices
               :indices indices
               :normals normals
               :tex-coords tex-coords
               :dimensions dims)))

(defun transform-mesh (mesh matrix)
  "Apply a 4x4 transformation matrix to a mesh. Returns a new transformed mesh.
   Properly transforms both vertices and normals."
  (let* ((dims (mesh-dimensions mesh))
         (vert-count (vertex-count mesh))
         (new-vertices (make-vertex-array vert-count dims))
         (new-normals nil))

    ;; Transform vertices
    (if (= dims 3)
        ;; 3D transformation
        (dotimes (i vert-count)
          (let* ((v (get-vertex-3d (mesh-vertices mesh) i))
                 (transformed (m:m* matrix v)))
            (set-vertex-3d-v new-vertices i transformed)))
        ;; 2D transformation (treat as 3D with z=0)
        (dotimes (i vert-count)
          (let* ((v2 (get-vertex-2d (mesh-vertices mesh) i))
                 (v3 (v:vec3 (v:vx2 v2) (v:vy2 v2) 0.0))
                 (transformed (m:m* matrix v3)))
            (set-vertex-2d new-vertices i
                           (v:vx3 transformed)
                           (v:vy3 transformed)))))

    ;; Transform normals if present
    (when (mesh-normals mesh)
      (setf new-normals (transform-normals (mesh-normals mesh) matrix)))

    (make-mesh :vertices new-vertices
               :indices (copy-seq (mesh-indices mesh))
               :normals new-normals
               :tex-coords (when (mesh-tex-coords mesh)
                             (copy-seq (mesh-tex-coords mesh)))
               :dimensions dims)))

(defun flip-winding (mesh)
  "Reverse the winding order of all triangles in a mesh. Returns a new mesh.
   This also flips normals if present."
  (let* ((tri-count (triangle-count mesh))
         (new-indices (make-index-array (* tri-count 3)))
         (indices (mesh-indices mesh)))

    ;; Reverse each triangle's winding
    (dotimes (tri tri-count)
      (let ((base (* tri 3)))
        (setf (aref new-indices base) (aref indices base)
              (aref new-indices (+ base 1)) (aref indices (+ base 2))
              (aref new-indices (+ base 2)) (aref indices (+ base 1)))))

    ;; Flip normals if present
    (let ((new-normals nil))
      (when (mesh-normals mesh)
        (let ((normals (mesh-normals mesh))
              (count (length (mesh-normals mesh))))
          (setf new-normals (make-array count :element-type 'single-float))
          (dotimes (i count)
            (setf (aref new-normals i) (- (aref normals i))))))

      (make-mesh :vertices (copy-seq (mesh-vertices mesh))
                 :indices new-indices
                 :normals new-normals
                 :tex-coords (when (mesh-tex-coords mesh)
                               (copy-seq (mesh-tex-coords mesh)))
                 :dimensions (mesh-dimensions mesh)))))

(defun translate-mesh (mesh x y &optional (z 0.0))
  "Translate a mesh by (x, y, z). Returns a new mesh."
  (transform-mesh mesh (m:mtranslation (v:vec3 (sf x) (sf y) (sf z)))))

(defun scale-mesh (mesh sx &optional sy sz)
  "Scale a mesh by (sx, sy, sz). If only sx is given, uniform scale.
   Returns a new mesh."
  (let ((sy (or sy sx))
        (sz (or sz sx)))
    (transform-mesh mesh (m:mscaling (v:vec3 (sf sx) (sf sy) (sf sz))))))

(defun rotate-mesh-x (mesh angle)
  "Rotate a mesh around the X axis by ANGLE radians. Returns a new mesh."
  (transform-mesh mesh (m:mrotation (v:vec3 1.0 0.0 0.0) (sf angle))))

(defun rotate-mesh-y (mesh angle)
  "Rotate a mesh around the Y axis by ANGLE radians. Returns a new mesh."
  (transform-mesh mesh (m:mrotation (v:vec3 0.0 1.0 0.0) (sf angle))))

(defun rotate-mesh-z (mesh angle)
  "Rotate a mesh around the Z axis by ANGLE radians. Returns a new mesh."
  (transform-mesh mesh (m:mrotation (v:vec3 0.0 0.0 1.0) (sf angle))))

(defun center-mesh (mesh)
  "Translate a mesh so its center (AABB center) is at the origin. Returns a new mesh."
  (multiple-value-bind (min-bounds max-bounds) (compute-aabb mesh)
    (let ((dims (mesh-dimensions mesh)))
      (if (= dims 3)
          (let ((cx (/ (+ (first min-bounds) (first max-bounds)) 2.0))
                (cy (/ (+ (second min-bounds) (second max-bounds)) 2.0))
                (cz (/ (+ (third min-bounds) (third max-bounds)) 2.0)))
            (translate-mesh mesh (- cx) (- cy) (- cz)))
          (let ((cx (/ (+ (first min-bounds) (first max-bounds)) 2.0))
                (cy (/ (+ (second min-bounds) (second max-bounds)) 2.0)))
            (translate-mesh mesh (- cx) (- cy)))))))

(defun normalize-mesh (mesh)
  "Scale and translate a mesh so it fits in a unit cube/square centered at origin.
   Returns a new mesh."
  (multiple-value-bind (min-bounds max-bounds) (compute-aabb mesh)
    (let* ((dims (mesh-dimensions mesh))
           (centered (center-mesh mesh))
           (size (if (= dims 3)
                     (max (- (first max-bounds) (first min-bounds))
                          (- (second max-bounds) (second min-bounds))
                          (- (third max-bounds) (third min-bounds)))
                     (max (- (first max-bounds) (first min-bounds))
                          (- (second max-bounds) (second min-bounds))))))
      (if (zerop size)
          centered
          (scale-mesh centered (/ 1.0 size))))))
