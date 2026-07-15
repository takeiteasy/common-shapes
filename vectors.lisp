;;;; vectors.lisp
;;;; Minimal single-float vec2/vec3 module (replaces 3d-vectors)

(defpackage #:common-shapes.vec
  (:use #:cl)
  (:export #:vec2 #:vec2-p #:vx2 #:vy2
           #:vec3 #:vec3-p #:vx3 #:vy3 #:vz3
           #:v+ #:v- #:v* #:vc #:vunit))

(in-package #:common-shapes.vec)

(declaim (inline sf))
(defun sf (x)
  (coerce x 'single-float))

(defstruct (vec2 (:constructor %make-vec2 (x y)))
  (x 0.0 :type single-float)
  (y 0.0 :type single-float))

(defun vec2 (x y)
  (%make-vec2 (sf x) (sf y)))

(declaim (inline vx2 vy2))
(defun vx2 (v) (vec2-x v))
(defun vy2 (v) (vec2-y v))

(defstruct (vec3 (:constructor %make-vec3 (x y z)))
  (x 0.0 :type single-float)
  (y 0.0 :type single-float)
  (z 0.0 :type single-float))

(defun vec3 (x y z)
  (%make-vec3 (sf x) (sf y) (sf z)))

(declaim (inline vx3 vy3 vz3))
(defun vx3 (v) (vec3-x v))
(defun vy3 (v) (vec3-y v))
(defun vz3 (v) (vec3-z v))

(defun v+ (a b)
  (vec3 (+ (vx3 a) (vx3 b))
        (+ (vy3 a) (vy3 b))
        (+ (vz3 a) (vz3 b))))

(defun v- (a b)
  (vec3 (- (vx3 a) (vx3 b))
        (- (vy3 a) (vy3 b))
        (- (vz3 a) (vz3 b))))

(defun v* (v s)
  (let ((s (sf s)))
    (vec3 (* (vx3 v) s)
          (* (vy3 v) s)
          (* (vz3 v) s))))

(defun vc (a b)
  (vec3 (- (* (vy3 a) (vz3 b)) (* (vz3 a) (vy3 b)))
        (- (* (vz3 a) (vx3 b)) (* (vx3 a) (vz3 b)))
        (- (* (vx3 a) (vy3 b)) (* (vy3 a) (vx3 b)))))

(defun vunit (v)
  (let ((len (sqrt (+ (* (vx3 v) (vx3 v))
                      (* (vy3 v) (vy3 v))
                      (* (vz3 v) (vz3 v))))))
    (if (zerop len)
        (vec3 0.0 0.0 0.0)
        (vec3 (/ (vx3 v) len) (/ (vy3 v) len) (/ (vz3 v) len)))))
