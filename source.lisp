(in-package #:rsbag-renderer)

(define-storage source 'equal)

(defclass source ()
  ())

(defclass channel ()
  ())

(defgeneric source-type (source))
(defgeneric open-source (type identifier &key &allow-other-keys))
(defgeneric close-source (source))
(defgeneric channel (source identifier))
(defgeneric channels (source))
(defgeneric channel-length (channel))
(defgeneric channel-source (channel))
(defgeneric start-timestamp (channel))
(defgeneric end-timestamp (channel))
(defgeneric duration (channel))
(defgeneric resolution (channel))
(defgeneric event (channel index))
(defgeneric id (event))
(defgeneric timestamp (event))
(defgeneric payload (event))

;; Registration
(defmethod open-source :around (type identifier &key)
  (let ((source (call-next-method)))
    (setf (source (identifier source))
          source)))

(defmethod close-source :after ((source source))
  (remove-source (identifier source)))

;; Default methods
(defmethod print-object ((source source) stream)
  (print-unreadable-object (source stream :type T)
    (format stream "~s ~s ~s ~s" :type (source-type source) :identifier (identifier source))))

(defmethod print-object ((channel channel) stream)
  (print-unreadable-object (channel stream :type T)
    (format stream "~s ~s" :identifier (identifier channel))))

(defmethod description ((source source))
  "")

(define-reducer-method maximize channel-length source channels)
(define-reducer-method maximize resolution source channels)
(define-reducer-method maximize duration source channels)
