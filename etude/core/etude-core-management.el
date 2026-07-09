(require 'etude-core-shell)

;;
;; Movement/Cut/Paste/Undo
;;

(use-package which-key :ensure t
  :init (progn (setq which-key-sort-order 
                     'which-key-local-then-key-order)))

(use-package goggles
  :ensure t
  :init   (setq-default goggles-pulse t)
  :config (goggles-mode))

(use-package undo-tree
  :ensure t
  :diminish 'undo-tree-mode
  :config (global-undo-tree-mode t))

;;
;; File Management
;;

(use-package no-littering :ensure t)

(use-package recentf
  :ensure t
  :config (progn (setq recentf-max-saved-items 200
                       recentf-max-menu-items 15)
                 (recentf-mode t)))

(use-package dired-subtree :ensure t
  :bind (:map dired-mode-map
         ("i" . dired-subtree-toggle)))

(use-package dired-collapse :ensure t
  :hook (dired-mode . dired-collapse-mode))

(use-package dired-filter :ensure t
  :hook (dired-mode . (lambda () (dired-filter-group-mode)
                        (dired-filter-by-garbage)))
  :custom
  (dired-garbage-files-regexp
   "*.\\(aux\\|bak\\|dvi\\|log\\|orig\\|rej\\|toc\\|out\\)")
  (dired-filter-group-saved-groups
   '(("default"
      ("Org"    (extension "org"))
      ("Executables" (exexutable))
      ("Directories" (directory))
      ("PDF"    (extension "pdf"))
      ("LaTeX"  (extension "tex" "bib"))
      ("Images" (extension "png"))
      ("Code"   (extension "java" "el" "clj" "js"))
      ("Archives"(extension "zip" "rar" "gz" "bz2" "tar"))))))

;;
;; Project Management
;;

(use-package projectile
  :ensure t
  :diminish 'projectile-mode
  :init (setq projectile-completion-system 'ivy)
  :config
  ;; Define test file patterns for generic projects
  (setq projectile-test-prefix "test_")
  (setq projectile-test-suffix "_test")
  ;; Register common project types
  (projectile-register-project-type 'generic
                                    '()
                                    :test-prefix "test_"
                                    :test-suffix "_test"))

(use-package ibuffer-projectile :ensure t
  :config (add-hook 'ibuffer-hook
                    (lambda ()
                      (ibuffer-projectile-set-filter-groups)
                      (unless (eq ibuffer-sorting-mode 'alphabetic)
                        (ibuffer-do-sort-by-alphabetic)))))

(defun e/start-screen ()
  (interactive)
  (dashboard-insert-startupify-lists)
  (redisplay)
  (switch-to-buffer "*dashboard*")
  (define-key dashboard-mode-map [down-mouse-1] 'nil))

(use-package dashboard
  :ensure t
  :init (progn (setq dashboard-startup-banner nil)
               (setq dashboard-items '((recents  . 15)
                                       (projects . 5)))))

(use-package treemacs :ensure t
  :init (setq treemacs-no-png-images t))

(use-package treemacs-projectile :ensure t)
          
;;
;; Search
;;

(use-package git-gutter
   :ensure t
   :diminish 'git-gutter-mode
   :config   (global-git-gutter-mode t))
   
(use-package smex :ensure t)

(use-package ivy
  :ensure t
  :diminish 'ivy-mode
  :config (progn (ivy-mode t)
                 (setq ivy-initial-inputs-alist nil)
                 (setq ivy-use-virtual-buffers t)
                 (setq ivy-virtual-abbreviate 'abbreviate)     
                 (setq enable-recursive-minibuffers t)
                 (setq ivy-count-format "(%d/%d)")))

(require 'wgrep)

(require 'color-rg)

(use-package swiper :ensure t)

(use-package counsel :ensure t)

(use-package counsel-projectile
  :ensure t
  :init (add-hook 'after-init-hook 'counsel-projectile-mode))

(use-package ivy-rich
  :ensure t
  :config (ivy-rich-mode t))

(provide 'etude-core-management)
