;;;; math.lisp
;;;; Math utilities for cl-meshgen using the in-house vec/mat modules

(in-package #:cl-meshgen)

;;; Constants
(defconstant +pi+ (coerce pi 'single-float)
  "PI as single-float.")

(defconstant +tau+ (* 2.0 +pi+)
  "2*PI, a full rotation in radians.")

(declaim (inline sf))
(defun sf (x)
  "Coerce X to single-float."
  (coerce x 'single-float))

;;; Vector normalization helper (used in make-icosphere)

(defun vec3-normalize (x y z)
  "Normalize a 3D vector given as separate components. Returns multiple values."
  (let ((len (sqrt (+ (* x x) (* y y) (* z z)))))
    (if (zerop len)
        (values 0.0 0.0 0.0)
        (values (/ x len) (/ y len) (/ z len)))))

;;; Triangle Operations

(defun triangle-normal (v0 v1 v2)
  "Compute the normal of a triangle defined by three vec3 vertices.
   Uses counter-clockwise winding."
  (let ((e1 (v:v- v1 v0))
        (e2 (v:v- v2 v0)))
    (v:vunit (v:vc e1 e2))))

;;; Vertex Array Utilities

(defun get-vertex-2d (vertices index)
  "Get 2D vertex at INDEX from vertex array as a vec2."
  (let ((base (* index 2)))
    (v:vec2 (aref vertices base)
            (aref vertices (1+ base)))))

(defun set-vertex-2d (vertices index x y)
  "Set 2D vertex at INDEX in vertex array."
  (let ((base (* index 2)))
    (setf (aref vertices base) (sf x)
          (aref vertices (1+ base)) (sf y))))

(defun set-vertex-2d-v (vertices index vec)
  "Set 2D vertex at INDEX in vertex array from a vec2."
  (let ((base (* index 2)))
    (setf (aref vertices base) (v:vx2 vec)
          (aref vertices (1+ base)) (v:vy2 vec))))

(defun get-vertex-3d (vertices index)
  "Get 3D vertex at INDEX from vertex array as a vec3."
  (let ((base (* index 3)))
    (v:vec3 (aref vertices base)
            (aref vertices (1+ base))
            (aref vertices (+ base 2)))))

(defun set-vertex-3d (vertices index x y z)
  "Set 3D vertex at INDEX in vertex array."
  (let ((base (* index 3)))
    (setf (aref vertices base) (sf x)
          (aref vertices (1+ base)) (sf y)
          (aref vertices (+ base 2)) (sf z))))

(defun set-vertex-3d-v (vertices index vec)
  "Set 3D vertex at INDEX in vertex array from a vec3."
  (let ((base (* index 3)))
    (setf (aref vertices base) (v:vx3 vec)
          (aref vertices (1+ base)) (v:vy3 vec)
          (aref vertices (+ base 2)) (v:vz3 vec))))

(defun set-triangle (indices tri-index i0 i1 i2)
  "Set triangle at TRI-INDEX in index array."
  (let ((base (* tri-index 3)))
    (setf (aref indices base) i0
          (aref indices (1+ base)) i1
          (aref indices (+ base 2)) i2)))

(defun set-texcoord (tex-coords index u v)
  "Set texture coordinate at INDEX."
  (let ((base (* index 2)))
    (setf (aref tex-coords base) (sf u)
          (aref tex-coords (1+ base)) (sf v))))

(defun set-texcoord-v (tex-coords index vec)
  "Set texture coordinate at INDEX from a vec2."
  (let ((base (* index 2)))
    (setf (aref tex-coords base) (v:vx2 vec)
          (aref tex-coords (1+ base)) (v:vy2 vec))))

;;; Matrix utilities

(defun transform-mesh-vertices (vertices matrix &key (dimensions 3))
  "Transform all vertices in array by matrix. Returns new array."
  (let* ((count (floor (length vertices) dimensions))
         (result (make-array (length vertices)
                             :element-type 'single-float
                             :initial-element 0.0)))
    (dotimes (i count)
      (if (= dimensions 3)
          (let* ((v (get-vertex-3d vertices i))
                 (transformed (m:m* matrix v)))
            (set-vertex-3d-v result i transformed))
          (let* ((base (* i 2))
                 (v (v:vec3 (aref vertices base)
                            (aref vertices (1+ base))
                            0.0))
                 (transformed (m:m* matrix v)))
            (setf (aref result base) (v:vx3 transformed)
                  (aref result (1+ base)) (v:vy3 transformed)))))
    result))

(defun transform-normals (normals matrix)
  "Transform normals by the inverse transpose of the matrix (for correct normal transformation)."
  (let* ((count (floor (length normals) 3))
         (result (make-array (length normals)
                             :element-type 'single-float
                             :initial-element 0.0))
         ;; For correct normal transformation, use inverse transpose
         ;; For rotation-only matrices, this is the same as the matrix
         (normal-matrix (m:mtranspose (m:minv matrix))))
    (dotimes (i count)
      (let* ((n (get-vertex-3d normals i))
             (transformed (v:vunit (m:m* normal-matrix n))))
        (set-vertex-3d-v result i transformed)))
    result))
