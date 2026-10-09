;;;; csg.lisp
;;;; Constructive Solid Geometry - BSP-tree based boolean operations

(in-package #:cl-meshgen)

;; ---------- Internal polygon representation ----------

(defstruct csg-polygon
  (vertices nil)
  (normal nil))

(defun %vec3-dot (a b)
  (+ (* (v:vx3 a) (v:vx3 b))
     (* (v:vy3 a) (v:vy3 b))
     (* (v:vz3 a) (v:vz3 b))))

(defun %vec3-copy (v)
  (v:vec3 (v:vx3 v) (v:vy3 v) (v:vz3 v)))

(defun %csg-polygon-flip (poly)
  (setf (csg-polygon-vertices poly)
        (list (third (csg-polygon-vertices poly))
              (second (csg-polygon-vertices poly))
              (first (csg-polygon-vertices poly))))
  (setf (csg-polygon-normal poly)
        (v:v* (csg-polygon-normal poly) -1.0))
  poly)

;; ---------- BSP tree node ----------

(defstruct csg-node
  (plane-normal nil)
  (plane-constant 0.0 :type single-float)
  (front nil)
  (back nil)
  (polygons nil))

(defconstant +csg-epsilon+ 1.0e-6)

;; ---------- Polygon classification ----------

(defun %classify-vertex (v plane-normal plane-constant)
  (let ((dist (- (%vec3-dot v plane-normal) plane-constant)))
    (cond ((> dist +csg-epsilon+) :front)
          ((< dist (- +csg-epsilon+)) :back)
          (t :coplanar))))

(defun %classify-polygon (poly plane-normal plane-constant)
  (let ((front-count 0) (back-count 0))
    (dolist (v (csg-polygon-vertices poly))
      (case (%classify-vertex v plane-normal plane-constant)
        (:front (incf front-count))
        (:back (incf back-count))))
    (cond ((and (> front-count 0) (zerop back-count)) :front)
          ((and (> back-count 0) (zerop front-count)) :back)
          ((and (> front-count 0) (> back-count 0)) :spanning)
          (t :coplanar))))

;; ---------- Polygon splitting ----------

(defun %lerp (a b tt)
  (v:vec3 (+ (v:vx3 a) (* tt (- (v:vx3 b) (v:vx3 a))))
          (+ (v:vy3 a) (* tt (- (v:vy3 b) (v:vy3 a))))
          (+ (v:vz3 a) (* tt (- (v:vz3 b) (v:vz3 a))))))

(defun %triangulate-convex (vertices normal)
  "Fan-triangulate a convex polygon. Returns a list of csg-polygons."
  (let ((n (length vertices)))
    (when (< n 3) (return-from %triangulate-convex nil))
    (loop for i from 1 below (1- n)
          collect (make-csg-polygon
                   :vertices (list (first vertices)
                                   (nth i vertices)
                                   (nth (1+ i) vertices))
                   :normal normal))))

(defun %split-polygon (poly plane-normal plane-constant)
  (let* ((verts (csg-polygon-vertices poly))
         (normal (csg-polygon-normal poly))
         (n (length verts))
         (front-verts nil)
         (back-verts nil)
         (dists (make-array n :element-type 'single-float)))
    (dotimes (i n)
      (setf (aref dists i)
            (- (%vec3-dot (nth i verts) plane-normal) plane-constant)))
    (dotimes (i n)
      (let* ((j (mod (1+ i) n))
             (vi (nth i verts))
             (vj (nth j verts))
             (di (aref dists i))
             (dj (aref dists j)))
        (when (>= di (- +csg-epsilon+))
          (push vi front-verts))
        (when (<= di +csg-epsilon+)
          (push vi back-verts))
        (when (or (and (> di +csg-epsilon+) (< dj (- +csg-epsilon+)))
                  (and (< di (- +csg-epsilon+)) (> dj +csg-epsilon+)))
          (let ((denom (- di dj)))
            (when (not (< (abs denom) +csg-epsilon+))
              (let ((factor (/ di denom)))
                (let ((point (%lerp vi vj factor)))
                  (push point front-verts)
                  (push point back-verts))))))))
    (setf front-verts (nreverse front-verts)
          back-verts (nreverse back-verts))
    (values (when (>= (length front-verts) 3)
              (%triangulate-convex front-verts normal))
            (when (>= (length back-verts) 3)
              (%triangulate-convex back-verts normal)))))

;; ---------- BSP tree operations ----------

(defun %build-bsp-tree (polygons)
  "Build a BSP tree from a list of polygons. Returns the root node."
  (if (null polygons)
      nil
      (let* ((node (make-csg-node))
             (front-polys nil)
             (back-polys nil)
             (pivot (first polygons))
             (plane-normal (csg-polygon-normal pivot))
             (plane-constant (%vec3-dot plane-normal (first (csg-polygon-vertices pivot))))
             (remaining (rest polygons)))
        (setf (csg-node-plane-normal node) plane-normal)
        (setf (csg-node-plane-constant node) plane-constant)
        (dolist (poly remaining)
          (let ((type (%classify-polygon poly plane-normal plane-constant)))
            (case type
              (:coplanar
               (push poly (csg-node-polygons node)))
              (:front
               (push poly front-polys))
              (:back
               (push poly back-polys))
              (:spanning
                (multiple-value-bind (front-parts back-parts)
                    (%split-polygon poly plane-normal plane-constant)
                  (dolist (fp front-parts) (push fp front-polys))
                  (dolist (bp back-parts) (push bp back-polys)))))))
        (push pivot (csg-node-polygons node))
        (setf (csg-node-front node) (%build-bsp-tree (nreverse front-polys))
              (csg-node-back node) (%build-bsp-tree (nreverse back-polys)))
        node)))

(defun %clip-polygons (node polygons)
  "Clip POLYGONS against the BSP tree rooted at NODE.
   Returns only the parts of POLYGONS that are on the outside (front) of the solid."
  (if (null node)
      (copy-list polygons)
      (let (front back)
        (dolist (poly polygons)
          (let ((type (%classify-polygon poly
                                         (csg-node-plane-normal node)
                                         (csg-node-plane-constant node))))
            (case type
               (:coplanar
                (if (>= (%vec3-dot (csg-polygon-normal poly)
                                   (csg-node-plane-normal node)) 0)
                    (push poly front)
                    (push poly back)))
              (:front
               (push poly front))
              (:back
               (push poly back))
              (:spanning
               (multiple-value-bind (front-parts back-parts)
                   (%split-polygon poly
                                   (csg-node-plane-normal node)
                                   (csg-node-plane-constant node))
                 (dolist (fp front-parts) (push fp front))
                 (dolist (bp back-parts) (push bp back)))))))
        (let ((front-result (%clip-polygons (csg-node-front node) front))
              (back-result (if (csg-node-back node)
                               (%clip-polygons (csg-node-back node) back)
                               nil)))
          (append front-result back-result)))))

(defun %copy-polygon (poly)
  "Return a shallow copy of a CSG polygon."
  (make-csg-polygon
   :vertices (copy-list (csg-polygon-vertices poly))
   :normal (%vec3-copy (csg-polygon-normal poly))))

(defun %invert-bsp-tree (node)
  "Invert a BSP tree: swap front/back, negate plane, flip polygons.
   Operates non-destructively by copying the node and its polygons."
  (when node
    (let ((new-node (make-csg-node
                     :plane-normal (v:v* (csg-node-plane-normal node) -1.0)
                     :plane-constant (- (csg-node-plane-constant node))
                     :front (%invert-bsp-tree (csg-node-back node))
                     :back (%invert-bsp-tree (csg-node-front node))
                     :polygons (mapcar (lambda (p)
                                         (let ((new-p (%copy-polygon p)))
                                           (%csg-polygon-flip new-p)
                                           new-p))
                                        (csg-node-polygons node)))))
      new-node)))

;; ---------- Mesh conversion ----------

(defun %safe-triangle-normal (v0 v1 v2)
  (let* ((e1 (v:v- v1 v0))
         (e2 (v:v- v2 v0))
         (cross (v:vc e1 e2))
         (len (sqrt (+ (* (v:vx3 cross) (v:vx3 cross))
                       (* (v:vy3 cross) (v:vy3 cross))
                       (* (v:vz3 cross) (v:vz3 cross))))))
    (if (< len +csg-epsilon+)
        (v:vec3 0.0 1.0 0.0)
        (v:vec3 (/ (v:vx3 cross) len)
                (/ (v:vy3 cross) len)
                (/ (v:vz3 cross) len)))))

(defun %mesh-to-polygons (mesh)
  "Convert a 3D mesh to a list of CSG polygons."
  (let ((vertices (mesh-vertices mesh))
        (indices (mesh-indices mesh))
        (tri-count (triangle-count mesh))
        (polygons nil))
    (dotimes (tri tri-count)
      (let* ((base (* tri 3))
             (i0 (aref indices base))
             (i1 (aref indices (+ base 1)))
             (i2 (aref indices (+ base 2)))
             (v0 (get-vertex-3d vertices i0))
             (v1 (get-vertex-3d vertices i1))
             (v2 (get-vertex-3d vertices i2)))
        (push (make-csg-polygon
               :vertices (list v0 v1 v2)
               :normal (%safe-triangle-normal v0 v1 v2))
              polygons)))
    (nreverse polygons)))

(defun %polygons-to-mesh (polygons)
  "Convert a list of CSG polygons back to a 3D mesh with per-vertex normals."
  (let* ((count (length polygons))
         (vertex-count (* count 3))
         (vertices (make-vertex-array vertex-count 3))
         (indices (make-index-array vertex-count))
         (normals (make-vertex-array vertex-count 3)))
    (loop for poly in polygons
          for i from 0 do
            (let* ((verts (csg-polygon-vertices poly))
                   (v0 (first verts))
                   (v1 (second verts))
                   (v2 (third verts))
                   (n (csg-polygon-normal poly))
                   (base (* i 3)))
              (set-vertex-3d-v vertices base v0)
              (set-vertex-3d-v vertices (+ base 1) v1)
              (set-vertex-3d-v vertices (+ base 2) v2)
              (set-triangle indices i base (+ base 1) (+ base 2))
              (set-vertex-3d-v normals base n)
              (set-vertex-3d-v normals (+ base 1) n)
              (set-vertex-3d-v normals (+ base 2) n)))
    (make-mesh :vertices vertices
               :indices indices
               :normals normals
               :dimensions 3)))

(defun %invert-polygons (polygons)
  "Return a new list with all polygons flipped."
  (mapcar (lambda (p)
            (let ((verts (csg-polygon-vertices p)))
              (make-csg-polygon
               :vertices (list (third verts) (second verts) (first verts))
               :normal (v:v* (csg-polygon-normal p) -1.0))))
          polygons))

(defun %all-tree-polygons (node)
  "Collect all polygons from a BSP tree."
  (if (null node)
      nil
      (append (copy-list (csg-node-polygons node))
              (%all-tree-polygons (csg-node-front node))
              (%all-tree-polygons (csg-node-back node)))))

;; ---------- Public CSG operations ----------

(defun csg-union (mesh-a mesh-b)
  "Return the union (A ∪ B) of two closed 3D triangle meshes."
  (let* ((a-polys (%mesh-to-polygons mesh-a))
         (b-polys (%mesh-to-polygons mesh-b))
         (a-tree (%build-bsp-tree a-polys))
         (b-tree (%build-bsp-tree b-polys))
         (a-outside-b (%clip-polygons b-tree a-polys))
         (b-outside-a (%clip-polygons a-tree b-polys)))
    (%polygons-to-mesh (append a-outside-b b-outside-a))))

(defun csg-intersection (mesh-a mesh-b)
  "Return the intersection (A ∩ B) of two closed 3D triangle meshes."
  (let* ((a-polys (%mesh-to-polygons mesh-a))
         (b-polys (%mesh-to-polygons mesh-b))
         (a-inside-b (%clip-polygons (%invert-bsp-tree (%build-bsp-tree b-polys)) a-polys))
         (b-inside-a (%clip-polygons (%invert-bsp-tree (%build-bsp-tree a-polys)) b-polys)))
    (%polygons-to-mesh (append a-inside-b b-inside-a))))

(defun csg-difference (mesh-a mesh-b)
  "Return the difference (A − B) of two closed 3D triangle meshes."
  (let* ((a-polys (%mesh-to-polygons mesh-a))
         (b-polys (%mesh-to-polygons mesh-b))
         (b-tree (%build-bsp-tree b-polys))
         (a-outside-b (%clip-polygons b-tree a-polys))
         (b-inside-a (%invert-polygons
                      (%clip-polygons (%invert-bsp-tree (%build-bsp-tree a-polys)) b-polys))))
    (%polygons-to-mesh (append a-outside-b b-inside-a))))
