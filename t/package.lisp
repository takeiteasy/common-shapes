;;;; t/package.lisp
;;;; Package definition for common-shapes tests

(defpackage #:common-shapes/test
  (:use #:cl #:common-shapes #:fiveam)
  (:export #:run-tests
           #:common-shapes-tests))
