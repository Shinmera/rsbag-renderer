(in-package #:rsbag-renderer)

;; Page dispatch
(define-storage page 'eql)

(defmacro define-page (name uri uri-registers &body body)
  (let ((path (gensym "PATH")))
    `(setf (page ',name)
           (list ,(format NIL "^~a$" uri)
                 (lambda (,path)
                   (declare (type string ,path))
                   (cl-ppcre:register-groups-bind ,uri-registers (,uri ,path)
                     ,@body))))))

(defun dispatch (to)
  (v:debug :server "Dispatching to ~s" to)
  (loop for page being the hash-values of *page*
        for (path func) = page
        do (when (cl-ppcre:scan path to)
             (return (funcall func to)))))

;; Api dispatch
(define-storage api 'eql)

(define-condition args-missing (error)
  ((args :initarg :args :accessor args))
  (:default-initargs :arg (error "ARGS required."))
  (:report (lambda (c s) (format s "Arguments ~s are required, but were not provided!" (args c)))))

(define-condition endpoint-missing (error)
  ((endpoint :initarg :endpoint :accessor endpoint))
  (:default-initargs :arg (error "ENDPOINT required."))
  (:report (lambda (c s) (format s "Endpoint ~s requested, but it does not exist!" (endpoint c)))))

(defun bindings-from-args (args)
  (loop with in-optional = NIL
        for arg in args
        for (name default) = (cond ((and in-optional (listp arg))
                                    arg)
                                   ((symbolp arg)
                                    (list arg))
                                   (T (error "Unexpected argument ~s in api-lambda-list." arg)))
        for binding = (cond ((eql arg '&optional)
                             (setf in-optional T)
                             NIL)
                            (in-optional
                             `(,name (or (post/get ,(string name))
                                         ,default)))
                            (T
                             `(,name (post/get ,(string name)))))
        when binding collect binding ))

(defun binding-check (args)
  (let ((req (loop for arg in args until (eql arg '&optional) collect arg))
        (symbol (gensym "SYMBOL"))
        (value (gensym "VALUE"))
        (missing (gensym "MISSING")))
    `(loop for (,symbol . ,value) in (list ,@(loop for r in req collect `(cons ',r ,r)))
           unless ,value
           collect (string ,symbol) into ,missing
           finally (when ,missing (error 'args-missing :args ,missing)))))

(defmacro define-api (name args () &body body)
  `(setf (api ',name)
         (lambda ()
           (let ,(bindings-from-args args)
             ,(binding-check args)
             (locally
                 ,@body)))))

(defmacro with-api-output ((message &rest format-args) &body body)
  `(with-json-output ((server-stream))
     (with-json-object ()
       (pair "status" (hunchentoot:return-code*))
       (pair "message" (format NIL ,message ,@format-args))
       (with-json-value ("data")
         ,@body))))
 
(define-page api "/api/(.*)" (endpoint)
  (declare (optimize speed))
  (setf (hunchentoot:content-type*) "application/json; charset=utf-8")
  (handler-case
      (dissect:with-truncated-stack ()
        (loop for api being the hash-keys of *api*
              for func being the hash-values of *api*
              do (when (string-equal endpoint api)
                   (return (funcall (the function func))))
              finally (error 'endpoint-missing :endpoint endpoint)))
    (args-missing (err)
      (setf (hunchentoot:return-code*) 400)
      (with-api-output ("~a" err)
        (write-json (args err))))
    (endpoint-missing (err)
      (setf (hunchentoot:return-code*) 404)
      (with-api-output ("~a" err)
        (write-json (endpoint err))))
    (error (err)
      (setf (hunchentoot:return-code*) 500)
      (with-api-output ("~a" err)
        (json-null)))))

;; Statics
(define-page static "/static/(.*)" (file)
  ;; Insecure, don't care.
  (static-file file NIL))

;; Minor
(defun redirect (to)
  (hunchentoot:redirect to))

(defun post/get (param)
  (declare (optimize speed))
  (maybe-unlist
   (append (assoc-all param (hunchentoot:post-parameters*))
           (assoc-all param (hunchentoot:get-parameters*)))))

;; Server backend
(define-storage listener 'eql)

(defun start-listener (port)
  (when (listener port)
    (error "Listener on port ~d already exists." port))
  (let ((listener (make-instance 'hunchentoot:easy-acceptor
                                 :port port
                                 :access-log-destination NIL
                                 :message-log-destination NIL)))
    (setf (listener port) listener)
    (hunchentoot:start listener)
    (v:info :server "Started listener on http://localhost:~d/" port))
  port)

(defun stop-listener (port)
  (unless (listener port)
    (error "No listener on port ~d active." port))
  (hunchentoot:stop (listener port))
  (remove-listener port)
  (v:info :server "Stopped listener on http://localhost:~d/" port)
  port)

(defun post-handler (result)
  (declare (optimize speed))
  (etypecase result
    (plump:node
     (setf (hunchentoot:content-type*) "application/xhtml+xml; charset=utf-8")
     (plump:serialize result NIL))
    (pathname (hunchentoot:handle-static-file result))
    (string result)
    ((array (unsigned-byte 8)) result)
    (null (setf (hunchentoot:return-code*) 404)
     "No result (404)")))

(defvar *server-stream*)

(defun server-stream (&key (type :flexi))
  (or *server-stream*
      (setf *server-stream*
            (ecase type
              (:flexi
               (flexi-streams:make-flexi-stream (server-stream :type :octet) :external-format :utf-8))
              (:octet
               (hunchentoot:send-headers))))))

(progn
  (defun pre-handler (request)
    (declare (optimize speed))
    (let* ((path (hunchentoot:url-decode
                  (hunchentoot:script-name request)
                  :utf-8))
           (*server-stream* NIL)
           (result (ignore-errors
                    (dissect:with-truncated-stack ()
                      (handler-bind ((error #'dissect-error))
                        (dispatch path))))))
      (lambda ()
        (post-handler result))))
  (setf hunchentoot:*dispatch-table* (list #'pre-handler)))
