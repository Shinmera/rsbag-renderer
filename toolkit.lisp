
(in-package #:rsbag-renderer)

(defvar *debugger* NIL)
(defvar *root* NIL)

(defgeneric description (object))
(defgeneric identifier (object))
(defgeneric schema (object))

(defmacro define-storage (basename &optional (test ''equal))
  (let ((var (intern (format NIL "*~a*" basename)))
        (fun (intern (format NIL "~a" basename)))
        (rem (intern (format NIL "~a-~a" :REMOVE basename)))
        (lis (intern (format NIL "~a-~a~a" :LIST basename :S))))
    `(progn
       (defvar ,var (make-hash-table :test ,test))

       (defun ,fun (id)
         (gethash id ,var))

       (defun (setf ,fun) (val id)
         (setf (gethash id ,var) val))

       (defun ,rem (id)
         (remhash id ,var))

       (defun ,lis ()
         (sort (loop for v being the hash-values of ,var collect v)
               #'string< :key #'identifier))
       
       (values ',fun ',rem ',lis ',var))))

(defun root-pathname (pathname)
  (merge-pathnames
   pathname
   (or *root*
       (setf *root*
             (or
              (when (uiop:directory-exists-p (merge-pathnames "visualizers/"))
                *default-pathname-defaults*)
              (uiop:directory-exists-p (asdf:system-source-directory :rsbag-renderer))
              (restart-case (error "Unable to discover self!")
                (set-root (root)
                  :interactive read
                  :report "Set a new root explicitly."
                  root)))))))

(defun resource (path &optional error-p)
  (or (probe-file (root-pathname path))
      (and error-p (error "Could not find resource ~s" path))))

(defun template (path &optional (error-p T))
  (resource (merge-pathnames path "template/") error-p))

(defun static-file (path &optional (error-p T))
  (resource (merge-pathnames path "static/") error-p))

(defun assoc-all (item alist)
  (loop for (name . val) in alist
        when (string-equal name item)
        collect val))

(defun ensure-list (list)
  (if (listp list) list (list list)))

(defun maybe-unlist (list)
  (if (cdr list) list (car list)))

(defun << (fun &rest curry)
  (if curry
      (lambda (&rest args) (apply fun (append args curry)))
      fun))

(defun >> (fun &rest curry)
  (if curry
      (lambda (&rest args) (apply fun (append curry args)))
      fun))

(defun dissect-error (err)
  (v:error :server "Unhandled error:~&~a" (dissect:present err NIL))
  (when *debugger* (invoke-debugger err)))

(defmacro define-reducer-method (reduction method class accessor)
  `(defmethod ,method ((,class ,class))
     (loop for chan in (,accessor ,class)
           ,reduction (,method chan))))

(defun write-string-file (string path)
  (with-open-file (stream path :direction :output
                               :if-exists :supersede
                               :if-does-not-exist :create)
    (write-sequence string stream)))

(defun read-string-file (path)
  (with-open-file (stream path :direction :input
                               :if-does-not-exist :error)
    (with-output-to-string (string)
      (let ((buffer (make-array 4096 :element-type 'character)))
        (loop for bytes = (read-sequence buffer stream)
              do (write-sequence buffer string :start 0 :end bytes)
              while (= bytes 4096))))))
