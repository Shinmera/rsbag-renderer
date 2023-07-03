(in-package #:rsbag-renderer)
(defpackage #:rsbag-renderer.source.file
  (:use #:cl #:rsbag-renderer)
  (:export
   #:file-source
   #:file-channel
   #:file-event))
(in-package #:rsbag-renderer.source.file)

(defclass file-source (source rsbag:bag)
  ((identifier :initarg :identifier :accessor identifier)))

(defclass file-channel (channel rsbag:channel)
  ())

(defclass file-event ()
  ((event :initarg :event :accessor event-event)
   (channel :initarg :channel :accessor event-channel)))

(defmethod source-type ((source file-source))
  :file)

(defmethod open-source ((type (eql :file)) pathname &key)
  (let* ((identifier (namestring
                      (uiop:enough-pathname (etypecase pathname
                                              (pathname pathname)
                                              (string (pathname pathname)))
                                            (root-pathname ""))))
         (bag (rsbag:open-bag pathname :direction :input))
         (source (change-class bag 'file-source :identifier identifier)))
    (loop for channel in (rsbag:bag-channels source)
          do (change-class channel 'file-channel))
    source))

(defmethod close-source ((source file-source))
  (close source)
  source)

(defmethod channel ((source file-source) identifier)
  (change-class (rsbag:bag-channel source identifier) 'file-channel))

(defmethod channels ((source file-source))
  (mapcar (lambda (c) (change-class c 'file-channel))
          (rsbag:bag-channels source)))

(defmethod channel-length ((channel file-channel))
  (length channel))

(defmethod channel-source ((channel file-channel))
  (rsbag:channel-bag channel))

(defmethod start-timestamp ((channel file-channel))
  (timestamp (event channel 0)))

(defmethod end-timestamp ((channel file-channel))
  (timestamp (event channel (1- (length channel)))))

(defmethod duration ((channel file-channel))
  (- (local-time:timestamp-to-universal (end-timestamp channel))
     (local-time:timestamp-to-universal (start-timestamp channel))))

(defmethod resolution ((channel file-channel))
  (/ (channel-length channel)
     (duration channel)))

(defmethod event ((channel file-channel) index)
  (make-instance
   'file-event
   :event (rsbag:entry channel index)
   :channel channel))

(defmethod identifier ((channel file-channel))
  (rsbag:channel-name channel))

(defmethod id ((event file-event))
  (rsb:event-sequence-number (event-event event)))

(defmethod timestamp ((event rsb:event))
  (getf (rsb:event-timestamps event) :create))

(defmethod timestamp ((event file-event))
  (timestamp (event-event event)))

(defun name-schema (name)
  (let ((pos (position #\: name)))
    (if pos (subseq name (1+ pos)) name)))

(defmethod payload ((event file-event))
  (rsb.converter:wire->domain
   :protocol-buffer
   (rsb:event-data (event-event event))
   (find-symbol (name-schema (identifier (event-channel event))) :keyword)))
