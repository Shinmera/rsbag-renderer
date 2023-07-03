(in-package #:rsbag-renderer)
(defpackage #:rsbag-renderer.transform.direct
  (:use #:cl #:rsbag-renderer)
  (:export #:direct))
(in-package #:rsbag-renderer.transform.direct)

(define-transform direct (&rest events) ()
  (with-json-array ()
    (dolist (ev events)
      (entry ev))))
