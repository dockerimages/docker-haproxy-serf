#!/usr/bin/sbcl --script

(load "/handlers/handler.lisp")

(defvar *haproxy-cfg* "/haproxy/haproxy.conf")
(defvar *supervisorctl* "/usr/bin/supervisorctl")
(defvar *web-role* "xweb")
(defvar *sed* "/bin/sed")

(defhandler member-join (line)
  (let ((member (parse-member line)))
    (when (string-equal (getf member :role) *web-role*)
      (with-open-file (s *haproxy-cfg*
                         :direction :output
                         :if-exists :append)
                      (write-line (format nil "~aserver ~a ~a:~a check" #\Tab
                                          (getf member :name)
                                          (getf member :ip-addr)
                                          (get-tag member "port")) s))
      (sb-ext:run-program *supervisorctl* '("restart" "haproxy")))))

(defun remove-node (line)
  (let ((member (parse-member line)))
    (sb-ext:run-program *sed*
                        (list "-i ''"
                              (format nil "/~a /d" (getf member :name))
                              *haproxy-cfg*))))

(defhandler member-leave remove-node)
(defhandler member-failed remove-node)

(handle-event)
