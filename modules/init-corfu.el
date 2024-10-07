;;; init-corfu.el --- Init Corfu -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:
;;; corfu.el - COmpletion in Region FUnction
;;; https://github.com/minad/corfu/tree/main
;;;
;;; Corfu enhances in-buffer completion with a small completion popup. The
;;; current candidates are shown in a popup below or above the point. The
;;; candidates can be selected by moving up and down. Corfu is the minimalistic
;;; in-buffer completion counterpart of the Vertico minibuffer UI.
;;;
;;; See also:
;;;   https://github.com/jwiegley/dot-emacs/blob/master/init.org
;;;   https://github.com/jamescherti/minimal-emacs.d?tab=readme-ov-file#code-completion-with-corfu
;;;
;;; cape.el - Let your completions fly!
;;; https://github.com/minad/cape
;;;
;;; Cape provides Completion At Point Extensions which can be used in
;;; combination with Corfu, Company or the default completion UI. The
;;; completion backends used by completion-at-point are so called
;;; completion-at-point-functions (Capfs).

;;; Code:

(use-package corfu
  :commands (corfu-mode global-corfu-mode)
  :hook ((prog-mode . corfu-mode)
         (shell-mode . corfu-mode)
         (eshell-mode . corfu-mode))
  :bind ( :map corfu-map
          ("C-n" . corfu-next)
          ("C-p" . corfu-previous)
          ("<escape>" . corfu-quit)
          ("<return>" . corfu-insert)
          ("M-d"      . corfu-info-documentation)
          ("M-l"      . corfu-info-location)
          ("M-."      . corfu-move-to-minibuffer))
  :custom
  (corfu-auto nil)
  (corfu-auto-prefix 2)
  (corfu-auto-delay 0.25)

  (corfu-min-width 80)
  (corfu-max-width corfu-min-width)       ; Always have the same width
  (corfu-count 14)
  (corfu-scroll-margin 4)
  (corfu-cycle nil)

  :preface
  (defun corfu-move-to-minibuffer ()
    (interactive)
    (let (completion-cycle-threshold completion-cycling)
      (apply #'consult-completion-in-region completion-in-region--data)))

  :config
  (global-corfu-mode))

(use-package kind-icon
  :ensure t
  :after corfu
  :custom
  (kind-icon-blend-background t)
  (kind-icon-default-face 'corfu-default) ; only needed with blend-background
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(use-package corfu-popupinfo
  :ensure nil ; extension installed with corfu
  :after corfu
  :hook (corfu-mode . corfu-popupinfo-mode)
  :bind (:map corfu-map
              ("M-n" . corfu-popupinfo-scroll-up)
              ("M-p" . corfu-popupinfo-scroll-down)
              ([remap corfu-show-documentation] . corfu-popupinfo-toggle))
  :custom
  (corfu-popupinfo-delay 0.5)
  (corfu-popupinfo-max-width 70)
  (corfu-popupinfo-max-height 20)
  ;; Also here to be extra-safe that this is set when `corfu-popupinfo' is
  ;; loaded. I do not want documentation shown in both the echo area and in
  ;; the `corfu-popupinfo' popup.
  (corfu-echo-documentation nil))

(use-package cape
  :commands (cape-dabbrev cape-file cape-elisp-block)
  ;; Bind prefix keymap providing all Cape commands under a mnemonic key.
  ;; Press C-c . ? to for help.
  :bind ("C-c /" . cape-prefix-map)
  :init
  ;; Add to the global default value of `completion-at-point-functions' which is
  ;; used by `completion-at-point'.  The order of the functions matters, the
  ;; first function returning a result wins.  Note that the list of buffer-local
  ;; completion functions takes precedence over the global list.

  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block)
  (add-hook 'completion-at-point-functions #'cape-abbrev)
  ;; (add-hook 'completion-at-point-functions #'cape-history)
  ;; ...
  )

(use-package elisp-mode-cape
  :ensure nil
  :no-require t
  :after (cape elisp-mode)
  :hook (emacs-lisp-mode . my/setup-elisp)
  :preface
  (defun my/setup-elisp ()
    (setq-local completion-at-point-functions
                `(,(cape-capf-super
                    #'elisp-completion-at-point
                    #'cape-dabbrev)
                  cape-file)
                cape-dabbrev-min-length 5)))

;;; https://raw.githubusercontent.com/jwiegley/dot-emacs/ada39160b1c6ab0991c0937b8a952b0be5d8e5ae/init.org

(provide 'init-corfu)
;;; init-corfu.el ends here
