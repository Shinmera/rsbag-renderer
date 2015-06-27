#|
This file is a part of rsbag-renderer
Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:rsbag-renderer)

;; Page dispatch
(define-storage page)

(defmacro define-page (name uri uri-registers &body body)
  (let ((path (gensym "PATH")))
    `(setf (page ',name)
           (list ,(format NIL "^~a$" uri)
                 (lambda (,path)
                   (cl-ppcre:register-groups-bind ,uri-registers (,uri ,path)
                     ,@body))))))

(defun dispatch (to)
  (v:debug :server "Dispatching to ~s" to)
  (loop for page being the hash-values of *page*
        for (path func) = page
        do (when (cl-ppcre:scan path to)
             (return (funcall func to)))))

;; Api dispatch
(define-storage api)

(define-condition args-missing (error)
  ((args :initarg :args :accessor args))
  (:default-initargs :arg (error "ARGS required."))
  (:report (lambda (c s) (format s "Arguments ~s are required, but were not provided!" (args c)))))

(define-condition endpoint-missing (error)
  ((endpoint :initarg :endpoint :accessor endpoint))
  (:default-initargs :arg (error "ENDPOINT required."))
  (:report (lambda (c s) (format s "Endpoint ~s requested, but it does not exist!" (endpoint c)))))

(defun bindings-from-args (args)
  (loop for arg in args
        unless (eql arg '&optional)
        collect `(,arg ,(string arg))))

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
             ,@body))))

(defmacro with-api-output ((message &rest format-args) &body body)
  `(with-json-output ()
     (with-json-object ()
       (pair "status" (hunchentoot:return-code*))
       (pair "message" (format NIL ,message ,@format-args))
       (key "data")
       (with-json-value ,@body))))
 
(define-page api "/api/(.*)" (endpoint)
  (setf (hunchentoot:content-type*) "application/json; charset=utf-8")
  (handler-case
      (dissect:with-truncated-stack ()
        (handler-bind ((error #'dissect-error))
          (loop for api being the hash-keys of *api*
                for func being the hash-values of *api*
                do (when (string-equal endpoint api)
                     (return (funcall func)))
                finally (error 'endpoint-missing :endpoint endpoint))))
    (arg-missing (err)
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
  (maybe-unlist
   (append (assoc-all param (hunchentoot:post-parameters*))
           (assoc-all param (hunchentoot:get-parameters*)))))

;; Server backend
(define-storage listener)

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
  (etypecase result
    (plump:node
     (setf (hunchentoot:content-type*) "application/xhtml+xml; charset=utf-8")
     (plump:serialize result NIL))
    (pathname (hunchentoot:handle-static-file result))
    (string result)
    ((array (unsigned-byte 8)) result)
    (null (setf (hunchentoot:return-code*) 404)
     "No result (404)")))

(progn
  (defun pre-handler (request)
    (let* ((path (hunchentoot:url-decode
                  (hunchentoot:script-name request)
                  :utf-8))
           (result (ignore-errors
                    (dissect:with-truncated-stack ()
                      (handler-bind ((error #'dissect-error))
                        (dispatch path))))))
      (lambda ()
        (post-handler result))))
  (setf hunchentoot:*dispatch-table* (list #'pre-handler)))