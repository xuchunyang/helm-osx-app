;;; helm-osx-app.el --- Launch macOS apps with helm  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Xu Chunyang

;; Author: Xu Chunyang
;; Homepage: https://github.com/xuchunyang/helm-osx-app
;; Package-Requires: ((emacs "25.1") (helm-core "3.0"))
;; Created: 2019/7/7 深夜
;; Version: 1.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Yet another macOS apps launcher.

;;; Code:

(require 'helm)
(require 'seq)

(defgroup helm-osx-app nil
  "Launch macOS apps with Helm."
  :group 'helm)

(defcustom helm-osx-app-app-folders '("/Applications" "~/Applications")
  "Folders containing applications."
  :group 'helm-osx-app
  :type '(repeat directory))

(defcustom helm-osx-app-pref-folders '("/System/Library/PreferencePanes"
                                       "/Library/PreferencePanes"
                                       "~/Library/PreferencePanes")
  "Folders containing system preferences."
  :group 'helm-osx-app
  :type '(repeat directory))

(defcustom helm-osx-app-actions
  (helm-make-actions
   "Open"
   (lambda (_)
     (apply #'call-process "open" nil nil nil
            (helm-marked-candidates)))
   "Reveal file in Finder"
   (lambda (_)
     (apply #'call-process "open" nil nil nil
            "-R" (helm-marked-candidates))))
  "Actions for `helm-osx-app'."
  :group 'helm-osx-app
  :type '(alist :key-type string :value-type function))

(defun helm-osx-app-get-apps (folder)
  "Return *.app in FOLDER recursively."
  (seq-mapcat
   (lambda (file)
     (cond
      ((string-match (rx "/" (or "." "..") eos) file)
       nil)
      ((string-match (rx ".app" eos) file)
       (list file))
      ((file-directory-p file)
       (helm-osx-app-get-apps file))
      (t nil)))
   (directory-files folder 'full)))

(defun helm-osx-app-get-prefs (folder)
  "Return .prefPane in FOLDER."
  (directory-files folder 'full (rx ".prefPane" eos)))

(defun helm-osx-app-candidates ()
  "Build helm candidates for `helm-osx-app'."
  (nconc
   (seq-mapcat
    #'helm-osx-app-get-apps
    (seq-filter #'file-exists-p helm-osx-app-app-folders))
   (seq-mapcat
    #'helm-osx-app-get-prefs
    (seq-filter #'file-exists-p helm-osx-app-pref-folders))))

;;;###autoload
(defun helm-osx-app ()
  "Launch macOS applications (and Preferences) with Helm."
  (interactive)
  (helm
   :sources
   (helm-build-sync-source "macOS apps"
     :candidates #'helm-osx-app-candidates
     :filtered-candidate-transformer
     (and (bound-and-true-p helm-adaptive-mode)
          '(helm-adaptive-sort))
     :action helm-osx-app-actions)
   :buffer "*helm osx app*"))

(provide 'helm-osx-app)
;;; helm-osx-app.el ends here
