;;; init-vertco.el --- Vertico  -*- no-byte-compile: t; lexical-binding: t; -

;;; Commentary:
;;; vertico.el - VERTical Interactive COmpletion
;;; https://github.com/minad/vertico
;;;
;;; Vertico provides a performant and minimalistic vertical completion UI based
;;; on the default completion system. The focus of Vertico is to provide a UI
;;; which behaves correctly under all circumstances. By reusing the built-in
;;; facilities system, Vertico achieves full compatibility with built-in Emacs
;;; completion commands and completion tables. Vertico only provides the
;;; completion UI but aims to be highly flexible, extendable and modular.
;;; Additional enhancements are available as extensions or complementary
;;; packages. The code base is small and maintainable. The main vertico.el
;;; package is only about 600 lines of code without white space and comments.
;;;
;;; See also:
;;;   https://github.com/jwiegley/dot-emacs/blob/master/init.org
;;;   https://github.com/jamescherti/minimal-emacs.d?tab=readme-ov-file#code-completion-with-corfu
;;;

;;; Code:

(use-package vertico
  :demand t
  :bind  (:map vertico-map
               ("?" . minibuffer-completion-help)
               ("M-RET" . minibuffer-force-complete-and-exit)
               ("M-TAB" . minibuffer-complete)
               ("C-n" . vertico-next)
               ("C-p" . vertico-previous))
  :custom
  (vertico-count 13)                    ; Number of candidates to display
  (vertico-resize t)
  (vertico-cycle nil) ; Go from last to first candidate and first to last (cycle)?
  :config
  (vertico-mode))

;; Enable rich annotations using the Marginalia package
(use-package marginalia
  ;; Bind `marginalia-cycle' locally in the minibuffer.  To make the binding
  ;; available in the *Completions* buffer, add it to the
  ;; `completion-list-mode-map'.
  :demand t
  :bind (:map minibuffer-local-map
              ("M-A" . marginalia-cycle))

  :custom
  (marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light nil))
  (marginalia-max-relative-age 0)
  (marginalia-align 'right)

  :hook (after-init . marginalia-mode)
  )

(use-package orderless
  :demand t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package consult
  :demand t
  :hook (completion-list-mode . consult-preview-at-point-mode)
  :bind (;; A recursive grep
         ("M-s M-g" . consult-grep)
         ;; Search for files names recursively
         ("M-s M-f" . consult-find)
         ;; Search through the outline (headings) of the file
         ("M-s M-o" . consult-outline)
         ;; Search the current buffer
         ("M-s M-l" . consult-line)
         ;; Switch to another buffer, or bookmarked file, or recently
         ;; opened file.
         ("M-s M-b" . consult-buffer))
  :config
  (setq consult-line-numbers-widen t)
  (setq consult-preview-key 'any)
  )

(use-package embark
  :demand t
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)
         ("C-h B" . embark-bindings)
         :map minibuffer-local-map
         ("C-c C-c" . embark-collect)
         ("C-c C-e" . embark-export))
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package wgrep
  :demand t
  :bind ( :map grep-mode-map
          ("e" . wgrep-change-to-wgrep-mode)
          ("C-x C-q" . wgrep-change-to-wgrep-mode)
          ("C-c C-c" . wgrep-finish-edit)))

(savehist-mode 1)

(recentf-mode 1)

(use-package all-the-icons-completion
  :after (marginalia all-the-icons)
  :demand t
  :hook (marginalia-mode . all-the-icons-completion-marginalia-setup)
  :init
  (all-the-icons-completion-mode))


(provide 'init-vertico)
;;; init-vertico.el ends here
