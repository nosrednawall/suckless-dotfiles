;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:

(setq doom-theme 'doom-gruvbox)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Configura o local do R
;; Configura o caminho do R
(after! ess
  (setq inferior-ess-r-program "/usr/local/bin/R"))

;; Adiciona navegação entre os buffers, com as teclas Alt+Seytas
(when (fboundp 'windmove-default-keybindings)
  (windmove-default-keybindings))

(require 'multiple-cursors)
(global-set-key (kbd "C->") 'mc/mark-next-like-this)
(global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
(global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this)

(eval-after-load "term"
  '(define-key term-raw-map (kbd "C-c y") 'term-paste))



;; Função para renderizar o markdown no emacs
(after! ess
  ;; Função principal para renderizar Rmd
  (defun my/rmd-render-and-view-with-R ()
    "Renderiza usando o processo R inferior se disponível."
    (interactive)
    (let* ((rmd-file (buffer-file-name))
           (html-file (concat (file-name-sans-extension rmd-file) ".html"))
           (ess-process (get-process "R")))
      (if (and rmd-file (string-match-p "\\.Rmd$" rmd-file))
          (progn
            (save-buffer)
            (if ess-process
                (progn
                  (message "▶ Usando R inferior para renderizar...")
                  (comint-send-string ess-process
                                     (format "rmarkdown::render(\"%s\")\n" rmd-file))
                  (message "⏳ Renderizando... Use C-c C-o para abrir o HTML quando terminar"))
              ;; Fallback para Rscript
              (progn
                (message "▶ Sem R inferior. Usando Rscript...")
                (shell-command (format "Rscript -e \"rmarkdown::render('%s')\"" rmd-file))
                (browse-url html-file)
                (message "✅ Concluído!"))))
        (message "❌ Não é um arquivo .Rmd")))

  ;; Função para abrir HTML
  (defun my/open-rmd-html ()
    "Abre o HTML correspondente ao RMarkdown atual."
    (interactive)
    (let* ((rmd-file (buffer-file-name))
           (html-file (concat (file-name-sans-extension rmd-file) ".html")))
      (if (file-exists-p html-file)
          (browse-url html-file)
        (message "❌ HTML não encontrado. Renderize primeiro com C-c C-r"))))

  ;; Define os keybindings apenas se o mapa existir
  (when (boundp 'ess-r-mode-map)
    (define-key ess-r-mode-map (kbd "C-c C-r") 'my/rmd-render-and-view-with-R)
    (define-key ess-r-mode-map (kbd "C-c C-o") 'my/open-rmd-html)))
)
