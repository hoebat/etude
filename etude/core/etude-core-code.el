
;; Automatic completion
(define-key read-expression-map (kbd "TAB") 'completion-at-point)

(use-package company
  :ensure t
  :diminish 'company-mode
  :init   (progn (setq company-idle-delay 0.05)
                 (setq company-tooltip-limit 20)
                 (setq company-minimum-prefix-length 1)
                 (setq company-tooltip-flip-when-above t)
                 (setq company-show-numbers t))
  :config (progn (add-hook 'after-init-hook 'global-company-mode)
                 (define-key company-active-map
                   " "
                   (lambda ()
                     (interactive)
                     (company-abort)
                     (self-insert-command 1)))
                 (define-key company-active-map (kbd "<return>") nil)))

(use-package company-fuzzy :ensure t)


(use-package gptel
  :ensure t
  :bind ("C-c g" . gptel-menu)
  :config
  ;; Create Kimi backend
  (setq gptel-backend
        (gptel-make-openai "Kimi"
          :host "api.moonshot.cn"
          :endpoint "/v1/chat/completions"
          :key "sk-kimi-SnSpDyjOwCcw9nBephISr8CJEQ15UvDecO73rF5I6nkIgb3J7RpvDZPuO1R3uyRw"
          :models '("kimi-for-coding" "kimi-k2" "kimi-latest")
          :header '(("User-Agent" . "KimiCLI/1.12.0"))))
  
  ;; Default model
  (setq gptel-model "kimi-for-coding")
  
  ;; Default system prompt
  (setq gptel-system-prompt
        "You are a helpful coding assistant. Provide concise, accurate code suggestions."))

(provide 'etude-core-code)
