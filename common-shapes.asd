;;;; common-shapes.asd
;;;; System definition for common-shapes

(asdf:defsystem #:common-shapes
  :description "A Common Lisp library for generating triangle meshes for 2D and 3D shapes"
  :author "George Watson <gigolo@hotmail.co.uk>"
  :license "MIT"
  :version "0.1.0"
  :depends-on (#:3d-vectors #:3d-matrices)
  :serial t
  :components ((:file "package")
               (:file "types")
               (:file "math")
               (:file "generators-2d")
               (:file "generators-3d")
               (:file "platonic")
               (:file "utilities")
   (:file "csg")))

(asdf:defsystem #:common-shapes/test
  :description "Tests for common-shapes"
  :author "George Watson <gigolo@hotmail.co.uk>"
  :license "MIT"
  :depends-on (#:common-shapes #:fiveam)
  :serial t
  :components ((:file "tests")))
