(in-package #:rsbag-renderer)

(define-storage transform 'equalp)

(defclass transform ()
  ((identifier :initarg :identifier :accessor identifier)
   (transformer :initarg :transformer :accessor transformer)
   (description :initarg :description :accessor description)
   (schema :initarg :schema :accessor schema)
   (origin :initarg :origin :accessor origin)))

(defmethod initialize-instance :after ((transform transform) &key)
  (setf (transform (identifier transform)) transform))

(defmacro define-transform (identifier channel-events options &body body)
  (let ((lambda `(lambda ,channel-events
                   ,@body)))
    `(make-instance
      'transform
      :identifier ,(string-downcase identifier)
      :description ,(form-fiddle:lambda-docstring lambda)
      :transformer ,lambda
      :origin ,(or *compile-file-pathname* *load-pathname*)
      ,@options)))

(defgeneric transform-events (transform events))

(defmethod transform-events ((transform transform) events)
  (apply (transformer transform) events))

(defmethod transform-events ((identifier string) events)
  (transform-events (or (transform identifier)
                        (error "No such transform ~s" identifier))
                    events))
