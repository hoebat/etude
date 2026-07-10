(require 'etude-core-global)

;; Lisp Modes
(use-package smartparens
  :ensure t
  :diminish 'smartparens-mode
  :config (progn (require 'smartparens-config)
                 (smartparens-global-mode t)
                 (show-paren-mode t)))

(use-package paredit
  :ensure t
  :diminish 'paredit-mode)

(use-package rainbow-delimiters 
  :ensure t
  :diminish 'rainbow-delimiters-mode)

(use-package eros
  :ensure t)

(progn (add-hook 'lisp-interaction-mode-hook 'smartparens-strict-mode)
       (add-hook 'lisp-interaction-mode-hook 'rainbow-delimiters-mode)
       (add-hook 'lisp-interaction-mode-hook 'paredit-mode)
       (add-hook 'lisp-interaction-mode-hook 'eldoc-mode)
       (add-hook 'emacs-lisp-mode-hook 'smartparens-strict-mode)
       (add-hook 'emacs-lisp-mode-hook 'rainbow-delimiters-mode)
       (add-hook 'emacs-lisp-mode-hook 'paredit-mode)
       (add-hook 'emacs-lisp-mode-hook 'eldoc-mode)
       (add-hook 'emacs-lisp-mode-hook (lambda ()
                                         (if which-key-mode
                                             (which-key-mode t)))))
(defun e/eval-buffer ()
  (interactive)
  (eval-buffer (current-buffer) t))

(pretty-hydra-define e/menu-fn::elisp-menu
  (:title "<F12> Elisp" :quit-key "z"  :exit nil :foreign-keys run)
  ("Actions"
   (("1" ielm "Repl")
    ("2" ert  "Test")
    ("3" (ert t) "Test all")
    ("4" (ert :failed) "Test failed"))
   "Describe"
   (("f"  helpful-callable   "function")
    ("s"  helpful-symbol     "symbol")
    ("c"  helpful-command    "command")
    ("i"  helpful-at-point   "thing at point"))
   "Toggle"
   (("P" paredit-mode "Paredit" :toggle t)
    ("R" rainbow-delimiters-mode "Rainbow" :toggle t)
    ("D" toggle-debug-on-error "Debug on error" :toggle (default-value 'debug-on-error))
    ("X" toggle-debug-on-quit "Debug on quit" :toggle (default-value 'debug-on-quit)))))

(defun e/elisp-mode-menu ()
  (interactive)
  (if (eq hydra-curr-map e/menu-fn::elisp-menu/keymap)
      (hydra-keyboard-quit)
    (e/menu-fn::elisp-menu/body)))

(eta-modal [::lisp   lisp-interaction-mode "etude-core-global"]
  ::eval-cursor      'eros-eval-last-sexp
  ::eval-cursor-alt  'pp-macroexpand-last-sexp
  ::eval-file        'e/eval-buffer
  ::refresh-code     'e/eval-buffer
  ::refresh-rt       'e/no-action
  ::mode-menu        'e/elisp-mode-menu)

(eta-modal [::emacs-lisp    emacs-lisp-mode "etude-core-lisp"]
  ::eval-cursor     'eros-eval-last-sexp
  ::eval-cursor-alt 'pp-macroexpand-last-sexp
  ::eval-file       'e/eval-buffer
  ::refresh-code    'e/eval-buffer
  ::refresh-rt      'e/no-action
  ::mode-menu       'e/elisp-mode-menu)

;; (eta-modal[::eshell-mode   eshell-mode    "etude-core-lisp"]
;;   ::eval-cursor 'eval-last-sexp)

;;
;; Clojure
;;


(defhydra e/menu-fn::clojure-rt-menu (:color pink)
  ("1"  foundation/rt-setup  "Setup")
  ("2"  foundation/rt-teardown "Teardown")
  ("3"  foundation/rt-resetup  "Resetup")
  ("4"  foundation/rt-reprep  "Reprep")
  
  ("9"  foundation/rt-load "Setup Current")
  ("0"  foundation/rt-unload "Teardown Current")
  ("`"  quit-window "Exit" :exit t))

(defun e/clojure-rt-menu ()
  (interactive)
  (if (eq hydra-curr-map e/menu-fn::clojure-rt-menu/keymap)
      (hydra-keyboard-quit)
    (e/menu-fn::clojure-rt-menu/body)))

;; ACTUAL
(defhydra e/menu-fn::clojure-unit-menu (:color pink)
  
  ("1"  foundation/import-tests   "Import")
  ("2"  foundation/scaffold-tests "Scaffold")
  ("3"  foundation/incomplete-tests "Incomplete")
  ("4"  foundation/orphaned-tests "Orphaned")
  ("5"  foundation/pedantic-tests "Pedantic")
  
  ("9"  foundation/run-errored-tests "Run Errored")
  ("0"  foundation/run-tests "Run")
  ("`" quit-window "Exit" :exit t :hint nil))

(defun e/clojure-unit-menu ()
  (interactive)
  (if (eq hydra-curr-map e/menu-fn::clojure-unit-menu/keymap)
      (hydra-keyboard-quit)
    (e/menu-fn::clojure-unit-menu/body)))

(use-package cider
  :ensure t
  :init (progn (setq nrepl-log-messages t)
               (setq nrepl-buffer-name-separator "/")
               (setq nrepl-buffer-name-show-port t)
               (setq cider-prefer-local-resources t)
               (setq cider-repl-use-clojure-font-lock t))
  :bind (:map cider-mode-map
         ("M-." . cider-find-var))
  :hook ((cider-repl-mode . smartparens-strict-mode)
         (cider-repl-mode . rainbow-delimiters-mode)
         (cider-repl-mode . eldoc-mode)))

(defun e/cider-eval-buffer ()
  (interactive)
  (save-buffer)
  (cider-eval-buffer))

(use-package clojure-mode
  :ensure t
  :config (progn (require 'cider-mode)
                 (eta-modal [::clojure clojure-mode "etude-core-lisp"]
                   ::eval-cursor       'cider-eval-last-sexp
                   ::eval-file         'e/cider-eval-buffer
                   ::esc-f2            'foundation/rt-print-module
                   ::esc-f3            'foundation/hotkey-0
                   ::esc-f4            'foundation/hotkey-1 
                   ::f5                'foundation/ns-clear
                   ::esc-f5            'foundation/rt-module-purge
                   ::f6                'foundation/build-triggered
                   
                   ::f8                'foundation/test-setup-global
                   ::esc-f8            'foundation/test-teardown-global
                   ::f9                'clay-make-ns-quarto-html
                   ::f10               'e/cider-eval-buffer

                   ::cc-0              'foundation/print-or-clip-last-expr
                   ::cc-1              'foundation/ptr-print-or-clip
                   ::cc-3              'foundation/ptr-setup
                   ::cc-4              'foundation/ptr-teardown
                   
                   ::mode-connect      'cider-connect
                   ::mode-toggle-test  'projectile-toggle-between-implementation-and-test
                   ::mode-menu         'e/clojure-unit-menu)
                 (eta-modal [::cider-repl cider-repl-mode "etude-core-lisp"]
                   ::eval-file   'cider-repl-clear-buffer))
  :hook ((clojure-mode . smartparens-strict-mode)
         (clojure-mode . rainbow-delimiters-mode)
         (clojure-mode . paredit-mode)
         (clojure-mode . eldoc-mode)))


(require 'midje-mode)
(progn (define-clojure-indent
         (comment 'defun))
       (define-clojure-indent
         (fn:> :defn)))

(provide 'etude-core-lisp)


;; (major-mode-hydra-define emacs-lisp-mode nil
;;   ("Eval"
;;    (("b" eval-buffer "buffer")
;;     ("e" eval-defun "defun")
;;     ("r" eval-region "region"))
;;    "REPL"
;;    (("I" ielm "ielm"))
;;    "Test"
;;    (("t" ert "prompt")
;;     ("T" (ert t) "all")
;;     ("F" (ert :failed) "failed"))
;;    "Doc"
;;    (("d" describe-foo-at-point "thing-at-pt")
;;     ("f" describe-function "function")
;;     ("v" describe-variable "variable")
;;     ("i" info-lookup-symbol "info lookup"))));
