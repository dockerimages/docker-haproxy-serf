(load "/config/config.lisp" :if-does-not-exist nil)

(defparameter *handlers* nil)

(defun split-at (char str)
  (let ((pos (position char str)))
    (cond ((zerop (length str)) nil)
          ((eq pos nil) (list str))
          ((= pos 0) (split-at char (subseq str 1)))
          (t (cons
              (subseq str 0 pos)
              (split-at char (subseq str (1+ pos))))))))

(defun parse-member (line)
  (let ((items (split-at #\Tab line)))
    (apply #'append
           (mapcar #'list
                   (case (length items)
                     (3 '(:name :ip-addr :tags))
                     (4 '(:name :ip-addr :role :tags)))
                   items))))

(defun get-handler (type)
  (cdr (assoc type *handlers* :test 'string-equal)))

(defun add-handler (type fn)
  (push (cons type fn) *handlers*))

(defun handle-event ()
  (let ((type (sb-unix::posix-getenv "SERF_EVENT"))
        (user-event (sb-unix::posix-getenv "SERF_USER_EVENT"))
        (data (loop for line = (read-line *terminal-io* nil)
                    while line collect line)))
    (when (string= type "user")
      (setf type (concatenate 'string type "." user-event)))
    (if (get-handler type)
        (dolist (line data)
          (funcall (get-handler type) line))
      (format t "~%No handler for ~a.~%" type))))

(defmacro defhandler (name params-or-fn &body body)
  `(add-handler
    (symbol-name ',name)
    (if (listp ',params-or-fn)
        (lambda ,params-or-fn ,@body)
              #',params-or-fn)))
