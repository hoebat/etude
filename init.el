;; Boot

;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.

(setq gc-cons-threshold (* 50 1000 1000))

(progn (setq emacs-d
             (file-name-directory
              (or (buffer-file-name) 
                  (file-chase-links load-file-name))))
       (add-to-list 'load-path (concat emacs-d "etude"))
       (add-to-list 'load-path (concat emacs-d "dev/" "eta"))
       (add-to-list 'load-path (concat emacs-d "dev/" "eta-hydra"))
       (add-to-list 'load-path (concat emacs-d "dev/" "eta-logger"))
       (add-to-list 'load-path (concat emacs-d "dev/" "midje-mode")))

(setq use-package-always-ensure nil)

(defcustom cider-use-xref nil "NO XREF FOR CIDER")

;; Core
(require 'etude-boot)
(use-package ht :ensure t)
(use-package hydra :ensure t)
(use-package pretty-hydra :ensure t)
(use-package cider :ensure t)
(use-package doom-modeline :ensure t)
(use-package counsel-projectile :ensure t)
(use-package vterm :ensure t)

;; Core chat / rewrite / context
(use-package gptel
  :ensure t
  :custom
  (gptel-default-mode 'org-mode)
  :config
  ;; ChatGPT Plus/Pro / OpenAI subscription path.
  ;; gptel supports an OAuth backend for OpenAI subscription access.
  ;; Use this if you want ChatGPT-style subscription access inside Emacs.
  (gptel-make-openai-oauth "OpenAI-sub")

  ;; OpenAI Codex / API-key path.
  ;; Uses the standard OpenAI API with Codex-capable models.
  (gptel-make-openai "Codex"
    :host "api.openai.com"
    :key (lambda ()
           (or (auth-source-pick-first-password
                :host "api.openai.com"
                :user "apikey")
               (getenv "OPENAI_API_KEY")))
    :stream t
    :models '("gpt-5.5"
              "gpt-5.4"
              "gpt-5.4-mini"
              "gpt-5.3-codex-spark"))

  ;; Kimi / Kimi Code API path.
  ;; Kimi Code uses api.kimi.com/coding with OpenAI-compatible endpoints.
  ;; This endpoint requires a coding-agent User-Agent for authorization.
  (gptel-make-openai "Kimi"
    :host "api.kimi.com"
    :endpoint "/coding/v1/chat/completions"
    :key (lambda ()
           (or (auth-source-pick-first-password
                :host "api.kimi.com"
                :user "apikey")
               (getenv "KIMI_API_KEY")
               (getenv "MOONSHOT_API_KEY")))
    :header (lambda (_info)
              (when-let* ((key (gptel--get-api-key)))
                `(("Authorization" . ,(concat "Bearer " key))
                  ("User-Agent" . "claude-code/0.1.0"))))
    :stream t
    :models '("kimi-k2.7-code-highspeed"
              "kimi-k2.7-code"
              "kimi-k2.6"
              "kimi-k2.5"
              "kimi-latest"))

  ;; Pick a default. Change this from gptel-menu whenever needed.
  (setq gptel-backend (gptel-get-backend "Kimi")
        gptel-model "kimi-k2.7-code-highspeed"))

(require 'eta)
(require 'eta-hydra)
(require 'eta-logger)

(require 'etude-core)
(require 'etude-bindings)
(require 'etude-foundation)

(setq custom-safe-themes t)

(if (not (window-system))
    (custom-set-faces
     '(custom-comment ((t (:foreground "color-115"))))
     '(font-lock-comment-delimiter-face ((t (:foreground "color-243"))))
     '(font-lock-comment-face ((t (:foreground "color-243"))))
     '(font-lock-doc-face ((t (:foreground "color-243"))))
     '(org-block-begin-line ((t (:foreground "color-99"))))
     '(org-block-end-line ((t (:foreground "color-92"))))
     '(org-meta-line   ((t (:foreground "yellow"))))
     '(org-link ((t (:foreground "brightblue" :underline nil)))))
  (custom-set-faces
   '(org-block-begin-line ((t (:foreground "Purple"))))
   '(org-block-end-line ((t (:foreground "DarkOrchid"))))
   '(org-meta-line   ((t (:foreground "gold1"))))
   '(org-hide ((t (:foreground "gray50" :underline nil))))
   '(org-link ((t (:foreground "turquoise3" :underline nil))))))

(setq gc-cons-threshold (* 2 1000 1000))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-comment ((t (:foreground "color-115"))))
 '(eros-result-overlay-face ((t (:background "black" :box (:line-width -1 :color "black")))))
 '(font-lock-comment-delimiter-face ((t (:foreground "color-243"))))
 '(font-lock-comment-face ((t (:foreground "color-243"))))
 '(font-lock-doc-face ((t (:foreground "color-243"))))
 '(goggles-added ((t (:background "brightblack"))))
 '(goggles-changed ((t (:background "brightblack"))))
 '(goggles-removed ((t (:extend t :background "brightblack"))))
 '(org-block-begin-line ((t (:foreground "color-99"))))
 '(org-block-end-line ((t (:foreground "color-92"))))
 '(org-hide ((t (:foreground "gray50" :underline nil))))
 '(org-link ((t (:foreground "brightblue" :underline nil))))
 '(org-meta-line ((t (:foreground "yellow")))))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(blink-cursor-mode nil)
 '(custom-enabled-themes 'nord)
 '(custom-safe-themes
   '("5a4cdc4365122d1a17a7ad93b6e3370ffe95db87ed17a38a94713f6ffe0d8ceb" "46f5e010e0118cc5aaea1749cc6a15be4dfce27c0a195a0dff40684e2381cf87" default))
 '(doom-modeline-icon nil)
 '(eros-mode t)
 '(global-linum-mode nil)
 '(nord-comment-brightness 20)
 '(org-babel-load-languages
   '((emacs-lisp . t) (js . t) (python . t) (shell . t) (dot . t)
     (java . t)))
 '(org-mouse-1-follows-link 'double)
 '(org-support-shift-select 'always)
 '(package-selected-packages
   '(auto-highlight-symbol cider clay company-fuzzy counsel-projectile
                           dashboard dired-collapse dired-filter
                           dired-subtree doom-modeline eros
                           exec-path-from-shell git-gutter goggles
                           gptel ibuffer-projectile ivy-rich
                           markdown-mode minuet no-littering
                           nord-theme paredit pretty-hydra
                           rainbow-delimiters smartparens smex
                           treemacs-projectile undo-tree vterm)))

(when (display-graphic-p)
  (load-theme 'nord t))
