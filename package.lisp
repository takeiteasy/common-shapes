;;;; package.lisp
;;;; Package definition for common-shapes

(defpackage #:common-shapes
  (:use #:cl)
  (:local-nicknames (:v #:org.shirakumo.flare.vector)
                    (:m #:org.shirakumo.flare.matrix))
  (:export
   ;; Mesh structure and accessors
   #:mesh
   #:mesh-p
   #:make-mesh
   #:mesh-vertices
   #:mesh-indices
   #:mesh-normals
   #:mesh-tex-coords
   #:mesh-dimensions
   #:vertex-count
   #:triangle-count

   ;; 2D Shape Generators
   #:make-rectangle-2d
   #:make-circle-2d
   #:make-polygon-2d
   #:make-ellipse-2d

   ;; 3D Shape Generators
   #:make-cube
   #:make-box
   #:make-sphere
   #:make-icosphere
   #:make-cylinder
   #:make-cone
   #:make-torus
   #:make-plane
   #:make-hemisphere
   #:make-capsule

   ;; Platonic Solids
   #:make-tetrahedron
   #:make-octahedron
   #:make-dodecahedron
   #:make-icosahedron

   ;; Utility Functions
   #:compute-normals
   #:compute-aabb
   #:merge-meshes
   #:transform-mesh
   #:flip-winding
   #:translate-mesh
   #:scale-mesh
   #:rotate-mesh-x
   #:rotate-mesh-y
   #:rotate-mesh-z
   #:center-mesh
    #:normalize-mesh

   ;; CSG Operations
   #:csg-union
   #:csg-intersection
   #:csg-difference))
