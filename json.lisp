
(in-package #:rsbag-renderer)

(defvar *json-output*)
(defvar *started*)
(defparameter *string-replaces*
  (let ((map (make-hash-table :test 'eql)))
    (loop for (k v) in '((#\\ "\\\\")
                         (#\" "\\\"")
                         (#\Backspace "\\b")
                         (#\Page "\\f")
                         (#\Newline "\\n")
                         (#\Return "\\r")
                         (#\Tab "\\t"))
          do (setf (gethash k map) v))
    map))

(declaim (inline json-delimiter
                 json-null
                 json-false
                 json-true)
         (type stream *json-output*)
         (type boolean *started*))

(defun json-delimiter (&optional (dest *json-output*))
  (declare (optimize speed) (type stream dest))
  (if *started*
      (write-char #\, dest)
      (setf *started* T)))

(defun json-null (&optional (dest *json-output*))
  (declare (optimize speed) (type stream dest))
  (write-string "null" dest))

(defun json-false (&optional (dest *json-output*))
  (declare (optimize speed) (type stream dest))
  (write-string "false" dest))

(defun json-true (&optional (dest *json-output*))
  (declare (optimize speed) (type stream dest))
  (write-string "true" dest))

(defun write-json (object &optional (dest *json-output*))
  (declare (optimize speed) (type stream dest))
  (typecase object
    (integer
     (princ object dest))
    
    (ratio
     (write-json (coerce object 'double-float) dest))
    
    (float
     (let ((*read-default-float-format* 'double-float))
       (format dest "~F" (coerce object 'double-float))))
    
    (string
     (write-char #\" dest)
     (loop for char across object
           for rep = (gethash char *string-replaces*)
           do (if rep
                  (write-string rep dest)
                  (write-char char dest)))
     (write-char #\" dest))
    
    (list
     (with-json-array (dest)
       (loop for i in object
             do (entry i))))
    
    (vector
     (with-json-array (dest)
       (loop for i across object
             do (entry i))))
    
    (T (write-json (princ-to-string object) dest)))
  object)

(defmacro with-delimiters ((destination left right) &body body)
  `(unwind-protect
        (let ((*started* NIL))
          (write-char ,left ,destination)
          ,@body)
     (write-char ,right ,destination)))

(defmacro with-json-array ((&optional (destination '*json-output*)) &body body)
  `(with-delimiters (,destination #\[ #\])
     (flet ((entry (value)
              (with-json-entry (,destination)
                (write-json value ,destination))
              NIL))
       (declare (ignorable (function entry)))
       ,@body)))

(defmacro with-json-entry ((&optional (destination '*json-output*)) &body body)
  `(progn (json-delimiter ,destination)
          ,@body))

(defmacro with-json-object ((&optional (destination '*json-output*)) &body body)
  `(with-delimiters (,destination #\{ #\})
     (flet ((pair (key value)
              (with-json-value (key ,destination)
                (write-json value ,destination))
              NIL))
       (declare (ignorable (function pair)))
       ,@body)))

(defmacro with-json-value ((key &optional (destination '*json-output*)) &body body)
  `(progn
     (json-delimiter ,destination)
     (write-json ,key ,destination)
     (write-char #\: ,destination)
     ,@body))

(defmacro with-json-output ((&optional stream) &body body)
  (if stream
      `(let ((*json-output* ,stream))
         ,@body)
      `(with-output-to-string (*json-output*)
         ,@body)))
