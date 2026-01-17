;;;; t/tests.lisp
;;;; Test suite for common-shapes

(in-package #:common-shapes/test)

;;; Define the main test suite
(def-suite common-shapes-tests
  :description "Test suite for common-shapes library")

(in-suite common-shapes-tests)

;;; Helper functions for tests

(defun approx= (a b &optional (epsilon 1e-5))
  "Check if two floats are approximately equal."
  (< (abs (- a b)) epsilon))

(defun valid-mesh-p (mesh &key (min-vertices 3) (min-triangles 1))
  "Check if a mesh has valid structure."
  (and (mesh-p mesh)
       (mesh-vertices mesh)
       (mesh-indices mesh)
       (>= (vertex-count mesh) min-vertices)
       (>= (triangle-count mesh) min-triangles)
       ;; Check array lengths are consistent
       (= (length (mesh-vertices mesh))
          (* (vertex-count mesh) (mesh-dimensions mesh)))
       (= (length (mesh-indices mesh))
          (* (triangle-count mesh) 3))))

(defun mesh-has-normals-p (mesh)
  "Check if mesh has properly sized normals array."
  (and (mesh-normals mesh)
       (= (length (mesh-normals mesh))
          (* (vertex-count mesh) 3))))

(defun mesh-has-texcoords-p (mesh)
  "Check if mesh has properly sized texture coordinate array."
  (and (mesh-tex-coords mesh)
       (= (length (mesh-tex-coords mesh))
          (* (vertex-count mesh) 2))))

;;; Mesh structure tests

(test mesh-structure
  "Test basic mesh structure creation and accessors."
  (let ((mesh (make-mesh :vertices (make-array 9 :element-type 'single-float
                                                :initial-contents '(0.0 0.0 0.0
                                                                    1.0 0.0 0.0
                                                                    0.0 1.0 0.0))
                         :indices (make-array 3 :element-type '(unsigned-byte 32)
                                               :initial-contents '(0 1 2))
                         :dimensions 3)))
    (is (mesh-p mesh))
    (is (= 3 (vertex-count mesh)))
    (is (= 1 (triangle-count mesh)))
    (is (= 3 (mesh-dimensions mesh)))))

;;; 2D Shape Generator Tests

(test make-rectangle-2d
  "Test 2D rectangle generation."
  (let ((mesh (make-rectangle-2d 2.0 1.0)))
    (is (valid-mesh-p mesh :min-vertices 4 :min-triangles 2))
    (is (= 2 (mesh-dimensions mesh))))
  ;; Test with 3D output
  (let ((mesh (make-rectangle-2d 2.0 1.0 :3d t)))
    (is (valid-mesh-p mesh :min-vertices 4 :min-triangles 2))
    (is (= 3 (mesh-dimensions mesh))))
  ;; Test with normals and tex-coords
  (let ((mesh (make-rectangle-2d 2.0 1.0 :3d t :normals t :tex-coords t)))
    (is (mesh-has-normals-p mesh))
    (is (mesh-has-texcoords-p mesh))))

(test make-circle-2d
  "Test 2D circle/disk generation."
  (let ((mesh (make-circle-2d 1.0 16)))
    (is (valid-mesh-p mesh :min-vertices 17 :min-triangles 16))
    (is (= 2 (mesh-dimensions mesh))))
  ;; Test with 3D and all options
  (let ((mesh (make-circle-2d 1.0 32 :3d t :normals t :tex-coords t)))
    (is (= 3 (mesh-dimensions mesh)))
    (is (mesh-has-normals-p mesh))
    (is (mesh-has-texcoords-p mesh))))

(test make-polygon-2d
  "Test 2D polygon generation."
  ;; Triangle
  (let ((mesh (make-polygon-2d 3 1.0)))
    (is (valid-mesh-p mesh :min-vertices 4 :min-triangles 3)))
  ;; Hexagon
  (let ((mesh (make-polygon-2d 6 1.0)))
    (is (valid-mesh-p mesh :min-vertices 7 :min-triangles 6))))

(test make-ellipse-2d
  "Test 2D ellipse generation."
  (let ((mesh (make-ellipse-2d 2.0 1.0 16)))
    (is (valid-mesh-p mesh :min-vertices 17 :min-triangles 16))
    (is (= 2 (mesh-dimensions mesh)))))

;;; 3D Shape Generator Tests

(test make-cube
  "Test cube generation."
  (let ((mesh (make-cube 1.0)))
    (is (valid-mesh-p mesh :min-vertices 24 :min-triangles 12))
    (is (= 3 (mesh-dimensions mesh))))
  ;; With normals and tex-coords
  (let ((mesh (make-cube 2.0 :normals t :tex-coords t)))
    (is (mesh-has-normals-p mesh))
    (is (mesh-has-texcoords-p mesh))))

(test make-box
  "Test box generation."
  (let ((mesh (make-box 2.0 1.0 0.5)))
    (is (valid-mesh-p mesh :min-vertices 24 :min-triangles 12))
    (is (= 3 (mesh-dimensions mesh)))))

(test make-sphere
  "Test UV sphere generation."
  (let ((mesh (make-sphere 1.0 16 8)))
    (is (valid-mesh-p mesh))
    (is (= 3 (mesh-dimensions mesh))))
  ;; With options
  (let ((mesh (make-sphere 1.0 32 16 :normals t :tex-coords t)))
    (is (mesh-has-normals-p mesh))
    (is (mesh-has-texcoords-p mesh))))

(test make-hemisphere
  "Test hemisphere generation."
  (let ((mesh (make-hemisphere 1.0 16 8)))
    (is (valid-mesh-p mesh))
    (is (= 3 (mesh-dimensions mesh)))))

(test make-cylinder
  "Test cylinder generation."
  (let ((mesh (make-cylinder 1.0 2.0 16 4)))
    (is (valid-mesh-p mesh))
    (is (= 3 (mesh-dimensions mesh))))
  ;; With options
  (let ((mesh (make-cylinder 1.0 2.0 16 4 :normals t :tex-coords t)))
    (is (mesh-has-normals-p mesh))
    (is (mesh-has-texcoords-p mesh))))

(test make-cone
  "Test cone generation."
  (let ((mesh (make-cone 1.0 2.0 16 4)))
    (is (valid-mesh-p mesh))
    (is (= 3 (mesh-dimensions mesh)))))

(test make-torus
  "Test torus generation."
  (let ((mesh (make-torus 1.0 0.3 16 8)))
    (is (valid-mesh-p mesh))
    (is (= 3 (mesh-dimensions mesh))))
  ;; With options
  (let ((mesh (make-torus 1.0 0.3 16 8 :normals t :tex-coords t)))
    (is (mesh-has-normals-p mesh))
    (is (mesh-has-texcoords-p mesh))))

(test make-plane
  "Test plane generation."
  (let ((mesh (make-plane 2.0 2.0 4 4)))
    (is (valid-mesh-p mesh))
    (is (= 3 (mesh-dimensions mesh))))
  ;; With options
  (let ((mesh (make-plane 2.0 2.0 4 4 :normals t :tex-coords t)))
    (is (mesh-has-normals-p mesh))
    (is (mesh-has-texcoords-p mesh))))

(test make-icosphere
  "Test icosphere generation."
  ;; No subdivisions = icosahedron
  (let ((mesh (make-icosphere 1.0 0)))
    (is (valid-mesh-p mesh))
    (is (= 3 (mesh-dimensions mesh))))
  ;; One subdivision
  (let ((mesh (make-icosphere 1.0 1 :normals t :tex-coords t)))
    (is (valid-mesh-p mesh))
    (is (mesh-has-normals-p mesh))
    (is (mesh-has-texcoords-p mesh))))

(test make-capsule
  "Test capsule generation."
  (let ((mesh (make-capsule 0.5 2.0 16 4)))
    (is (valid-mesh-p mesh))
    (is (= 3 (mesh-dimensions mesh)))))

;;; Platonic Solid Tests

(test make-tetrahedron
  "Test tetrahedron generation."
  (let ((mesh (make-tetrahedron 1.0)))
    (is (valid-mesh-p mesh :min-vertices 12 :min-triangles 4))
    (is (= 3 (mesh-dimensions mesh))))
  ;; With options
  (let ((mesh (make-tetrahedron 1.0 :normals t :tex-coords t)))
    (is (mesh-has-normals-p mesh))
    (is (mesh-has-texcoords-p mesh))))

(test make-octahedron
  "Test octahedron generation."
  (let ((mesh (make-octahedron 1.0)))
    (is (valid-mesh-p mesh :min-vertices 24 :min-triangles 8))
    (is (= 3 (mesh-dimensions mesh)))))

(test make-icosahedron
  "Test icosahedron generation."
  (let ((mesh (make-icosahedron 1.0)))
    (is (valid-mesh-p mesh :min-vertices 60 :min-triangles 20))
    (is (= 3 (mesh-dimensions mesh)))))

(test make-dodecahedron
  "Test dodecahedron generation."
  (let ((mesh (make-dodecahedron 1.0)))
    (is (valid-mesh-p mesh :min-vertices 108 :min-triangles 36))
    (is (= 3 (mesh-dimensions mesh)))))

;;; Utility Function Tests

(test compute-aabb
  "Test axis-aligned bounding box computation."
  ;; 3D cube
  (let ((mesh (make-cube 2.0)))
    (multiple-value-bind (min-b max-b) (compute-aabb mesh)
      (is (= 3 (length min-b)))
      (is (= 3 (length max-b)))
      (is (approx= -1.0 (first min-b)))
      (is (approx= 1.0 (first max-b)))))
  ;; 2D rectangle
  (let ((mesh (make-rectangle-2d 4.0 2.0)))
    (multiple-value-bind (min-b max-b) (compute-aabb mesh)
      (is (= 2 (length min-b)))
      (is (= 2 (length max-b)))
      (is (approx= -2.0 (first min-b)))
      (is (approx= 2.0 (first max-b))))))

(test compute-normals
  "Test normal computation."
  (let* ((mesh (make-cube 1.0))
         (mesh-with-normals (compute-normals mesh)))
    (is (mesh-has-normals-p mesh-with-normals))
    ;; Original mesh should still not have normals
    (is (null (mesh-normals mesh)))))

(test merge-meshes
  "Test mesh merging."
  (let* ((cube1 (make-cube 1.0))
         (cube2 (make-cube 1.0))
         (merged (merge-meshes cube1 cube2)))
    (is (valid-mesh-p merged))
    (is (= (* 2 (vertex-count cube1)) (vertex-count merged)))
    (is (= (* 2 (triangle-count cube1)) (triangle-count merged)))))

(test flip-winding
  "Test winding order flip."
  (let* ((mesh (make-cube 1.0 :normals t))
         (flipped (flip-winding mesh)))
    (is (valid-mesh-p flipped))
    (is (mesh-has-normals-p flipped))
    ;; Vertex count should be same
    (is (= (vertex-count mesh) (vertex-count flipped)))))

(test translate-mesh
  "Test mesh translation."
  (let* ((mesh (make-cube 1.0))  ; Cube with size 1.0 goes from -0.5 to 0.5
         (translated (translate-mesh mesh 5.0 0.0 0.0)))
    (multiple-value-bind (min-b max-b) (compute-aabb translated)
      ;; Cube should now be centered at x=5, so bounds are 4.5 to 5.5
      (is (approx= 4.5 (first min-b)))
      (is (approx= 5.5 (first max-b))))))

(test scale-mesh
  "Test mesh scaling."
  (let* ((mesh (make-cube 1.0))
         (scaled (scale-mesh mesh 2.0)))
    (multiple-value-bind (min-b max-b) (compute-aabb scaled)
      ;; Cube should now be 2x2x2
      (is (approx= -1.0 (first min-b)))
      (is (approx= 1.0 (first max-b))))))

(test center-mesh
  "Test mesh centering."
  (let* ((mesh (make-cube 1.0))
         (translated (translate-mesh mesh 10.0 10.0 10.0))
         (centered (center-mesh translated)))
    (multiple-value-bind (min-b max-b) (compute-aabb centered)
      ;; Should be centered at origin
      (is (approx= (- (first min-b)) (first max-b))))))

(test normalize-mesh
  "Test mesh normalization."
  (let* ((mesh (make-box 4.0 2.0 1.0))
         (normalized (normalize-mesh mesh)))
    (multiple-value-bind (min-b max-b) (compute-aabb normalized)
      ;; Largest dimension should be 1.0
      (let ((size-x (- (first max-b) (first min-b)))
            (size-y (- (second max-b) (second min-b)))
            (size-z (- (third max-b) (third min-b))))
        (is (approx= 1.0 (max size-x size-y size-z)))))))

;;; Run all tests

(defun run-tests ()
  "Run all common-shapes tests."
  (run! 'common-shapes-tests))
