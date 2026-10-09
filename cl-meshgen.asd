;;;; cl-meshgen.asd
;;;; System definition for cl-meshgen

(asdf:defsystem #:cl-meshgen
  :description "A Common Lisp library for generating triangle meshes for 2D and 3D shapes"
  :author "George Watson <gigolo@hotmail.co.uk>"
  :license "GPLv3"
  :version "0.1.0"
  :serial t
  :components ((:file "vectors")
               (:file "matrices")
               (:file "package")
               (:file "types")
               (:file "math")
               (:file "generators-2d")
               (:file "generators-3d")
               (:file "platonic")
               (:file "utilities")
   (:file "csg")))

(asdf:defsystem #:cl-meshgen/test
  :description "Tests for cl-meshgen"
  :author "George Watson <gigolo@hotmail.co.uk>"
  :license "GPLv3"
  :depends-on (#:cl-meshgen #:fiveam)
  :serial t
  :components ((:file "tests")))
