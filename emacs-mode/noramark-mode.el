;; experiment: noramark mode
(require 'outline)

(defconst noramark-mode-version "0.1"
  "NoraMark mode version number.")

;;; Customizable Variables ====================================================

(defvar noramark-mode-hook nil
  "Hook run when entering NoraMark mode.")

(defgroup noramark nil
  "Major mode for editing text files in NoraMark format."
  :prefix "noramark-"
  :group 'noramark)



;;; Font Lock =================================================================

(require 'font-lock)

(defvar noramark-header-face 'noramark-header-face
  "Face name to use as a base for header.")

(defvar noramark-inline-code-face 'noramark-inline-code-face
  "Face name to use for inline code.")

(defvar noramark-list-face 'noramark-list-face
  "Face name to use for list markers.")

(defvar noramark-pre-face 'noramark-pre-face
  "Face name to use for preformatted text.")

(defvar noramark-language-keyword-face 'noramark-language-keyword-face
  "Face name to use for programming language identifiers.")

(defvar noramark-link-face 'noramark-link-face
  "Face name to use for links.")

(defvar noramark-keyword-face 'noramark-keyword-face
  "Face name to use for noramark keywords.")

(defvar noramark-frontmatter-face 'noramark-frontmatter-face
  "Face name to use for noramark frontmatter.")

(defvar noramark-command-face 'noramark-command-face
  "Face name to use for noramark command.")

(defgroup noramark-faces nil
  "Faces used in NoraMark Mode"
  :group 'noramark
  :group 'faces)

(defface noramark-header-face
  '((t (:inherit font-lock-function-name-face :weight bold)))
  "Base face for headers."
  :group 'noramark-faces)

(defface noramark-command-face
  '((t (:inherit font-lock-comment-face)))
  "command face."
  :group 'noramark-faces)

(defface noramark-inline-code-face
  '((t (:inherit font-lock-constant-face)))
  "Face for inline code."
  :group 'noramark-faces)

(defface noramark-list-face
  '((t (:inherit font-lock-keyword-face :weight bold)))
  "Face for list item markers."
  :group 'noramark-faces)

(defface noramark-pre-face
  '((t (:inherit font-lock-constant-face)))
  "Face for preformatted text."
  :group 'noramark-faces)

(defface noramark-language-keyword-face
  '((t (:inherit font-lock-type-face)))
  "Face for programming language identifiers."
  :group 'noramark-faces)

(defface noramark-link-face
  '((t (:inherit font-lock-keyword-face)))
  "Face for links."
  :group 'noramark-faces)

(defface noramark-keyword-face
  '((t (:inherit font-lock-keyword-face)))
  "Face for keyword."
  :group 'noramark-faces)

(defface noramark-frontmatter-face
  '((t (:inherit font-lock-comment-face)))
  "Face for frontmatter."
  :group 'noramark-faces)

(defconst noramark-regex-command-param
  "\\(\\(\\#[[:alpha:][:digit:]-_]+\\)*\\)\\(\\(\\.[[:alpha:][:digit:]-_]+\\)*\\)\\((.*?)\\)?\\(\\[.*\\]\\)?"
  "Regular expression for #id.class(parameter)[namedparameter]
Group 1 matchs the id.
Group 3 matchs the class
Group 5 matches the parameter.
Group 6 matches the named parameter.")

(defconst noramark-regex-pre-head
  (concat "^[[:space:]]*\\(pre\\|code\\)" noramark-regex-command-param "[[:space:]]*\\({\\)[[:space:]]*?\n")
  "Regular expression for pre or code head block like pre.class(param) {")

(defconst noramark-regex-pre-tail
  "^[[:space:]]*\\(}\\)[[:space:]]*$")


(defconst noramark-regex-pre-c-head
  (concat "^[[:space:]]*\\(pre\\|code\\)" noramark-regex-command-param "[[:space:]]*\\({//\\)\\([A-Za-z-_]*?\\)?[[:space:]]*?\n")
  "Regular expression for pre or code head block like code.class(param) {//language ")

(defconst noramark-regex-pre-c-tail
  "^[[:space:]]*\\(//}\\)[[:space:]]*$")

(defconst noramark-regex-fence-head
  "^\\(```\\)\\([A-Za-z0-9-_]+\\)?\\((.*?)\\)?\\(\\[.*?\\]\\)?[[:space:]]*$")

(defconst noramark-regex-fence-tail
  "^\\(```\\)[[:space:]]*$")

(defconst noramark-regex-header
  "^[ \t]*\\(#+\\).*$"
  "Regexp identifying NoraMark headers.")

(defconst noramark-regex-frontmatter
  "^\\(---\\)[[:space:]]*?$"
  "Regular expression for frontmatter separator.")

(defconst noramark-regex-code
  "\\(\\`\\|[^\\]\\)\\(\\(`+\\)\\(\\(.\\)*?[^`]\\)\\3\\)\\([^`]\\|\\'\\)"
  "Regular expression for matching inline code fragments.")

(defvar noramark-mode-font-lock-keywords-basic
  (list
   ; frontmatter
   (cons 'noramark-match-frontmatter 
         '((1 'font-lock-keyword-face)
          (2 'font-lock-comment-face nil t)
          (3 'font-lock-keyword-face)))
   ; fence
   (cons 'noramark-match-fence
         '((1 'noramark-command-face)
           (2 'font-lock-keyword-face nil t) ; language
           (3 'font-lock-string-face nil t) ; param
           (4 'font-lock-string-face nil t) ; named param
           (5 'noramark-pre-face nil t)
           (6 'noramark-command-face)))
   ; pre/code
   (cons 'noramark-match-pre-command-complex
         '((1 'noramark-command-face nil t) ; cmd
           (2 'font-lock-keyword-face nil t) ; id
           (3 'font-lock-keyword-face nil t) ; class
           (4 'font-lock-string-face nil t) ; param
           (5 'font-lock-string-face nil t) ; named param
           (6 'noramark-command-face nil t) ; open 
           (7 'font-lock-keyword-face nil t) ; language
           (8 'noramark-pre-face nil t) ; body of pre
           (9 'noramark-command-face nil t))) ; close
   ; pre/code
   (cons 'noramark-match-pre-command
         '((1 'noramark-command-face nil t) ; cmd
           (2 'font-lock-keyword-face nil t) ;id 
           (3 'font-lock-keyword-face nil t) ;class
           (4 'font-lock-string-face nil t)  ;param
           (5 'font-lock-string-face nil t)  ;named param
           (6 'noramark-command-face nil t) ; open
           (7 'noramark-pre-face nil t) ; body
           (8 'noramark-command-face nil t))) ;close
   ; inline code
   (cons 'noramark-match-inline-code '((0 noramark-inline-code-face)))
   ; block-end
   '("^[ \t]*}[ \t]*\n" . noramark-command-face)
   ; comment
   '("^[ \t]*//.*$" . font-lock-comment-face)
   ; ul
   '("^[ \t]*[*]+" . noramark-list-face)
   ; ol
   '("^[ \t]*[[:digit:]]+\\.[ \t]" . noramark-list-face)
   ; headings
   (cons noramark-regex-header '((0 noramark-header-face)))
   ; headings: hN
   '("^[ \t]*h[1-6]:.*$" . noramark-header-face)
   ; definition-list short
   (cons 'noramark-match-definition-list-short
         '((1 'noramark-list-face)
           (2 'noramark-list-face)))

   ; definition-list long
   (cons 'noramark-match-definition-list-long
         '((1 'noramark-list-face)
           (2 'noramark-command-face)))
   ; line-command
   (cons 'noramark-match-line-command
         '((1 'noramark-command-face)
           (2 'font-lock-keyword-face nil t)
           (3 'font-lock-keyword-face nil t)
           (4 'font-lock-string-face nil t)
           (5 'font-lock-string-face nil t)
           (6 'noramark-command-face)))
   ; inline-command
   (cons 'noramark-match-inline-command
         '((1 'noramark-command-face)
           (2 'font-lock-keyword-face nil t)
           (3 'font-lock-keyword-face nil t)
           (4 'font-lock-string-face nil t)
           (5 'font-lock-string-face nil t)
           (6 'noramark-command-face nil t)
           (7 'noramark-command-face))))
  "Syntax highlighting for NoraMark files.")


;;; Noramark Font Lock Matching Functions =====================================
(defun noramark-match-frontmatter (last)
  (let (start body end all)
    (cond ((search-forward-regexp noramark-regex-frontmatter last t)
           (forward-line)
           (beginning-of-line)
           (setq start (list (match-beginning 1) (match-end 1)))
           (setq body (list (point)))
           (cond ((search-forward-regexp noramark-regex-frontmatter last t)
                  (forward-line)
                  (setq body (reverse (cons (1- (match-beginning 0)) body))
                        end (list (match-beginning 1) (match-end 1))
                        all (list (car start) (match-end 0)))
                  (set-match-data (append all start body end))
                  t)
                 (t nil)))
          (t nil))))

(defun noramark-match-inline-code (last)
  "Match inline code from the point to LAST."
  (unless (bobp)
    (backward-char 1))
  (cond ((re-search-forward noramark-regex-code last t)
         (set-match-data (list (match-beginning 2) (match-end 2)
                               (match-beginning 4) (match-end 4)))
         (goto-char (match-end 0))
         t)
        (t (forward-char 2) nil)))

(defun noramark-match-line-command (last)
  (let (cmd id class param nparam comma)
    (cond ((search-forward-regexp (concat "^[[:space:]]*\\([A-Za-z0-9-_]+\\)" noramark-regex-command-param "[[:space:]]*\\([:{]\\)") last t)
           (beginning-of-line)

           (setq cmd (list (match-beginning 1) (match-end 1))
                 id (list (match-beginning 2) (match-end 2))
                 class (list (match-beginning 4) (match-end 4))
                 param (list (match-beginning 6) (match-end 6))
                 nparam (list (match-beginning 7) (match-end 7))
                 comma (list (match-beginning 8) (match-end 8))
                 all (list (match-beginning 0) (match-end 0)))
           (forward-line)
           (set-match-data (append all cmd id class param nparam comma))
           t)
          (t nil))))

(defun noramark-match-definition-list-short (last)
  (let (all open delimiter) 
    (cond ((search-forward-regexp "^[ \t]*\\(;:\\)[[:space:]]*?[^:]*?\\(:\\)[[:space:]]" last t)
           (beginning-of-line)
           (setq open (list (match-beginning 1) (match-end 1))
                 delimiter (list (match-beginning 2) (match-end 2))
                 all (list (match-beginning 0) (match-end 0)))
           (forward-line)
           (set-match-data (append all open delimiter))
           t)
          (t nil))))

(defun noramark-match-definition-list-long (last)
  (let (all open delimiter) 
    (cond ((search-forward-regexp "^[ \t]*\\(;:\\)[[:space:]]*?[^{]*?\\({\\)[[:space:]]*?\n" last t)
           (beginning-of-line)
           (setq open (list (match-beginning 1) (match-end 1))
                 delimiter (list (match-beginning 2) (match-end 2))
                 all (list (match-beginning 0) (match-end 0)))
           (forward-line)
           (set-match-data (append all open delimiter))
           t)
          (t nil))))
                 


(defun noramark-match-inline-command (last)
  (let (cmd id class param nparam open close)
    (cond ((search-forward-regexp (concat "\\(\\[[A-Za-z0-9-_]+\\)" noramark-regex-command-param "\\({\\).*?\\(}]\\)") last t)
           (beginning-of-line)
           (setq cmd (list (match-beginning 1) (match-end 1))
                 id (list (match-beginning 2) (match-end 2))
                 class (list (match-beginning 4) (match-end 4))
                 param (list (match-beginning 6) (match-end 6))
                 nparam (list (match-beginning 7) (match-end 7))
                 open (list (match-beginning 8) (match-end 8))
                 close (list (match-beginning 9) (match-end 9))
                 all (list (match-beginning 0) (match-end 0)))
           (goto-char (1+ (match-end 0)))
           (set-match-data (append all cmd id class param nparam open close))
           t)
          (t nil))))

(defun noramark-match-pre-command (last)
  "Match Noramark pre command from point to LAST."
  (let (cmd id class param nparam open cm lang body close all)
    (cond ((search-forward-regexp
            noramark-regex-pre-head last t)
           (beginning-of-line)
           (setq cmd (list (match-beginning 1) (match-end 1))
                 id (list (match-beginning 2) (match-end 2))
                 class (list (match-beginning 4) (match-end 4))
                 param (list (match-beginning 6) (match-end 6))
                 nparam (list (match-beginning 7) (match-end 7))
                 open (list (match-beginning 8) (match-end 8)))
           (setq body (list (point)))
           (cond ((search-forward-regexp noramark-regex-pre-tail last t)
                  (forward-line)
                  (setq body (reverse (cons (1- (match-beginning 0)) body))
                        close (list (match-beginning 0) (match-end 0))
                        all (list (car cmd) (match-end 0)))
                  (set-match-data (append all cmd id class param nparam open body close))
                  t)
                 (t nil)))
          (t nil))))

(defun noramark-match-fence (last)
  "Match Noramark fence command from point to LAST."
  (let (open lang param nparam body close all)
    (cond ((search-forward-regexp noramark-regex-fence-head last t)
           (beginning-of-line)
           (setq open (list (match-beginning 1) (match-end 1))
                 lang (list (match-beginning 2) (match-end 2))
				 param (list (match-beginning 3) (match-end 3))
				 nparam (list (match-beginning 4) (match-end 4)))
           (forward-line)
           (setq body (list (point)))
           (cond ((search-forward-regexp noramark-regex-fence-tail last t)
                  (setq body (reverse (cons (1- (match-beginning 0)) body))
                        close (list (match-beginning 0) (match-end 0))
                        all (list (car open) (match-end 0)))
                  (set-match-data (append all open lang param nparam body close))
                  t)
                 (t nil)))
          (t nil))))


(defun noramark-match-pre-command-complex (last)
  "Match Noramark pre command from point to LAST."
  (let (cmd id class param nparam open lang body close all)
    (cond ((search-forward-regexp
            noramark-regex-pre-c-head last t)
           (beginning-of-line)
           (setq cmd (list (match-beginning 1) (match-end 1))
                 id (list (match-beginning 2) (match-end 2))
                 class (list (match-beginning 4) (match-end 4))
                 param (list (match-beginning 6) (match-end 6))
                 nparam (list (match-beginning 7) (match-end 7))
                 open (list (match-beginning 8) (match-end 8))
                 lang (list (match-beginning 9) (match-end 9)))
           (setq body (list (point)))
           (cond ((search-forward-regexp noramark-regex-pre-c-tail last t)
                  (forward-line)
                  (setq body (reverse (cons (1- (match-beginning 0)) body))
                        close (list (match-beginning 0) (match-end 0))
                        all (list (car cmd) (match-end 0)))
                  (set-match-data (append all cmd id class param nparam open lang body close))
                  t)
                 (t nil)))
          (t nil))))


;;; Outline
(defun noramark-outline-level ()
  "Return the depth to which a statement is nested in the outline."
  (let ((mz (match-string 0)) (mo (match-string 1)))
    (message "zero : %s one : %s" mz mo)
    (- (match-end 1) (match-beginning 1))))

(defun noramark-reload-extensions ()
  "Check settings, update font-lock keywords, and re-fontify buffer."
  (interactive)
  (when (eq major-mode 'noramark-mode)
    (setq noramark-mode-font-lock-keywords
          noramark-mode-font-lock-keywords-basic)
    (setq font-lock-defaults '(noramark-mode-font-lock-keywords))
    (font-lock-refresh-defaults)))

(defun noramark-font-lock-extend-region-pre ()
  (eval-when-compile (defvar font-lock-beg) (defvar font-lock-end))
  (save-excursion
    (goto-char font-lock-beg)
    (when (re-search-backward noramark-regex-pre-head nil t)
      (let ((found (match-beginning 0)))
        (goto-char font-lock-beg)
        (when (re-search-forward noramark-regex-pre-tail nil t)
               (setq font-lock-end (max (match-end 0) font-lock-end))
               (setq font-lock-beg found))))))

(defun noramark-font-lock-extend-region-pre-c ()
  (eval-when-compile (defvar font-lock-beg) (defvar font-lock-end))
  (save-excursion
    (goto-char font-lock-beg)
    (when (re-search-backward noramark-regex-pre-c-head nil t)
      (let ((found (match-beginning 0)))
        (goto-char font-lock-beg)
        (when (re-search-forward noramark-regex-pre-c-tail nil t)
          (setq font-lock-end (max (match-end 0) font-lock-end))
          (setq font-lock-beg found))))))

(defun noramark-font-lock-extend-region-frontmatter ()
  (eval-when-compile (defvar font-lock-beg) (defvar font-lock-end))
  (save-excursion
    (goto-char font-lock-beg)
    (cond ((re-search-backward "^---[[:space:]]*?$" nil t)
           (let ((found (point)))
             (goto-char font-lock-beg)
             (beginning-of-line)
             (cond ((re-search-forward "^---[[:space:]]*?$" nil t)
                    (setq font-lock-end (max (match-end 0) font-lock-end))
                    (setq font-lock-beg found)
                    t)
                   (t nil))))
          (t nil))))

(defun noramark-font-lock-extend-region-fence ()
  (eval-when-compile (defvar font-lock-beg) (defvar font-lock-end))
  (save-excursion
    (goto-char font-lock-beg)
    (beginning-of-line)
    (cond ((re-search-backward noramark-regex-fence-head nil t)
           (let ((found (point)))
             (goto-char font-lock-beg)
             (beginning-of-line)
             (cond ((re-search-forward noramark-regex-fence-tail nil t)
                    (setq font-lock-end (max (match-end 0) font-lock-end))
                    (setq font-lock-beg (min found font-lock-beg))
                    t)
                   (t nil))))
          (t nil))))
      
;;; Keymap

(defvar noramark-mode-map
  (let ((map (make-keymap)))
    ;; header navigation
    (define-key map (kbd "C-c C-n") 'outline-next-visible-heading)
    (define-key map (kbd "C-c C-p") 'outline-previous-visible-heading)
    (define-key map (kbd "C-c C-f") 'outline-forward-same-level)
    (define-key map (kbd "C-c C-b") 'outline-backward-same-level)
    (define-key map (kbd "C-c C-u") 'outline-up-heading)
    map)
  "Keymap for NoraMark major mode.")

;;; Syntax Table ==============================================================

(defvar noramark-mode-syntax-table
  (make-syntax-table text-mode-syntax-table)
  "Syntax table for `noramark-mode'.")

;;; Mode Definition  ==========================================================

;;;###autoload
(define-derived-mode noramark-mode text-mode "NoraMark"
  "Major mode for editing NoraMark files."
  ;; Font lock.
  (set (make-local-variable 'noramark-mode-font-lock-keywords) nil)
  (set (make-local-variable 'font-lock-multiline) t)
  (noramark-reload-extensions)
  ;; Outline mode
  (make-local-variable 'outline-regexp)
  (setq outline-regexp noramark-regex-header)
  (make-local-variable 'outline-level)
  (setq outline-level 'noramark-outline-level)
  ;; hooks
  (add-hook 'font-lock-extend-region-functions
            'noramark-font-lock-extend-region-pre)
  (add-hook 'font-lock-extend-region-functions
            'noramark-font-lock-extend-region-pre-c)
  (add-hook 'font-lock-extend-region-functions
            'noramark-font-lock-extend-region-frontmatter)
  (add-hook 'font-lock-extend-region-functions
            'noramark-font-lock-extend-region-fence))


;;;###autoload(add-to-list 'auto-mode-alist '("\\.nora\\'" . noramark-mode))


(provide 'noramark-mode)

;;; noramark-mode.el ends here

