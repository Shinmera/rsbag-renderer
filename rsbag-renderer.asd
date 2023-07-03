(in-package #:cl-user)
(asdf:defsystem :rsbag-renderer
  :version "0.1.0"
  :license "LGPL2.1"
  :author "Yukari Hafner <shinmera@tymoon.eu>"
  :maintainer "Yukari Hafner <shinmera@tymoon.eu>"
  :description "RSBag Data Web Server"
  :serial T
  :components ((:file "package")
               (:file "toolkit")
               (:file "source")
               (:file "transform")
               (:file "visualizer")
               (:file "json")
               (:file "server")
               (:file "front")
               (:file "api")
               (:file "config")
               (:file "documentation")
               (:module "sources"
                :components ((:file "file")))
               (:module "transforms"
                :components ((:file "direct")
                             (:file "haptic-vicon-3d"))))
  :depends-on (:hunchentoot
               :cl-ppcre
               :dissect
               :verbose
               :clip
               :cl-rsbag
               :cl-rsb-common
               :form-fiddle
               :rsbag-tidelog
               :rsb-converter-protocol-buffer
               :rsbag-helper)
  :build-operation asdf:program-op
  :build-pathname "rsbag-renderer"
  :entry-point "rsbag-renderer:main")
