;;; init-iwyu.el --- include-what-you-use - see `https://include-what-you-use.org' -*- lexical-binding: t -*-

;;; Commentary:
;;
;;
;; include-what-you-use keys use prefix C-c w
;; ---------- ----------------------------------------------------------------
;; Key        Function
;; ---------- ----------------------------------------------------------------
;; C-c w e    `iwyu-reparse'
;; C-c w d    `iwyu-show-diagnostics-buffer'
;; g          `iwyu-start-process-for' (in `IWYU-mode' buffer)

;;; Code:
(eval-when-compile
  (unless (featurep 'init-require)
    (load (file-name-concat (locate-user-emacs-file "modules") "init-require"))))
(exordium-require 'init-prefs)
(exordium-require 'init-projectile)

(require 'cl-lib)
(require 'compile)

;;;###autoload
(define-derived-mode iwyu-mode compilation-mode "IWYU mode"
  "IWYU is a mode to display include what you use results.
Use \\[iwyu-start-process-for] (substitution to \\[recompile]
typically bound to g) to reparse recent file."
  (font-lock-add-keywords
   nil
   `((,(concat "^\\(- \\)?\\(#include\\) "
               "\\(\"[-[:alnum:]_./]+\"\\|<[-[:alnum:]_./]+>\\) +"
               "\\(//.*\\)$")
      (2 font-lock-preprocessor-face)
      (3 font-lock-string-face)
      (4 font-lock-comment-face))
     (,(concat "\\(^\\|\\(for \\)\\)\\(\\(/[-[:alnum:]_.]+\\)+\\."
               (regexp-opt '("h" "hh" "hpp" "c" "cc" "cpp"))
               "\\)")
      (3 font-lock-function-name-face)))))

(defun iwyu-show-diagnostics-buffer ()
  "Show/hide the diagnostics buffer in a dedicated window.
Similar to `iwyu-reparse' but without reparsing."
  (interactive)
  (let* ((buffer-name "*IWYU*")
         (buffer (get-buffer buffer-name)))
    (if buffer
        (let ((window (get-buffer-window buffer)))
          (cond (window
                 (bury-buffer buffer)
                 (delete-window window))
                (buffer
                 (display-buffer buffer-name)
                 (other-window 1)
                 (goto-char (point-min))
                 (fit-window-to-buffer
                  (get-buffer-window (current-buffer)) 20 8)
                 (set-window-dedicated-p
                  (get-buffer-window (current-buffer)) t)
                 (other-window -1))))
      (message "IWYU has not been run for current buffer (Use C-c w e)"))))

(defun iwyu-prepare-args (command)
  "Return list of arguments extracted from COMMAND.
The first word (assumed: the compiler) is skipped.  The
\\='backslash double quote\\=' sequences of arguments are
returned as single element."
  (let* ((quote-match
          (lambda (list start)
            (cl-position-if
             (lambda (x) (string-match (rx "\\\"") x))
             list
             :start start)))
         (args (cdr (split-string command)))
         (start (funcall quote-match args 0))
         (end (funcall quote-match args
                       (if start (+ start 1) (- (cl-list-length args) 1)))))
    (while (and start end)
      (setq args
            (append
             (cl-subseq args 0 start)
             (list (mapconcat 'identity (cl-subseq args start (+ end 1)) " "))
             (cl-subseq args (+ end 1))))
      (setq start (funcall quote-match args (+ start 1)))
      (setq end (funcall quote-match args
                         (if start (+ start 1) (- (cl-list-length args) 1)))))
    args))

(defun iwyu-start-process-for (compile-commands-db file)
  "Start the `include-what-you-use' process for FILE.
The process output is redirected to *IWYU* buffer.  The buffer is
cleared before starting the process.  The is FILE is searched
inside the specified COMPILE-COMMANDS-DB compilation database,
typically `compile-commands.json'..

The arguments for `include-what-you-use' are constructed as
follows.  From the JSON value of \\='command\\=' property it
filters out any flag that matches `exordium-iwyu-filter-args'.
Such constructed list then is appended to arguments in
`exordium-iwyu-extra-args'."
  (let* ((json-object-type 'plist)
         (json-array-type 'list)
         (compile-commands-json
          (json-read-file compile-commands-db)))
    (catch 'found
      (dolist (entry compile-commands-json)
        (when (string-suffix-p file (plist-get entry :file))
          (let* ((buffer-name "*IWYU*")
                 (buffer (get-buffer-create buffer-name)))
            (with-current-buffer buffer
              (read-only-mode 0)
              (delete-region (point-min) (point-max))
              (goto-char (point-min))
              (insert
               (format "include-what-you-use results for file %s:\n" file))
              (read-only-mode)
              (iwyu-mode)
              (substitute-key-definition
               'recompile
               (lambda ()
                 (interactive)
                 (iwyu-start-process-for compile-commands-db file))
                (current-local-map)))
            (apply
             'start-process
             "iwyu-process"
             buffer
             "include-what-you-use"
             (append
              exordium-iwyu-extra-args
              (cl-remove-if (lambda (x) (member x exordium-iwyu-filter-args))
                            (iwyu-prepare-args (plist-get entry :command)))))
            (display-buffer buffer-name)
            (other-window 1)
            (set-window-dedicated-p (get-buffer-window (current-buffer)) t)
            (other-window -1))
          (throw 'found t)))
      (message (format "Cannot find file %s in compile_commands.json" file)))))

(defun iwyu-reparse ()
  "Reparse the current buffer with `include-what-you-use'.
For headers (files with \\='.h\\=' extension) it uses the
corresponding implementation, i.e., the file with \\='.cpp\\='
extension."
  (interactive)
  (if-let* ((compile-commands-json
             (cl-find-if #'file-exists-p
                         (mapcar (lambda (build-dir)
                                   (expand-file-name
                                    "compile_commands.json"
                                    (expand-file-name build-dir
                                                      (projectile-project-root))))
                                 '("cmake.bld/Linux" "build" "bld" "cmake-build"
                                   "cmake-build/linux_64_static_ninja_Debug"
                                   "cmake-build/linux_64_static_make_Debug"
                                   "cmake-build/linux_64_static_ninja_Release"
                                   "cmake-build/linux_64_static_make_Release"))))
            (file-name (file-name-nondirectory buffer-file-name)))
      (iwyu-start-process-for
       compile-commands-json
       (if (string= "h" (file-name-extension file-name))
           (concat (file-name-sans-extension file-name) ".cpp")
         file-name))
    (message "Cannot find compile_commands.json for this project")))

(use-package cc-mode
  :ensure nil
  :defer t
  :bind
  (:map c-mode-base-map
   ("C-c w d" . #'iwyu-show-diagnostics-buffer)
   ("C-c w e" . #'iwyu-reparse)))



(provide 'init-iwyu)

;;; init-iwyu.el ends here
