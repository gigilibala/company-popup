;;; company-popup.el --- Simple company mode frontend using popups

;; Copyright (C) 2018, Amin Hassani

;; Author: Amin Hassani <gigilibala@gigilibala.com>
;; URL: https://github.com/gigilibala/company-popup
;; Keywords: company popup tip
;; Version: 1.0.0

;; This package is not part of the GNU emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Comentary:
;; Nothing for now

;;; Code:
(require 'company)
(require 'popup)

(defgroup company-popup nil
  "A frontend for `company-mode' using `popup'"
  :group 'company)

(defcustom company-popup-tip-delay 0.5
  "A deflay between showing the list of choices as a menu and the popup tip.")

(defvar-local company-popup--menu nil
  "Popup menu for tist of available choices.")

(defvar-local company-popup--tip nil
  "Popup tip for the documentation of the selected menu")

(defvar-local company-popup--prefix nil
  "The common prefix between all the avaialble company choices.")

(defvar-local company-popup--tip-timer nil
  "A timer for showing the popup tip after the menu appears.")

(defun company-popup--extract-docstring ()
  "Extracts the document string from the currently selected
candidate in the the menu."
  (let* ((selected (nth company-selection company-candidates))
	 (tip (company-call-backend 'doc-buffer selected)))
    (when tip
      (let ((tip-buffer (if (consp tip) (car tip) tip))
	    (tip-begin (if (consp tip) (cdr tip) (point-min))))
	(with-current-buffer tip-buffer
	  (buffer-substring tip-begin (point-max)))))))

(defun company-popup--show-tip ()
  "Shows the current documentation in a popup tip."
  (let* ((tip (company-popup--extract-docstring)))
    (when tip
      (setq company-popup--tip
	    (popup-tip tip
		       :nowait t
		       :parent company-popup--menu
		       :parent-offset 0))
      (popup-draw company-popup--tip))))

(defun company-popup--start-tip-timer ()
  "Starts the timer for showing the popup tip."
  (when (not company-popup--tip-timer)
    (setq company-popup--tip-timer
	  (run-with-idle-timer company-popup-tip-delay
			       nil
			       'company-popup--show-tip))))

(defun company-popup--stop-tip-timer ()
  "Stops the timer for showing the popup tip."
  (when company-popup--tip-timer
    (cancel-timer company-popup--tip-timer)
    (setq company-popup--tip-timer nil)))

(defun company-popup--frontend-update ()
  "Is called when the `company-mode' calls the `update'
command. It renders the menu of candidates and starts a timer for
showing the popup tip."
  (let* ((menu-point (- company-point (length company-prefix)))
	 (same-prefix (equal company-popup--prefix company-prefix))
	 (change-popup (or (not company-popup--menu)
			   (not same-prefix))))
    (setq company-popup--prefix company-prefix)
    (company-popup--stop-tip-timer)
    (popup-delete company-popup--tip)
    (if change-popup
	(progn (popup-delete company-popup--menu)
	       (setq company-popup--menu
		     (popup-menu* company-candidates
				  :point menu-point
				  :initial-index company-selection
				  :height company-tooltip-limit
				  :nowait t))
	       (popup-draw company-popup--menu))
      (let* ((selection-changed-size
	      (- company-selection (popup-cursor company-popup--menu))))
	(if (< 0 selection-changed-size)
	    (dotimes (counter selection-changed-size)
	      (popup-next company-popup--menu))
	  (dotimes (counter (abs selection-changed-size))
	    (popup-previous company-popup--menu)))))
    (company-popup--start-tip-timer)))

(defun company-popup--frontend-hide ()
  "Is called when the `company-mode' sends the `hide' command."
  (setq company-popup--prefix nil)
  (company-popup--stop-tip-timer)
  (popup-delete company-popup--menu)
  (popup-delete company-popup--tip)
  (setq company-popup--menu nil)
  (setq company-popup--tip nil))

(defun company-popup-frontend (command)
  "`company-mode' front-end using `popup' popup."
  (pcase command
    (`update (company-popup--frontend-update))
    (`hide (company-popup--frontend-hide))))

(defun company-popup--enable ()
  "Enables the company-popup."
  (make-local-variable 'company-frontends)
  (setq company-frontends nil)
  (add-to-list 'company-frontends 'company-popup-frontend))

(defun company-popup--disable ()
  "Disables the company-popup."
  (make-local-variable 'company-frontends)
  (setq-local company-frontends
	      (delq 'company-popup-frontend company-frontends)))

;;;###autoload
(define-minor-mode company-popup-mode
  "A simple frontend for `company-mode' using `popup'."
  :global nil
  (if company-popup-mode
      (company-popup--enable)
    (company-popup--disable)))

;;;###autoload
(add-hook 'company-mode-hook 'company-popup-mode)

(provide 'company-popup)
;;; company-popup ends here
