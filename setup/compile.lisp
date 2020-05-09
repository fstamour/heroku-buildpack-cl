(in-package :cl-user)

(defpackage #:heroku-build-pack
  (:use #:cl)
  (:export #:initialize-application
	   #:heroku-toplevel))

(in-package #:heroku-build-pack)

(defun env-var-to-path (var)
  (make-pathname :defaults (format nil "~a/" (uiop:getenv var))))

(defvar *build-dir* (env-var-to-path "BUILD_DIR"))
(defvar *cache-dir* (env-var-to-path "CACHE_DIR"))
(defvar *buildpack-dir* (env-var-to-path "BUILDPACK_DIR"))
(defvar *cl-webserver* (let ((cl-webserver (uiop:getenv "CL_WEBSERVER")))
			 (if (zerop (length cl-webserver))
			     'hunchentoot
			     (intern cl-webserver))))

(ecase *cl-webserver*
  (hunchentoot (ql:quickload "hunchentoot"))
  (aserve (ql:quickload "portableaserve")))

;;; App can redefine this to do runtime initializations
(defun initialize-application ())

(defun eval* (format-string &rest arguments)
  (eval (read-from-string (apply #'format nil format-string arguments))))

;;; Default toplevel, app can redefine.
(defun heroku-toplevel ()
  (let ((port (parse-integer (uiop:getenv "PORT"))))
    (format t "Listening on port ~A~%" port)
    (ecase *cl-webserver*
      (hunchentoot
       (eval* "(hunchentoot:start (make-instance 'hunchentoot:easy-acceptor :port ~a" port))
      (aserve (eval* "(net.aserve:start :port ~a" port)))
    (loop (sleep 60))))

;;; This loads the application
(let ((heroku-setup (merge-pathnames "heroku-setup.lisp" *build-dir*)))
  (if (probe-file heroku-setup)
      (load heroku-setup)
      (warn "Could not find \"heroku-setup.lisp\" in \"~A\"." *build-dir*)))

(defun make-executable (name)
  (uiop:dump-image name
   :executable t
   #+sbcl :compression #+sbcl t))

(setf uiop:*image-entry-point* 'heroku-toplevel)

(let ((executable (namestring (merge-pathnames "lispapp" *build-dir*)))) ;must match path specified in bin/release
  (format t "Saving to ~A~%" executable)
  (make-executable executable))
