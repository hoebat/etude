(require 'cl-lib)
(require 'cider)

(defcustom foundation/std-lang-project-root
  "/Users/chris/Development/greenways/gw-v2/ref/foundation"
  "Root directory for the foundation hara.lang sources."
  :type 'directory)

(defconst foundation/std-lang-dsl-form-heads
  '("def.xt" "def.js" "defn.xt" "defn.js"))

(defvar foundation/std-lang-dsl-symbol-cache
  (make-hash-table :test #'equal))

(defun foundation/std-lang--buffer-in-project-p ()
  (let ((file (or buffer-file-name default-directory))
        (root (and foundation/std-lang-project-root
                   (expand-file-name foundation/std-lang-project-root))))
    (and file
         root
         (file-directory-p root)
         (file-in-directory-p (expand-file-name file)
                              (file-name-as-directory root)))))

(defun foundation/std-lang--symbol-bounds ()
  (save-excursion
    (skip-chars-backward "[:alnum:]*+!?.<>:=/_-")
    (let ((start (point)))
      (skip-chars-forward "[:alnum:]*+!?.<>:=/_-")
      (let ((end (point)))
        (and (< start end)
             (cons start end))))))

(defun foundation/std-lang--inside-dsl-form-p ()
  (unless (or (nth 3 (syntax-ppss))
              (nth 4 (syntax-ppss)))
    (save-excursion
      (let (found)
        (while (and (not found)
                    (condition-case nil
                        (progn
                          (backward-up-list 1)
                          t)
                      (error nil)))
          (when (looking-at-p "(")
            (forward-char 1)
            (skip-syntax-forward " ")
            (let ((head (symbol-at-point)))
              (when (and head
                         (member (symbol-name head)
                                 foundation/std-lang-dsl-form-heads))
                (setq found t))))
          (unless found
            (goto-char (max (point-min) (1- (point))))))
        found))))

(defun foundation/std-lang--collect-dsl-symbols-fallback (root)
  (let (out)
    (dolist (file (directory-files-recursively root "\\.clj[cx]?\\'"))
      (with-temp-buffer
        (insert-file-contents file)
        (goto-char (point-min))
        (while (re-search-forward "x:[A-Za-z0-9*+!?.<>:=/_-]+" nil t)
          (push (match-string-no-properties 0) out))))
    (sort (delete-dups out) #'string<)))

(defun foundation/std-lang-refresh-dsl-cache (&optional root)
  (interactive)
  (let* ((root (expand-file-name (or root foundation/std-lang-project-root)))
         (src-root (expand-file-name "src" root))
         (symbols
          (or (ignore-errors
                (sort
                 (delete-dups
                 (process-lines "rg"
                                 "-o"
                                 "-N"
                                 "--no-filename"
                                 "-g" "*.clj"
                                 "-g" "*.cljc"
                                 "x:[A-Za-z0-9*+!?.<>:=/_-]+"
                                 src-root))
                 #'string<))
              (foundation/std-lang--collect-dsl-symbols-fallback src-root))))
    (puthash root symbols foundation/std-lang-dsl-symbol-cache)
    (when (called-interactively-p 'interactive)
      (message "foundation hara.lang DSL cache refreshed (%s symbols)"
               (length symbols)))
    symbols))

(defun foundation/std-lang--dsl-symbols ()
  (let ((root (expand-file-name foundation/std-lang-project-root)))
    (or (gethash root foundation/std-lang-dsl-symbol-cache)
        (foundation/std-lang-refresh-dsl-cache root))))

(defun foundation/std-lang-dsl-capf ()
  (when (and (foundation/std-lang--buffer-in-project-p)
             (foundation/std-lang--inside-dsl-form-p))
    (let* ((bounds (foundation/std-lang--symbol-bounds))
           (start (and bounds (car bounds)))
           (end (and bounds (cdr bounds))))
      (when bounds
        (let ((prefix (buffer-substring-no-properties start end)))
          (when (string-prefix-p "x" prefix)
            (list start
                  end
                  (completion-table-dynamic
                   (lambda (input)
                     (all-completions input
                                      (foundation/std-lang--dsl-symbols))))
                  :exclusive 'no
                  :annotation-function (lambda (_candidate) " dsl"))))))))

(defun foundation/std-lang-setup-dsl-completion ()
  (when (foundation/std-lang--buffer-in-project-p)
    (setq-local completion-at-point-functions
                (cons #'foundation/std-lang-dsl-capf
                      (remove #'foundation/std-lang-dsl-capf
                              completion-at-point-functions)))))

(add-hook 'clojure-mode-hook #'foundation/std-lang-setup-dsl-completion)
(add-hook 'cider-mode-hook #'foundation/std-lang-setup-dsl-completion)

(defun foundation/debug-last-sexp ()
  (interactive)
  (message (or (cider-last-sexp)
               "<NONE>")))

(defun foundation/cider-eval (code)
  (interactive)
  (message code)
  (cider-interactive-eval
   code
   nil
   nil
   nil))

(defun foundation/cider-eval-at-point (code)
  (interactive)
  (message "%s" code)
  (cider-interactive-eval
   code
   (cider-interactive-eval-handler nil (point))
   (cider-last-sexp 'bounds)
   nil))

(defun foundation/make-format-handler ()
  (nrepl-make-response-handler (current-buffer)
                               (lambda (buffer value)
                                 (with-current-buffer buffer
                                   (insert
                                    (if (derived-mode-p 'cider-clojure-interaction-mode)
                                        (format "\n%s\n" value)
                                      value))
                                   (cider-format-edn-last-sexp)))
                               (lambda (_buffer out)
                                 (cider-emit-interactive-eval-output out))
                               (lambda (_buffer err)
                                 (cider-emit-interactive-eval-err-output err))
                               '()))


(defun foundation/rt-print-module (&optional prefix)
  (interactive)
  (save-buffer)
  (cider-eval-buffer)
  (foundation/cider-eval "(hara.lang/print-module)"))

(defun foundation/rt-restart ()
  (interactive)
  (foundation/cider-eval "(hara.lang/rt:restart)"))

(defun foundation/ns-clear ()
  (interactive)
  (save-buffer)
  (foundation/cider-eval "(do (jvm.namespace/clear))"))

(defun foundation/build-triggered ()
  (interactive)
  (save-buffer)
  (cider-eval-buffer)
  (foundation/cider-eval "(std.make/build-triggered)"))

;;
(defun foundation/scaffold-tests ()
  (interactive)
  (foundation/cider-eval
   "(code.manage/create-tests (code.project/source-ns (std.lib/ns-sym)))"))

(defun foundation/import-tests ()
  (interactive)
  (foundation/cider-eval
   "(code.manage/import (code.project/source-ns (std.lib/ns-sym)))"))

;;
;;
;;

(defun foundation/test-setup-global ()
  (interactive)
  (foundation/cider-eval "[(code.test/run:load) (code.test/fact:global :setup)]"))

(defun foundation/test-prep-global ()
  (interactive)
  (foundation/cider-eval "[(code.test/run:load) (code.test/fact:global :prelim) (code.test/fact:global :setup)]"))

(defun foundation/test-teardown-global ()
  (interactive)
  (foundation/cider-eval "(code.test/fact:global :teardown)"))


(defun foundation/rt-deploy ()
  (interactive)
  (foundation/cider-eval "[(rt.solidity/rt:deploy)]"))

;;
;;
;;

(defun foundation/run-errored-tests ()
  (interactive)
  (foundation/cider-eval "(code.test/run-errored)"))

(defun foundation/run-tests ()
  (interactive)
  (foundation/cider-eval "(code.test/run)"))

(defun foundation/ptr-deploy ()
  (interactive)
  (foundation/cider-eval-at-point
   (concat "(rt.solidity/rt:deploy-ptr " (cider-last-sexp) ")")))

(defun foundation/ptr-teardown ()
  (interactive)
  (foundation/cider-eval-at-point
   (concat "(hara.lang/with:print-all (hara.lang/ptr-teardown " (cider-last-sexp) "))")))

(defun foundation/ptr-setup ()
  (interactive)
  (foundation/cider-eval-at-point
   (concat "(hara.lang/with:print-all (hara.lang/ptr-setup " (cider-last-sexp) "))")))

(defun foundation/ptr-teardown-deps ()
  (interactive)
  (foundation/cider-eval-at-point
   (concat "(hara.lang/with:print-all (hara.lang/ptr-teardown-deps " (cider-last-sexp) "))")))

(defun foundation/ptr-setup-deps ()
  (interactive)
  (foundation/cider-eval-at-point
   (concat "(hara.lang/with:print-all (hara.lang/ptr-setup-deps " (cider-last-sexp) "))")))

(defun foundation/ptr-emit ()
  (interactive)
  (foundation/cider-eval-at-point
   (concat "(hara.lang/emit-ptr" (cider-last-sexp) ")")))

(defun foundation/rt-module-purge ()
  (interactive)
  (save-buffer)
  (foundation/cider-eval "(hara.lang/rt:module-purge)"))

(defun foundation/ptr-print-or-clip (&optional prefix)
  (interactive "P")
  (if prefix
      (foundation/cider-eval-at-point
       (concat "(hara.lang/ptr-print " (cider-last-sexp) ")"))
    (foundation/cider-eval-at-point
     (concat "(hara.lang/ptr-clip " (cider-last-sexp) ")"))))

(defun foundation/ptr-redis-print-or-clip (&optional prefix)
  (interactive "P")
  (if prefix
      (foundation/cider-eval-at-point
       (concat "(std.lib/pl (rt.redis/generate-script " (cider-last-sexp) "))"))
    (foundation/cider-eval-at-point
     (concat "(std.lib/clip:nil (rt.redis/generate-script " (cider-last-sexp) "))"))))

(defun foundation/insert-uuid ()
  (interactive)
  (cider-interactive-eval "(str (std.lib/uuid))"
                          (cider-eval-print-handler)
                          nil
                          (cider--nrepl-pr-request-map)))

(defun foundation/wrangle-long-string ()
  (interactive)
  (let ((last-sexp (cider-last-sexp)))
    (let ((opoint  (point)))
      (clojure-backward-logical-sexp)
      (kill-region (point) opoint)
      (cider-interactive-eval (concat "(std.string/lines " last-sexp ")")
                              (foundation/make-format-handler)
                              nil
                              (cider--nrepl-pr-request-map)))))

(defun foundation/add-trace ()
  (interactive)
  (foundation/cider-eval-at-point
   (concat "(std.lib/add-base-trace (var " (cider-last-sexp) "))")))

(defun foundation/add-print-trace ()
  (interactive)
  (foundation/cider-eval-at-point
   (concat "(std.lib/add-print-trace (var " (cider-last-sexp) "))")))

(defun foundation/add-stack-trace ()
  (interactive)
  (foundation/cider-eval-at-point
   (concat "(std.lib/add-stack-trace (var " (cider-last-sexp) "))")))

(defun foundation/remove-trace ()
  (interactive)
  (foundation/cider-eval-at-point
   (concat "(std.lib/remove-trace (var " (cider-last-sexp) "))")))

(defun foundation/get-trace ()
  (interactive)
  (foundation/cider-eval-at-point
   (concat "(std.lib/get-trace (var " (cider-last-sexp) "))")))

(defun foundation/output-trace ()
  (interactive)
  (cider-interactive-eval (concat "(std.lib/output-trace (var " (cider-last-sexp) "))")
                          (cider-eval-print-handler)
                          nil
                          (cider--nrepl-pr-request-map)))

(defun foundation/trace-ns ()
  (interactive)
  (foundation/cider-eval "(std.lib/trace-ns)"))

(defun foundation/trace-print-ns ()
  (interactive)
  (foundation/cider-eval "(std.lib/trace-print-ns)"))

(defun foundation/untrace-ns ()
  (interactive)
  (foundation/cider-eval "(std.lib/untrace-ns)"))

(defun foundation/paste-string ()
  (interactive)
  (cider-interactive-eval "(std.lib/paste)"
                          (cider-eval-print-handler)
                          nil
                          (cider--nrepl-pr-request-map)))

(defun foundation/lang-add-js-module ()
  (interactive)
  (cider-interactive-eval "'(def.js MODULE (!:module))"
                          (cider-eval-print-handler)
                          nil
                          (cider--nrepl-pr-request-map)))

(defun foundation/lang-add-xt-module ()
  (interactive)
  (cider-interactive-eval "'(def.xt MODULE (!:module))"
                          (cider-eval-print-handler)
                          nil
                          (cider--nrepl-pr-request-map)))

(defun foundation/print-or-clip-last-expr (&optional prefix)
  (interactive)
  (if prefix
      (foundation/cider-eval-at-point
       (concat "(std.lib/prf " (cider-last-sexp) ")"))
    (foundation/cider-eval-at-point
     (concat "(std.lib/clip:nil " (cider-last-sexp) ")"))))

(defun foundation/print-or-clip-last-expr-backup (&optional prefix)
  (interactive)
  (if prefix
      (foundation/cider-eval-at-point
       (concat "(std.lib/prf " (cider-last-sexp) ")"))
    (foundation/cider-eval-at-point
     (concat "(std.lib/clip:nil " (cider-last-sexp) ")"))))

(defun foundation/paste-long-string ()
  (interactive)
  (cider-interactive-eval "(std.string/lines (std.lib/paste))"
                          (foundation/make-format-handler)
                          nil
                          (cider--nrepl-pr-request-map)))

(defun foundation/paste-format ()
  (interactive)
  (cider-interactive-eval "(read-string (std.lib/paste))"
                          (foundation/make-format-handler)
                          nil
                          (cider--nrepl-pr-request-map)))

(defun foundation/hotkey-0 ()
  (interactive)
  (save-buffer)
  (cider-eval-buffer)
  (foundation/cider-eval "(./hotkey-0)"))

(defun foundation/hotkey-1 ()
  (interactive)
  (save-buffer)
  (cider-eval-buffer)
  (foundation/cider-eval "(./hotkey-1)"))

(defun foundation/hotkey-2 ()
  (interactive)
  (save-buffer)
  (cider-eval-buffer)
  (foundation/cider-eval "(./hotkey-2)"))

(defun foundation/hotkey-3 ()
  (interactive)
  (save-buffer)
  (cider-eval-buffer)
  (foundation/cider-eval "(./hotkey-3)"))

(defun foundation/hotkey-4 ()
  (interactive)
  (save-buffer)
  (cider-eval-buffer)
  (foundation/cider-eval "(./hotkey-4)"))


(defun statstrade/refresh-statsweb-index ()
  (interactive)
  (save-buffer)
  (cider-eval-buffer)
  (foundation/cider-eval "(./refresh-statsweb-index)"))

(defun statstrade/refresh-pune-00-all-web-cell ()
  (interactive)
  (save-buffer)
  (cider-eval-buffer)
  (foundation/cider-eval "(./refresh-pune-00-all-web-cell)"))

(defun statstrade/refresh-statsall ()
  (interactive)
  (save-buffer)
  (cider-eval-buffer)
  (foundation/cider-eval "(./refresh-statsall)"))

(provide 'etude-foundation)
