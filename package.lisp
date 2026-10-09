;;;; package.lisp
;;;; Package definition for cl-meshgen

(defpackage #:cl-meshgen
  (:use #:cl)
  (:local-nicknames (:v #:cl-meshgen.vec)
                    (:m #:cl-meshgen.mat))
  (:import-from #:cl-meshgen.vec #:vec2 #:vec3)
  (:import-from #:cl-meshgen.mat
                #:mtranslation #:mscaling #:mrotation #:m*
                #:marr #:mat4-from-array #:*matrix-layout*)
  (:export
   #:vec2
   #:vec3
   #:mtranslation
   #:mscaling
   #:mrotation
   #:m*
   #:marr
   #:mat4-from-array
   #:*matrix-layout*

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
