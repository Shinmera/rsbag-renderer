(in-package #:rsbag-renderer)

(define-storage visualizer 'equalp)

(defclass visualizer ()
  ((identifier :initarg :identifier :accessor identifier)
   (description :initarg :description :accessor description)
   (path :initarg :path :accessor path)
   (schema :initarg :schema :accessor schema)
   (js :initarg :js :accessor js)
   (html :initarg :html :accessor html)
   (css :initarg :css :accessor css))
  (:default-initargs
   :identifier (error "IDENTIFIER required")
   :description ""
   :path NIL
   :schema NIL
   :js NIL
   :html NIL
   :css NIL))

(defmethod initialize-instance :after ((vis visualizer) &key)
  (with-slots (js html css path) vis
    (when path
      (setf path (make-pathname :type NIL :defaults (uiop:enough-pathname path (root-pathname "")))))
    (cond ((and (or js html css) path)
           (save-visualizer vis)
           (load-visualizer vis))
          ((or js html css)
           (setf path (visualizer-file (identifier vis) NIL))
           (save-visualizer vis))
          (path
           (unless (uiop:file-pathname-p path)
             (error "PATH must be a file pathname."))
           (load-visualizer vis))
          (T
           (error "One of JS, HTML, CSS, PATH is required."))))
  (check-visualizer-consistency vis)
  (setf (visualizer (identifier vis)) vis))

(defun check-visualizer-consistency (vis)
  (unless (js vis) (error "JS not supplied and unable to autoload from file!"))
  (unless (html vis) (setf (html vis) ""))
  (unless (css vis) (setf (css vis) ""))
  vis)

(defun visualizer-file (name type)
  (asdf:system-relative-pathname
   :rsbag-renderer
   (make-pathname :name name :type type :directory '(:relative "visualizers"))))

(defgeneric save-visualizer (visualizer))
(defgeneric load-visualizer (visualizer))

(defmethod save-visualizer ((vis visualizer))
  (with-slots (js html css path) vis
    (flet ((maybe-write (thing type)
             (when thing
               (write-string-file thing (root-pathname (make-pathname :type type :defaults path))))))
      (maybe-write js "js")
      (maybe-write html "html")
      (maybe-write css "css")))
  vis)

(defmethod load-visualizer ((vis visualizer))
  (with-slots (js html css path) vis
    (macrolet ((maybe-read (var type)
                 (let ((path (gensym "PATH")))
                   `(let ((,path (root-pathname (make-pathname :type ,type :defaults path))))
                      (when (uiop:file-exists-p ,path)
                        (setf ,var (read-string-file ,path)))))))
      (maybe-read js "js")
      (maybe-read html "html")
      (maybe-read css "css")))
  vis)

(defmethod load-visualizer ((path pathname))
  (make-instance
   'visualizer
   :identifier (pathname-name path)
   :path path))
