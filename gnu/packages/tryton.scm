;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017 Adriano Peluso <catonano@gmail.com>
;;; Copyright © 2020 Vinicius Monego <monego@posteo.net>
;;; Copyright © 2021 Maxime Devos <maximedevos@telenet.be>
;;; Copyright © 2021 Hartmut Goebel <h.goebel@crazy-compilers.com>
;;; Copyright © 2021 Maxim Cournoyer <maxim.cournoyer@gmail.com>
;;; Copyright © 2025 Ricardo Wurmus <rekado@elephly.net>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages tryton)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages check)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages finance)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages graphviz)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages pdf)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-crypto)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages time)
  #:use-module (gnu packages xml)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (guix build-system python)
  #:use-module (guix build-system pyproject))

(define (guix-trytonpath-search-path version)
  "Generate a GUIX_TRYTOND_MODULES_PATH search path specification, using
VERSION.

Do not use PYTHHONPATH not avoid interfering with any different Python package
installed in the same environments.  Collecting only paths actually containing
/tryton/modules reduces the number of paths."
  (search-path-specification (variable "GUIX_TRYTOND_MODULES_PATH")
                             (files (list (string-append
                                           "lib/python"
                                           (version-major+minor version)
                                           "/site-packages/trytond/modules")))))

(define-public trytond
  (package
    (name "trytond")
    (version "7.4.4")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond" version))
       (sha256
        (base32 "1bwa631qz07k6s5fbki3ph6sx0ch9yss2q4sa1jb67z6angiwv5f"))
       (patches (search-patches "trytond-add-guix_trytond_path.patch"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:test-flags
      '(list "-k"
             (string-append
              ;; "modules" is [None], but should be a list of modules.
              "not ModuleTestCase"
                            ;; fixture 'self' not found
                            " and not test_method"))
      #:phases
      '(modify-phases %standard-phases
         (add-before 'check 'preparations
           (lambda _
             (setenv "DB_NAME" ":memory:")
             (setenv "HOME" "/tmp"))))))
    (propagated-inputs
     (list python-dateutil
           python-defusedxml
           python-genshi
           python-lxml
           python-passlib
           python-polib
           python-relatorio
           python-sql
           python-werkzeug))
    (native-inputs
     (list python-pillow
           python-pydot
           python-pytest
           python-setuptools
           python-wheel
           tzdata-for-tests))
    (native-search-paths
     (list (guix-trytonpath-search-path (package-version python))))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton Server")
    (description "Tryton is a three-tier high-level general purpose
application platform using PostgreSQL as its main database engine.  It is the
core base of a complete business solution providing modularity, scalability
and security.")
    (license license:gpl3+)))

(define-public tryton
  (package
    (name "tryton")
    (version "7.4.4")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "tryton" version))
       (sha256
        (base32 "0q0qa4pjbpc0h8r9hlnm5dh315w5i7mzqpdrlw1c8qvigpl1rf7g"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'check 'change-home
            (lambda _
              ;; Change from /homeless-shelter to /tmp for write permission.
              (setenv "HOME" "/tmp")))
          (add-after 'install 'wrap-gi-python
            (lambda _
              (let ((gi-typelib-path   (getenv "GI_TYPELIB_PATH")))
                (wrap-program (string-append #$output "/bin/tryton")
                  `("GI_TYPELIB_PATH" ":" prefix (,gi-typelib-path)))))))))
    (native-inputs
     (list `(,glib "bin")
           gobject-introspection
           python-pytest
           python-setuptools
           python-wheel))
    (inputs (list bash-minimal))        ;for wrap-program
    (propagated-inputs
     (list (librsvg-for-system)
           gsettings-desktop-schemas
           gtk+
           python-dateutil
           python-pycairo
           python-pygobject))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton Client")
    (description
     "This package provides the Tryton GTK client.")
    (license license:gpl3+)))

(define-public python-proteus
  (package
    (name "python-proteus")
    (version "7.4.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "proteus" version))
       (sha256
        (base32 "1q3d0hkvmfsmxbx2qqp8zpslyy11mzwh0q2dkrh958yfyrzi1550"))))
    (build-system pyproject-build-system)
    ;; Tests require python-trytond-party which requires python-proteus.
    (arguments
     `(#:tests? #f))
    (propagated-inputs
     (list python-dateutil python-defusedxml))
    (native-inputs (list python-setuptools python-wheel))
    (home-page "http://www.tryton.org/")
    (synopsis "Library to access a Tryton server as a client")
    (description
     "This package provides a library to access Tryton server as a client.")
    (license license:lgpl3+)))

(define (tryton-phases module . extra-arguments)
  "Return the phases for building and testing a Tryton module named MODULE.
If present, pass EXTRA-ARGUMENTS to runtest as well."
  `(modify-phases %standard-phases
     (replace 'check
       (lambda* (#:key inputs outputs tests? #:allow-other-keys)
         (let ((runtest
                (string-append
                 (assoc-ref inputs "trytond")
                 "/lib/python"
                 ,(version-major+minor (package-version python))
                 "/site-packages/trytond/tests/run-tests.py")))
           (when tests?
             (add-installed-pythonpath inputs outputs)
             (invoke "python" runtest "-m" ,module ,@extra-arguments)))))))

(define (tryton-arguments module . extra-arguments)
  "Like ’tryton-phases’, but directly return all arguments for
the build system."
  `(#:phases ,(apply tryton-phases module extra-arguments)))

;;;
;;;  Tryton modules - please sort alphabetically
;;;

(define (%standard-trytond-native-inputs)
  ;; native-inputs required by most of the tryton module for running the test
  `(("python-dateutil" ,python-dateutil)
    ("python-genshi" ,python-genshi)
    ("python-lxml" ,python-lxml)
    ("python-magic" ,python-magic)
    ("python-passlib" ,python-passlib)
    ("python-polib" ,python-polib)
    ("python-proteus" ,python-proteus)
    ("python-relatorio" ,python-relatorio)
    ("python-sql" ,python-sql)
    ("python-werkzeug" ,python-werkzeug-1.0)
    ("python-wrapt" ,python-wrapt)))

(define-public trytond-account
  (package
    (name "trytond-account")
    (version "6.2.7")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account" version))
       (sha256
        (base32 "1jjffyfkax36v6znhdyvlrr314h3d5rn13iwv3kvhsm6paddbmwi"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-simpleeval trytond trytond-company trytond-currency
           trytond-party))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for accounting")
    (description
     "This package provides a Tryton module that defines the fundamentals for
most of accounting needs.")
    (license license:gpl3+)))

(define-public python-trytond-account
  (deprecated-package "python-trytond-account" trytond-account))

(define-public trytond-account-asset
  (package
    (name "trytond-account-asset")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_asset" version))
       (sha256
        (base32 "0zs0bqa3crfqc39z7c5hcj60w2aws2fv2l9y59v9sfy8azi32533"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_asset"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-purchase" ,trytond-purchase)))
    (propagated-inputs
     (list trytond trytond-account trytond-account-invoice
           trytond-account-product trytond-product))
    (home-page "https://docs.tryton.org/projects/modules-account-asset")
    (synopsis "Tryton module for assets management")
    (description "The @emph{Account Asset} Tryton module adds the depreciation
of fixed assets.")
    (license license:gpl3+)))

(define-public trytond-account-be
  (package
    (name "trytond-account-be")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_be" version))
       (sha256
        (base32 "0ff27b9g1nf1gqlbv71kq7nm25r85vqpn8b0piajcxln1pbwgnmw"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_be"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account trytond-account-eu))
    (home-page "https://docs.tryton.org/projects/modules-account-be")
    (synopsis "Tryton module with Belgian chart of accounts")
    (description "The @emph{Account BE} Tryton module defines the standard
chart of account for Belgium.")
    (license license:gpl3+)))

(define-public trytond-account-budget
  (package
    (name "trytond-account-budget")
    (version "6.2.2")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "trytond_account_budget" version))
              (sha256
               (base32 "055y9jjpx4xfrc6dlssvjzmjz7rrvfljlaljx0v6c6s87mpzi3m5"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "trytond_account_budget"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs (list trytond trytond-account
                             trytond-company trytond-currency))
    (home-page "https://docs.tryton.org/projects/modules-account-budget")
    (synopsis "Tryton module that allows budgets to be setup for accounts")
    (description "The @emph{Account Budget} Tryton module provides the ability
to set budgets for accounts over a defined period of time.  These budgets can
then be used to track the total amount from relevant transactions against the
budgeted amount.")
    (license license:gpl3+)))

(define-public trytond-account-cash-rounding
  (package
    (name "trytond-account-cash-rounding")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_cash_rounding" version))
       (sha256
        (base32 "0lxwz3f1p8szphvl64w8fhjnnvn30fin5k1rh47ikvcmlpq8xb67"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_cash_rounding"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-account-invoice" ,trytond-account-invoice)
       ("trytond-purchase" ,trytond-purchase)
       ("trytond-sale" ,trytond-sale)))
    (propagated-inputs
     (list trytond trytond-account trytond-currency))
    (home-page
     "https://docs.tryton.org/projects/modules-account-cash-rounding")
    (synopsis "Tryton module to round cash amount")
    (description "The @emph{Account Cash Rounding} Tryton module allows cash
amounts to be rounded using the cash rounding factor of the currency.")
    (license license:gpl3+)))

(define-public trytond-account-credit-limit
  (package
    (name "trytond-account-credit-limit")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_credit_limit" version))
       (sha256
        (base32 "1j3krz4qm04366d1k4sdf089vwbjl29lw8wbpd002hr2lb2lppm3"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_credit_limit"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-account-dunning" ,trytond-account-dunning)))
    (propagated-inputs
     (list trytond trytond-account trytond-company trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-account-credit-limit")
    (synopsis "Tryton module for account credit limit")
    (description "The @emph{Account Credit Limit} Tryton module for manages
credit limit of parties.")
    (license license:gpl3+)))

(define-public trytond-account-de-skr03
  (package
    (name "trytond-account-de-skr03")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_de_skr03" version))
       (sha256
        (base32 "1igag4nbafr5il6fqw7piak0wma6mgxhzy59zpsnl8gcl96jijv1"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_de_skr03"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account))
    (home-page "https://docs.tryton.org/projects/modules-account-de-skr03")
    (synopsis "Tryton module with German chart of accounts SKR03")
    (description "This package provides the German SKR03 chart of accounts for
Tryton.")
    (license license:gpl3+)))

(define-public trytond-account-deposit
  (package
    (name "trytond-account-deposit")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_deposit" version))
       (sha256
        (base32 "0axp72p00fk1r6mr9pip8g4276wvb55vfbp962f3gdsijslj9mqi"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_deposit"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account trytond-account-invoice
           trytond-company trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-account-deposit")
    (synopsis "Tryton module for accounting deposit")
    (description "The @emph{Account Deposit} Tryton module adds support for
deposit accounting.

A deposit is an amount paid by the customer prior to the company providing it
with services or goods.  A wizard on invoice allows recalling a prior deposit of
the party.")
    (license license:gpl3+)))

(define-public trytond-account-dunning
  (package
    (name "trytond-account-dunning")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_dunning" version))
       (sha256
        (base32 "0kzafh99055ghg5d8vs411y5c8v1xjqqf23n1sa9a4dzj10wlq97"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_dunning"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account trytond-company trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-account-dunning")
    (synopsis "Tryton module for account dunning")
    (description "The @emph{Account Dunning} Tryton module adds dunning for
receivable move lines.")
    (license license:gpl3+)))

(define-public trytond-account-dunning-email
  (package
    (name "trytond-account-dunning-email")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_dunning_email" version))
       (sha256
        (base32 "01d0cwgvl40i7zq9s3yrmf504j8s6395vs8mm1hgg0s9dpi7pl46"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_dunning_email"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account-dunning trytond-account-dunning-letter
           trytond-party))
    (home-page
     "https://docs.tryton.org/projects/modules-account-dunning-email")
    (synopsis "Tryton module for account dunning email")
    (description "This package provides a Tryton module for sending dunning
emails.")
    (license license:gpl3+)))

(define-public trytond-account-dunning-fee
  (package
    (name "trytond-account-dunning-fee")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_dunning_fee" version))
       (sha256
        (base32 "0v88xkigxqr1py2l25z3qfrr1irpllsi7zzwg3sxmp12d8pi8szk"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_dunning_fee"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-account-dunning-letter" ,trytond-account-dunning-letter)))
    (propagated-inputs
     (list trytond trytond-account-dunning trytond-account-product))
    (home-page "https://docs.tryton.org/projects/modules-account-dunning-fee")
    (synopsis "Tryton module for account dunning fee")
    (description "This package provides a Tryton module for generating
accounting moves as fees when processing dunning.")
    (license license:gpl3+)))

(define-public trytond-account-dunning-letter
  (package
    (name "trytond-account-dunning-letter")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_dunning_letter" version))
       (sha256
        (base32 "1jx1ad7kwlk7cm5j2b15bf4lcy5d2c13j8ag48v0pfy3kiglr2z3"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_dunning_letter"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account trytond-account-dunning
           trytond-company trytond-party))
    (home-page
     "https://docs.tryton.org/projects/modules-account-dunning-letter")
    (synopsis "Tryton module for account dunning letter")
    (description "This package provides a Tryton module for generating dunning
letters.")
    (license license:gpl3+)))

(define-public trytond-account-es
  (package
    (name "trytond-account-es")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_es" version))
       (sha256
        (base32 "0wwfkqxlppaild62labldabcnzgdmiqd36sknqdb69jn4ljhw4im"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_es"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-account-asset" ,trytond-account-asset)
       ("trytond-account-payment-sepa" ,trytond-account-payment-sepa)
       ("trytond-sale-advance-payment" ,trytond-sale-advance-payment)))
    (propagated-inputs
     (list trytond trytond-account trytond-account-eu trytond-account-invoice
           trytond-company trytond-currency trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-account-es")
    (synopsis "Tryton with Spanish chart of accounts")
    (description "This package provides the following Spanish charts of
accounts for Tryton:
@itemize
@item Plan General Contable Español 2008
@item Plan Contable para PYMES 2008
@end itemize

A wizard allows generating the following AEAT files:

@itemize
@item Modelo 111
@item Modelo 115
@item Modelo 303
@end itemize")
    (license license:gpl3+)))

(define-public trytond-account-eu
  (package
    (name "trytond-account-eu")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_eu" version))
       (sha256
        (base32 "1k11ncamp4cd5bdpj4va9p0vga2vcgfwd7wbivf1w4m1bzpisvm8"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_eu"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-account
           trytond-account-invoice
           trytond-company
           trytond-currency
           trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-account-eu")
    (synopsis "Tryton module for european accounting")
    (description "This package provides a Tryton module implementing common
accounting requirements in Europe.  It includes:

@itemize
@item EC Sales List (ESL)
@end itemize")
    (license license:gpl3+)))

(define-public trytond-account-fr
  (package
    (name "trytond-account-fr")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_fr" version))
       (sha256
        (base32 "18wmijaxah125skhgpqc7iaw6a8md5mpv7m5yazcrscx9pk1z5jz"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_fr"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account trytond-party-siret))
    (home-page "https://docs.tryton.org/projects/modules-account-fr")
    (synopsis "Tryton module with French chart of accounts")
    (description "This package provides the French standard chart of account
for Tryton.")
    (license license:gpl3+)))

(define-public trytond-account-fr-chorus
  (package
    (name "trytond-account-fr-chorus")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_fr_chorus" version))
       (sha256
        (base32 "14rcfk825m7wi73a4ahps5wqrz2aws3a7spz402mmbfxz84ypvbg"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_fr_chorus"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-edocument-uncefact" ,trytond-edocument-uncefact)))
    (propagated-inputs
     (list python-requests
           trytond
           trytond-account
           trytond-account-invoice
           trytond-company
           trytond-party
           trytond-party-siret))
    (home-page "https://docs.tryton.org/projects/modules-account-fr-chorus")
    (synopsis "Tryton module to communicate with the French Chorus Pro
portal")
    (description "This package provides a Tryton module to send invoices
through the French Chorus Pro portal.

If the party is checked for Chorus Pro, all posted customer invoices are
queued to be sent.  A cron job will send them every 15 minutes by default,
using the credential from the accounting configuration.")
    (license license:gpl3+)))

(define-public trytond-account-invoice
  (package
    (name "trytond-account-invoice")
    (version "6.2.4")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_invoice" version))
       (sha256
        (base32 "12hkrlni1psa5n72bvz94zqwfmzpy24814p0f2vk1cmzkbsfb6vi"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_invoice"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-account
           trytond-account-product
           trytond-company
           trytond-currency
           trytond-party
           trytond-product))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for invoicing")
    (description
     "This package provides a Tryton module that adds the invoice, payment
term.")
    (license license:gpl3+)))

(define-public python-trytond-account-invoice
  (deprecated-package "python-trytond-account-invoice" trytond-account-invoice))

(define-public trytond-account-invoice-correction
  (package
    (name "trytond-account-invoice-correction")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_invoice_correction" version))
       (sha256
        (base32 "1m95h7bnwzjbhrnbld5bka4hqygm0d8jcg1g2nmdyqakcniljv34"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_invoice_correction"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account-invoice))
    (home-page
     "https://docs.tryton.org/projects/modules-account-invoice-correction")
    (synopsis "Tryton module to correct invoice")
    (description "The @emph{Account Invoice Correction} Tryton module adds a
wizard on invoice which allows select lines for which the unit price must be
corrected.  A new invoice is created with those lines in double: once with the
original quantity, once with the inverted quantity.")
    (license license:gpl3+)))

(define-public trytond-account-invoice-defer
  (package
    (name "trytond-account-invoice-defer")
    (version "6.2.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_invoice_defer" version))
       (sha256
        (base32 "1jjsadia1bxx0h80aqhm0alzxdqbkg3by0i7i6qfk7wwikim6lkm"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_invoice_defer"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account trytond-account-invoice
           trytond-company))
    (home-page
     "https://docs.tryton.org/projects/modules-account-invoice-defer")
    (synopsis "Tryton module to defer expense and revenue")
    (description "The @emph{Account Invoice Defer} Tryton module allows
deferring the expense or the revenue of an invoice line over many periods.")
    (license license:gpl3+)))

(define-public trytond-account-invoice-history
  (package
    (name "trytond-account-invoice-history")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_invoice_history" version))
       (sha256
        (base32 "1qg8x6kggi2f390y35m7k3mfi358zr4jwiw76vw5kkrpa3gm4lyj"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_invoice_history"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account-invoice trytond-party))
    (home-page
     "https://docs.tryton.org/projects/modules-account-invoice-history")
    (synopsis "Tryton module to historize invoices")
    (description "The @emph{Account Invoice History} Tryton module activates
the historization of the invoice and its related fields.")
    (license license:gpl3+)))

(define-public trytond-account-invoice-line-standalone
  (package
    (name "trytond-account-invoice-line-standalone")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_invoice_line_standalone" version))
       (sha256
        (base32 "15ld3iixh8kgil5zw3q4acci4xvdcd56lyin154qaak12f7rms0z"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_invoice_line_standalone"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account-invoice))
    (home-page
     "https://docs.tryton.org/projects/modules-account-invoice-line-standalone")
    (synopsis "Tryton module to have standalone invoice lines")
    (description "The @emph{Account Invoice Line Standalone} Tryton module
allows creating an invoice line not linked to an invoice.")
    (license license:gpl3+)))

(define-public trytond-account-invoice-secondary-unit
  (package
    (name "trytond-account-invoice-secondary-unit")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_invoice_secondary_unit" version))
       (sha256
        (base32 "1wmc8zx51saqxbg26b7jnhl7ss3gjrhzxn7zqqsis9dps6l07jwf"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_invoice_secondary_unit"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account-invoice trytond-product))
    (home-page
     "https://docs.tryton.org/projects/modules-account-invoice-secondary-unit")
    (synopsis "Tryton module to add a secondary unit on invoice line")
    (description "The @emph{Account Invoice Secondary Unit} Tryton module adds
a secondary unit of measure on invoice line.")
    (license license:gpl3+)))

(define-public trytond-account-invoice-stock
  (package
    (name "trytond-account-invoice-stock")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_invoice_stock" version))
       (sha256
        (base32 "0q12v6xdpsw4fjm9pqp73bffdixi2hm9j2vxxx6n2p9r0c3g1gj1"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_invoice_stock"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account-invoice trytond-product trytond-stock))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module to link stock and invoice")
    (description
     "This package provides a Tryton module that adds link between invoice
lines and stock moves.  The unit price of the stock move is updated with the
average price of the posted invoice lines that are linked to it.")
    (license license:gpl3+)))

(define-public python-trytond-account-invoice-stock
  (deprecated-package
   "python-trytond-account-invoice-stock" trytond-account-invoice-stock))

(define-public trytond-account-move-line-grouping
  (package
    (name "trytond-account-move-line-grouping")
    (version "6.2.0")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "trytond_account_move_line_grouping" version))
              (sha256
               (base32 "1mrh17a55hkfj89vyx1jrmgzps4ig0m03c10ngsy4my6v6rnnn2r"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "trytond_account_move_line_grouping"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs (list python-sql trytond trytond-account))
    (home-page "https://docs.tryton.org/projects/modules-account-move-line-grouping")
    (synopsis "Tryton module to display account move lines grouped")
    (description "The @emph{Account Move Line Grouping} Tryton module adds a
view that displays move lines grouped.")
    (license license:gpl3+)))

(define-public trytond-account-payment
  (package
    (name "trytond-account-payment")
    (version "6.2.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_payment" version))
       (sha256
        (base32 "0gsg53fiqdmrdpckpfh5sm56ycqjdpa26calmng4p0v2rz557l1f"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_payment"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-account-invoice" ,trytond-account-invoice)))
    (propagated-inputs
     (list trytond trytond-account trytond-company trytond-currency
           trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-account-payment")
    (synopsis "Tryton module for payment")
    (description "This package provides a Tryton module for generating grouped
payments for receivable or payable Account Move Lines.")
    (license license:gpl3+)))

(define-public trytond-account-payment-braintree
  (package
    (name "trytond-account-payment-braintree")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_payment_braintree" version))
       (sha256
        (base32 "0s8li1ynb89nx5isxmg0rbbk6aw85i0218391z9nzgkj8kxgww9j"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_payment_braintree"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-braintree trytond trytond-account
           trytond-account-payment trytond-party))
    (home-page
     "https://docs.tryton.org/projects/modules-account-payment-braintree")
    (synopsis "Tryton module for Braintree payment")
    (description "The @emph{Account Payment Braintree} Tryton module allows
receipt of payments using Braintree.  It uses the Drop-in UI in a checkout
form to handle the payment method nonce for card and other supported payment
methods.")
    (license license:gpl3+)))

(define-public trytond-account-payment-clearing
  (package
    (name "trytond-account-payment-clearing")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_payment_clearing" version))
       (sha256
        (base32 "037d759nzfs5qh97a5hq24argrga9i3p0b966xckss38cwyq7ixq"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_payment_clearing"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-account-statement" ,trytond-account-statement)
       ("trytond-account-statement-rule" ,trytond-account-statement-rule)))
    (propagated-inputs
     (list trytond trytond-account-payment))
    (home-page
     "https://docs.tryton.org/projects/modules-account-payment-clearing")
    (synopsis "Tryton module for payment clearing")
    (description "The @emph{Account Payment Clearing} Tryton module allows
generating an account move when a payment succeeded between the
receivable/payable account to a clearing account defined on the payment
journal.")
    (license license:gpl3+)))

(define-public trytond-account-payment-sepa
  (package
    (name "trytond-account-payment-sepa")
    (version "6.2.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_payment_sepa" version))
       (sha256
        (base32 "0c3ij24l8mxad2ppd3r24mx92l2xm52ip2syf88wlxqhsja9p945"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_payment_sepa"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-stdnum
           trytond
           trytond-account-payment
           trytond-bank
           trytond-company
           trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-account-payment-sepa")
    (synopsis "Tryton module for SEPA payment")
    (description "The @emph{Account Payment SEPA} Tryton module allows
generating SEPA files for a Payment Group.")
    (license license:gpl3+)))

(define-public trytond-account-payment-sepa-cfonb
  (package
    (name "trytond-account-payment-sepa-cfonb")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_payment_sepa_cfonb" version))
       (sha256
        (base32 "1a4g2jzk8f98iy3plzanz8wfw5jixqpbsljqfigcp05nykbcfwzf"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_payment_sepa_cfonb"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-account-payment
           trytond-account-payment-sepa
           trytond-bank
           trytond-company
           trytond-party))
    (home-page
     "https://docs.tryton.org/projects/modules-account-payment-sepa-cfonb")
    (synopsis "Tryton module for CFONB SEPA payment")
    (description "The @emph{account payment sepa cfonb} Tryton module adds
CFONB flavors to SEPA messages.")
    (license license:gpl3+)))

(define-public trytond-account-payment-stripe
  (package
    (name "trytond-account-payment-stripe")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_payment_stripe" version))
       (sha256
        (base32 "11lmgw4ny5v7zimvx35kkmy9n2pa342j97abn25y10yrcacfjhvh"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_payment_stripe"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-stripe trytond trytond-account trytond-account-payment
           trytond-party))
    (home-page
     "https://docs.tryton.org/projects/modules-account-payment-stripe")
    (synopsis "Tryton module for Stripe payment")
    (description "The @emph{Account Payment Stripe} Tryton module for
receiving payments from Stripe.  It uses Stripe.js and Stripe Elements in a
checkout form to handle Setup Intent and Payment Intent by card.")
    (license license:gpl3+)))

(define-public trytond-account-product
  (package
    (name "trytond-account-product")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_product" version))
       (sha256
        (base32 "1z1ri2plsmdnhgw64r5yxk2m346zcnva8nddmcwcalis35krgjcx"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_product"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account trytond-analytic-account
           trytond-company trytond-product))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module to add accounting on product")
    (description
     "This package provides a Tryton module that adds accounting on product
and category.")
    (license license:gpl3+)))

(define-public python-trytond-account-product
  (deprecated-package "python-trytond-account-product" trytond-account-product))

(define-public trytond-account-rule
  (package
    (name "trytond-account-rule")
    (version "6.2.1")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "trytond_account_rule" version))
              (sha256
               (base32 "1rn0xdqk5pcjybpyw09fqag6lyha06dq9qb3v0jc31cvwmd17ckl"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "trytond_account_rule"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs (list trytond trytond-account
                             trytond-company trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-account-rule")
    (synopsis "Tryton module to change accounts based on rules")
    (description "The @emph{Account Rule} Tryton module allows rules which
substitute default accounts with other accounts.")
    (license license:gpl3+)))

(define-public trytond-account-statement
  (package
    (name "trytond-account-statement")
    (version "6.2.3")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_statement" version))
       (sha256
        (base32 "1c7k1xv5jcraaa9dqdzxphqffycbc1ygy0gc49909vql1r8dpzk5"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_statement"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-account
           trytond-account-invoice
           trytond-bank
           trytond-company
           trytond-currency
           trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-account-statement")
    (synopsis "Tryton module with account statements")
    (description "The @emph{Account Statement} Tryton module allows booking
statements.  Statement can be used for bank statement, cash daybook etc.")
    (license license:gpl3+)))

(define-public trytond-account-statement-aeb43
  (package
    (name "trytond-account-statement-aeb43")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_statement_aeb43" version))
       (sha256
        (base32 "1snjabg4qixsb99lsrirpx7zrz0f21wy46d61rar5704657yxyc9"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_statement_aeb43"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-csb43 python-stdnum trytond trytond-account-statement
           trytond-bank))
    (home-page
     "https://docs.tryton.org/projects/trytond-account-statement-aeb43")
    (synopsis "Tryton module to import AEB43 statements")
    (description "The @emph{Account Statement AEB43} Tryton module implements
the import of @emph{Norm 43} files as statement.  @emph{Norm 43} is a standard
defined by the Spanish banking association.")
    (license license:gpl3+)))

(define-public trytond-account-statement-coda
  (package
    (name "trytond-account-statement-coda")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_statement_coda" version))
       (sha256
        (base32 "0flz8rkavfcwq3przw9sq8jnpf6hdmyi3ip7vc89s3ykdx4qcrh0"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_statement_coda"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-febelfin-coda trytond trytond-account-statement
           trytond-bank))
    (home-page
     "https://docs.tryton.org/projects/modules-account-statement-coda")
    (synopsis "Tryton module to import CODA statements")
    (description "The @emph{Account Statement CODA} Tryton module implements
the import of @emph{CODA} files as statement.  @emph{CODA} is a standard
defined by Belgian \"febelfin\".")
    (license license:gpl3+)))

(define-public trytond-account-statement-ofx
  (package
    (name "trytond-account-statement-ofx")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_statement_ofx" version))
       (sha256
        (base32 "01ncqvz4nx277q7x50sqwwvcy3hcpgp7bwhbp2l5aa2habprki8x"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_statement_ofx"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-ofxparse trytond trytond-account-statement trytond-bank
           trytond-party))
    (home-page
     "https://docs.tryton.org/projects/modules-account-statement-ofx")
    (synopsis "Tryton module to import OFX statements")
    (description "The @emph{Account Statement OFX} Tryton module implements
the import of the @emph{OFX} files as statement.")
    (license license:gpl3+)))

(define-public trytond-account-statement-rule
  (package
    (name "trytond-account-statement-rule")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_statement_rule" version))
       (sha256
        (base32 "1fbn4z111k0wwsy9jr9np82yyc7xiniavyavwhf0qf3l6l8qwk6x"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_statement_rule"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-account
           trytond-account-invoice
           trytond-account-statement
           trytond-company
           trytond-party))
    (home-page
     "https://docs.tryton.org/projects/modules-account-statement-rule")
    (synopsis "Tryton module to automate statement import with rules")
    (description "The @emph{Account Statement Rule} Tryton module allows rules
to be defined to complete statement lines from imported files.

When the @emph{Apply Rule} button is clicked on a statement, each rule is
tested in order against each origin that does not have any lines until one is
found that matches.  Then the rule found is used to create the statement lines
linked to the origin.")
    (license license:gpl3+)))

(define-public trytond-account-stock-anglo-saxon
  (package
    (name "trytond-account-stock-anglo-saxon")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_stock_anglo_saxon" version))
       (sha256
        (base32 "1jgj5kb85qj3kb1hcyb9jps1x062cqa32x5rp4rvgg64824d8hwz"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_stock_anglo_saxon"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-purchase" ,trytond-purchase)
       ("trytond-sale" ,trytond-sale)
       ("trytond-sale-supply-drop-shipment"
        ,trytond-sale-supply-drop-shipment)))
    (propagated-inputs
     (list trytond
           trytond-account
           trytond-account-invoice
           trytond-account-invoice-stock
           trytond-account-product
           trytond-account-stock-continental))
    (home-page
     "https://docs.tryton.org/projects/modules-account-stock-anglo-saxon")
    (synopsis "Tryton module for anglo-saxon real-time stock valuation")
    (description "The @emph{Account Stock Anglo Saxon} Tryton module adds the
anglo-saxon accounting model for stock valuation.")
    (license license:gpl3+)))

(define-public trytond-account-stock-continental
  (package
    (name "trytond-account-stock-continental")
    (version "6.2.3")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_stock_continental" version))
       (sha256
        (base32 "1dzldnasshpx2gn15scycj72z85z5xli5wq1h39y8brb49ib7nvy"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_stock_continental"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-account-invoice" ,trytond-account-invoice)
       ("trytond-purchase" ,trytond-purchase)
       ("trytond-sale" ,trytond-sale)
       ("trytond-sale-supply-drop-shipment"
        ,trytond-sale-supply-drop-shipment)))
    (propagated-inputs
     (list trytond trytond-account trytond-account-product trytond-stock))
    (home-page
     "https://docs.tryton.org/projects/modules-account-stock-continental")
    (synopsis "Tryton module for continental real-time stock valuation")
    (description "The @emph{Account Stock Continental} Tryton module adds the
continental accounting model for stock valuation.")
    (license license:gpl3+)))

(define-public trytond-account-stock-landed-cost
  (package
    (name "trytond-account-stock-landed-cost")
    (version "6.2.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_stock_landed_cost" version))
       (sha256
        (base32 "01yfkhwxw86s354y51bhs799cvfhwkmjrnmhaspbn889mkpir0wg"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_stock_landed_cost"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account trytond-account-invoice
           trytond-product trytond-stock))
    (home-page
     "https://docs.tryton.org/projects/modules-account-stock-landed-cost")
    (synopsis "Tryton module for landed cost")
    (description "The @emph{Account Stock Landed Cost} Tryton module allows
allocating landed cost on Supplier Shipments after their reception.")
    (license license:gpl3+)))

(define-public trytond-account-stock-landed-cost-weight
  (package
    (name "trytond-account-stock-landed-cost-weight")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_stock_landed_cost_weight" version))
       (sha256
        (base32 "1dx5m5l1ccnffkqgwxpfk57g1wndxq1q1jrmrbf4cj6q47x1y0xx"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_stock_landed_cost_weight"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account-stock-landed-cost trytond-product
           trytond-product-measurements trytond-stock-shipment-measurements))
    (home-page
     "https://docs.tryton.org/projects/modules-account-stock-landed-cost-weight")
    (synopsis "Tryton module for landed cost per weight")
    (description "The @emph{Account Stock Landed Cost Weight} Tryton module
adds an allocation method based on weight of each line.  The Weight is taken
from the Product Measurements")
    (license license:gpl3+)))

(define-public trytond-account-stock-shipment-cost
  (package
    (name "trytond-account-stock-shipment-cost")
    (version "6.2.1")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "trytond_account_stock_shipment_cost" version))
              (sha256
               (base32 "1iyz76cma63kp2alqr4rcrm3zjj6ifsvv9hsylbfkamfgy84brsr"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "trytond_account_stock_shipment_cost"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs (list trytond
                             trytond-account
                             trytond-account-invoice
                             trytond-product
                             trytond-stock
                             trytond-stock-shipment-cost))
    (home-page "https://docs.tryton.org/projects/modules-account-stock-shipment-cost")
    (synopsis "Tryton module to allocate shipment cost based on invoice")
    (description "The @emph{Account Stock Shipment Cost} Tryton module
allocates shipment cost based on invoice.")
    (license license:gpl3+)))

(define-public trytond-account-tax-cash
  (package
    (name "trytond-account-tax-cash")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_tax_cash" version))
       (sha256
        (base32 "0hy5929697lsa84xyy535gh4s2j1yv4vdfxyi93md17pjf95hwpg"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_tax_cash"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account trytond-account-invoice trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-account-tax-cash")
    (synopsis "Tryton module to support tax report on cash basis")
    (description "The @emph{Account Tax Cash} Tryton module allows making a tax
report on cash basis.")
    (license license:gpl3+)))

(define-public trytond-account-tax-rule-country
  (package
    (name "trytond-account-tax-rule-country")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_tax_rule_country" version))
       (sha256
        (base32 "0bg831hha4j71lm9xhpv4al2qaxmk8qgli5s9hx2h4bcy1hbf5wf"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_tax_rule_country"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-account-invoice" ,trytond-account-invoice)
       ("trytond-purchase" ,trytond-purchase)
       ("trytond-sale" ,trytond-sale)
       ("trytond-stock" ,trytond-stock)))
    (propagated-inputs
     (list trytond trytond-account trytond-country))
    (home-page
     "https://docs.tryton.org/projects/modules-account-tax-rule-country")
    (synopsis "Tryton module to add countries on tax rules")
    (description "The @emph{Account Tax Rule Country} Tryton module extends
the tax rule to add origin and destination countries and subdivisions as
criteria.")
    (license license:gpl3+)))

(define-public trytond-analytic-account
  (package
    (name "trytond-analytic-account")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_analytic_account" version))
       (sha256
        (base32 "1ys9admjlgvn2m2zjp74liplzmc8q12x8i004cgb5m43x2mhrj8d"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "analytic_account"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account trytond-company trytond-currency
           trytond-party))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for analytic accounting")
    (description
     "This package provides a Tryton module that adds the fundamentals
required to analyse accounting using multiple different axes.")
    (license license:gpl3+)))

(define-public python-trytond-analytic-account
  (deprecated-package
   "python-trytond-analytic-account" trytond-analytic-account))

(define-public trytond-analytic-budget
  (package
    (name "trytond-analytic-budget")
    (version "6.2.1")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "trytond_analytic_budget" version))
              (sha256
               (base32 "080a1s9w6n50xi2r7d3jkyk84rdqzggbqzhab9qjgppl67q85m8p"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "trytond_analytic_budget"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs (list trytond trytond-account-budget
                             trytond-analytic-account
                             trytond-company))
    (home-page "https://docs.tryton.org/projects/modules-analytic-budget")
    (synopsis "Allow creating budgets for analytic accounts in Tryton")
    (description "The @emph{Analytic Budget} Tryton module provides the
ability to set budgets for analytic accounts over a defined period of time.
These budgets can then be used to track the total amount from relevant
transactions against the budgeted amount.")
    (license license:gpl3+)))

(define-public trytond-analytic-invoice
  (package
    (name "trytond-analytic-invoice")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_analytic_invoice" version))
       (sha256
        (base32 "0416knbcn7wcx4anzvl0hw7qcdn3xndlh5i0pa0xffvw6kw1ijp9"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "analytic_invoice"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-account-asset" ,trytond-account-asset)))
    (propagated-inputs
     (list trytond trytond-account-invoice trytond-analytic-account))
    (home-page "https://docs.tryton.org/projects/modules-analytic-invoice")
    (synopsis "Tryton module to add analytic accounting on invoice")
    (description "The @emph{Analytic Invoice} Tryton module allows setting
analytic accounts on an invoice line.")
    (license license:gpl3+)))

(define-public trytond-analytic-purchase
  (package
    (name "trytond-analytic-purchase")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_analytic_purchase" version))
       (sha256
        (base32 "098sdhmr1idqqaxms3c05pgmvb27bykwfhgibxi9l1lr6k06d2cr"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "analytic_purchase"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-analytic-account trytond-analytic-invoice
           trytond-purchase))
    (home-page "https://docs.tryton.org/projects/modules-analytic-purchase")
    (synopsis "Tryton module to add analytic accounting on purchase")
    (description "The @emph{Analytic Purchase} Tryton module allows setting
analytic accounts on a purchase line.")
    (license license:gpl3+)))

(define-public trytond-analytic-sale
  (package
    (name "trytond-analytic-sale")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_analytic_sale" version))
       (sha256
        (base32 "00b3xiykm9j0kf1f9kmsy22413rdjsmvg5li7bd4xrxk22j8v4wv"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "analytic_sale"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-analytic-account trytond-analytic-invoice
           trytond-sale))
    (home-page "https://docs.tryton.org/projects/modules-analytic-sale")
    (synopsis "Tryton module to add analytic accounting on sale")
    (description "The @emph{Analytic Sale} Tryton module allows setting
analytic accounts on a sale line.")
    (license license:gpl3+)))

(define-public trytond-attendance
  (package
    (name "trytond-attendance")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_attendance" version))
       (sha256
        (base32 "0g9b0x4zdz6djmd592ll8zj4q3lhz5gj97phc38kkzvwgvpq9xw2"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "attendance"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-timesheet" ,trytond-timesheet)))
    (propagated-inputs
     (list trytond trytond-company))
    (home-page "https://docs.tryton.org/projects/modules-attendance")
    (synopsis "Tryton module for recording employee attendance")
    (description "The @emph{Attendance} Tryton module allows you to track the
entry and exit time of employees.  The module also comes with a sheet that
shows for each employee the total duration per day in the company and the
detail of the time of entrance and exit")
    (license license:gpl3+)))

(define-public trytond-authentication-sms
  (package
    (name "trytond-authentication-sms")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_authentication_sms" version))
       (sha256
        (base32 "17237qrmk8pm7lifrn5zjvsf42cs2q6p2h6qw2vk9fixdz1gxk9x"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "authentication_sms"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond))
    (home-page "https://docs.tryton.org/projects/modules-authentication-sms")
    (synopsis "Tryton module to authenticate users via SMS")
    (description "The @emph{Authentication SMS} Tryton module allows users to
authenticate via SMS.  It adds a new authentication method sms, which can be
used in the list of authentications in the session section of the
configuration file.")
    (license license:gpl3+)))

(define-public trytond-bank
  (package
    (name "trytond-bank")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_bank" version))
       (sha256
        (base32 "1gvsd8yyrba9bsql9zi4wlmg1jyjb7m13m15av0szkwxylcy0c0q"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "bank"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-stdnum trytond trytond-currency trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-bank")
    (synopsis "Tryton module with banks")
    (description "The @emph{Bank} Tryton module defines the concept of bank
and account.")
    (license license:gpl3+)))

(define-public trytond-carrier
  (package
    (name "trytond-carrier")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_carrier" version))
       (sha256
        (base32 "1fr12m4qi0fkxnbjq5v1sf5dkic9xb2j0bvb8y18if3hh0csfcy7"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "carrier"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-country trytond-party trytond-product))
    (home-page "https://docs.tryton.org/projects/modules-carrier")
    (synopsis "Tryton module with carriers")
    (description "The @emph{Carrier} Tryton module defines the concept
of carrier.")
    (license license:gpl3+)))

(define-public trytond-carrier-percentage
  (package
    (name "trytond-carrier-percentage")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_carrier_percentage" version))
       (sha256
        (base32 "0lnahli4bc4zspr86i8qchza96k4cmsfcdg3wp7wicp1s2ki7bbw"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "carrier_percentage"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-purchase-shipment-cost" ,trytond-purchase-shipment-cost)
       ("trytond-sale-shipment-cost" ,trytond-sale-shipment-cost)
       ("trytond-stock-shipment-cost" ,trytond-stock-shipment-cost)))
    (propagated-inputs
     (list trytond trytond-carrier trytond-currency))
    (home-page "https://docs.tryton.org/projects/modules-carrier-percentage")
    (synopsis "Tryton module to add cost method based on percentage")
    (description "The @emph{Carrier Percentage} Tryton module adds a cost
method \"on percentage\" on carrier.")
    (license license:gpl3+)))

(define-public trytond-carrier-subdivision
  (package
    (name "trytond-carrier-subdivision")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_carrier_subdivision" version))
       (sha256
        (base32 "1a4jpi6iaah3f1zsdsjz2zak6wd9jai4jcqzijl2li4pcnkc0x8a"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "carrier_subdivision"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-sale-shipment-cost" ,trytond-sale-shipment-cost)
       ("trytond-stock-shipment-cost" ,trytond-stock-shipment-cost)))
    (propagated-inputs
     (list trytond trytond-carrier))
    (home-page "https://docs.tryton.org/projects/modules-carrier-subdivision")
    (synopsis "Tryton module that allows carriers selection to be restricted
by subdivision")
    (description "The @emph{Carrier Subdivision} Tryton module extends the
carrier selection pattern with

@itemize
@item the warehouse Subdivision,
@item the customer Subdivision,
@item a regular expression to match against warehouse postal code and
@item A regular expression to match against customer postal code.
@end itemize

These can be used to restrict the usage of a carrier to a specific subdivision
or a specific postal code.")
    (license license:gpl3+)))

(define-public trytond-carrier-weight
  (package
    (name "trytond-carrier-weight")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_carrier_weight" version))
       (sha256
        (base32 "0mvz7q2hb4bcj3abvi4dxmnqbrph1g49s2bvyf3lx9ykbmr6v3n7"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "carrier_weight"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-purchase-shipment-cost" ,trytond-purchase-shipment-cost)
       ("trytond-sale-shipment-cost" ,trytond-sale-shipment-cost)
       ("trytond-stock-shipment-cost" ,trytond-stock-shipment-cost)))
    (propagated-inputs
     (list trytond
           trytond-carrier
           trytond-company
           trytond-currency
           trytond-product
           trytond-product-measurements))
    (home-page "https://docs.tryton.org/projects/modules-carrier-weight")
    (synopsis "Tryton module to add cost method based on weight")
    (description "The @emph{Carrier Weight} Tryton module adds a cost method
\"on weight\" on carrier.  The price is computed by finding the line for which
the weight is greater or equal but smaller than the next line.")
    (license license:gpl3+)))

(define-public trytond-commission
  (package
    (name "trytond-commission")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_commission" version))
       (sha256
        (base32 "1m8cg6vb08paymi3bckqwp2vg0as36p6jadg86dc4b1axabas144"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "commission"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-sale" ,trytond-sale)))
    (propagated-inputs
     (list python-simpleeval
           trytond
           trytond-account
           trytond-account-invoice
           trytond-account-product
           trytond-party
           trytond-product))
    (home-page "https://docs.tryton.org/projects/modules-commission")
    (synopsis "Tryton module for commission")
    (description "The @emph{Commission} Tryton module allows manageing a
commission for sales agents.  A commission move is created when posting the
invoice, following the agent's commission plan.")
    (license license:gpl3+)))

(define-public trytond-commission-waiting
  (package
    (name "trytond-commission-waiting")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_commission_waiting" version))
       (sha256
        (base32 "16y11dc33x1h55v94rab8wzbh4d1pc35vd64ys8915rvijpm6xm5"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "commission_waiting"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account trytond-account-invoice
           trytond-commission))
    (home-page "https://docs.tryton.org/projects/modules-commission-waiting")
    (synopsis "Tryton module for commission waiting")
    (description "The @emph{Commission Waiting} Tryton module allows
generating an account move for each commission between the expense/revenue account
to a waiting account defined on the agent.")
    (license license:gpl3+)))

(define-public trytond-company
  (package
    (name "trytond-company")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_company" version))
       (sha256
        (base32 "03ss7cwxbynn8ly5y32bj1cl2ikji9ydsby62l440jb025sn9x8v"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "company"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-currency trytond-party))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module with companies and employees")
    (description
     "This package provides a Tryton module that defines the concepts of
company and employee and extend the user model.")
    (license license:gpl3+)))

(define-public python-trytond-company
  (deprecated-package "python-trytond-company" trytond-company))

(define-public trytond-company-work-time
  (package
    (name "trytond-company-work-time")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_company_work_time" version))
       (sha256
        (base32 "08nhnlxy1z5drlmxdsd6ad166qx5ckymzx94ja824n1qqac17zqw"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "company_work_time"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-company))
    (home-page "https://docs.tryton.org/projects/modules-company-work-time")
    (synopsis "Tryton module to add work time on company")
    (description "The @emph{Company Work Time} Tryton module adds work time
management.

The Company Work Time module adds 4 new fields (Hours per Work Day, Hours per
Work Week, Hours per Work Month, Hours per Work Year) on the company form that
allows defining how many hours are spent by an employee in a day, a week, a
month and a year of work.")
    (license license:gpl3+)))

(define-public trytond-country
  (package
    (name "trytond-country")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_country" version))
       (sha256
        (base32 "1mlf6fwngdbqy6c7xi7nmg4dph3nnac61rkzhn79x5zqg2mgnv53"))))
    (build-system python-build-system)
    ;; Doctest contains one test that requires internet access.
    (arguments (tryton-arguments "country" "--no-doctest"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-pycountry@20.7.3 trytond))
    (home-page "http://www.tryton.org/")
    (synopsis "Tryton module with countries")
    (description
     "This package provides a Tryton module with countries.")
    (license license:gpl3+)))

(define-public python-trytond-country
  (deprecated-package "python-trytond-country" trytond-country))

(define-public trytond-currency
  (package
    (name "trytond-currency")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_currency" version))
       (sha256
        (base32 "1sx9wanb4r95gs5hsl6hgy0gcvsfh0yr17rnhaa908286f88wa4f"))))
    (build-system python-build-system)
    ;; Doctest 'scenario_currency_rate_update.rst' fails.
    (arguments (tryton-arguments "currency" "--no-doctest"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("python-forex-python" ,python-forex-python)
       ("python-pycountry" ,python-pycountry)))
    (propagated-inputs
     (list python-sql trytond))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module with currencies")
    (description
     "This package provides a Tryton module that defines the concepts of
currency and rate.")
    (license license:gpl3+)))

(define-public python-trytond-currency
  (deprecated-package "python-trytond-currency" trytond-currency))

(define-public trytond-currency-ro
  (package
    (name "trytond-currency-ro")
    (version "6.2.0")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "trytond_currency_ro" version))
              (sha256
               (base32 "1kn4bgh1gg5dcphb2afqb922myyg2012vdhixipmi7ccbv7ik46s"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "trytond_currency_ro"))
        (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs (list python-lxml python-requests trytond
                             trytond-currency))
    (home-page "https://docs.tryton.org/projects/modules-currency-ro")
    (synopsis "Fetch currency rates from the Romanian National Bank")
    (description "The @emph{Currency RO} Tryton module adds the Romanian
National Bank as a source for currency exchange rates.")
    (license license:gpl3+)))

(define-public trytond-currency-rs
  (package
    (name "trytond-currency-rs")
    (version "6.2.0")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "trytond_currency_rs" version))
              (sha256
               (base32 "05admscvj5m7anhji2ni9w2d8b33vlgcifda6jbrxdw8g4c0yivn"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "trytond_currency_rs"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs (list python-lxml trytond trytond-currency
                             python-zeep))
    (home-page "https://docs.tryton.org/projects/modules-currency-rs")
    (synopsis "Fetch currency rates from the Serbian National Bank")
    (description "The @emph{Currency RS} Tryton module adds the Serbian
National Bank as a source for currency exchange rates.")
    (license license:gpl3+)))

(define-public trytond-customs
  (package
    (name "trytond-customs")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_customs" version))
       (sha256
        (base32 "1zx9cwiq9q4802bj2ga3bilyjls60vpycp3cncqfqh2n4mg23xlq"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "customs"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-simpleeval trytond trytond-country trytond-currency
           trytond-product))
    (home-page "https://docs.tryton.org/projects/modules-customs")
    (synopsis "Tryton module for customs")
    (description "The @emph{Customs} Tryton module allows defining customs
duty based on the tariff code.")
    (license license:gpl3+)))

(define-public trytond-dashboard
  (package
    (name "trytond-dashboard")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_dashboard" version))
       (sha256
        (base32 "1b8dalnbj69ppk8q7znw1ljyv5515r16m6gfd9a3l25dpvj0cxz2"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "dashboard"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond))
    (home-page "https://docs.tryton.org/projects/modules-dashboard")
    (synopsis "Tryton module for dashboard")
    (description "The @emph{Dashboard} Tryton module allows users to
configure their dashboard.")
    (license license:gpl3+)))

(define-public trytond-edocument-uncefact
  (package
    (name "trytond-edocument-uncefact")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_edocument_uncefact" version))
       (sha256
        (base32 "0nf72c5sw33c77y87idkhf8fz39a7qlgmlrbnzz1cwcpky4hrmdg"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "edocument_uncefact"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("python-lxml" ,python-lxml)
       ("trytond-account-invoice" ,trytond-account-invoice)))
    (propagated-inputs
     (list trytond trytond-edocument-unece))
    (home-page "https://docs.tryton.org/projects/modules-edocument-uncefact")
    (synopsis "Tryton module for electronic document UN/CEFACT")
    (description "The @emph{Edocument UN/CEFACT} Tryton module implements
electronic document from UN/CEFACT.  Supported formats are:

@itemize
@item Cross-Industry-Invoice (16B-CII)
@end itemize")
    (license license:gpl3+)))

(define-public trytond-edocument-unece
  (package
    (name "trytond-edocument-unece")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_edocument_unece" version))
       (sha256
        (base32 "1ikrh9yk5if8v1sw1aihnysbpipmly6r6ka6zccjcywm1cmabhx0"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "edocument_unece"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account trytond-product))
    (home-page "https://docs.tryton.org/projects/modules-edocument-unece")
    (synopsis "Tryton module for electronic document UNECE codes")
    (description "The @emph{Edocument UNECE} Tryton module adds several codes
from the UNECE.  Supported formats are:

@itemize
@item Recommendation N°. 20 Codes for
      Units of Measure Used in International Trade
@item 5153  Duty or tax or fee type name code
@item 5305  Duty or tax or fee category code
@end itemize")
    (license license:gpl3+)))

(define-public trytond-gis
  (package
    (name "trytond-gis")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_gis" version))
       (sha256
        (base32 "0zfvbqzxhvjja03pv9ja9rml2i2fqiir5a92rz0vj3lx9azjbkvw"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "trytond_gis"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs (list python-geomet  trytond))
    (home-page "https://docs.tryton.org/projects/backend-gis")
    (synopsis "Geographic Information System support from Tryton")
    (description "The @emph{Trytond GIS} Tryton module adds GIS (Geographic
information system) support to Tryton.")
    (license license:gpl3+)))

(define-public trytond-google-maps
  (package
    (name "trytond-google-maps")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_google_maps" version))
       (sha256
        (base32 "0g6hag2n7rc7avcawwhdkndbqxc957nyrwq4arkrlkidpbipw37n"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "trytond_google_maps"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs (list trytond trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-google-maps")
    (synopsis "Tryton module to link addresses to Google Maps")
    (description "The @emph{Trytond Google Maps} Tryton module adds a new URL
field on the party addresses.  This link open the Google Maps page on the
default browser with the map centered on the selected address.")
    (license license:gpl3+)))

(define-public trytond-incoterm
  (package
    (name "trytond-incoterm")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_incoterm" version))
       (sha256
        (base32 "08sz2j3610iqqzz3qdl51pxdj8mncyjp8lg29y6sskfd0s4fhax5"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "incoterm"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-account" ,trytond-account)
       ("trytond-account-invoice" ,trytond-account-invoice)
       ("trytond-account-invoice-stock" ,trytond-account-invoice-stock)
       ("trytond-carrier" ,trytond-carrier)
       ("trytond-purchase" ,trytond-purchase)
       ("trytond-purchase-request-quotation"
        ,trytond-purchase-request-quotation)
       ("trytond-sale" ,trytond-sale)
       ("trytond-sale-invoice-grouping" ,trytond-sale-invoice-grouping)
       ("trytond-sale-opportunity" ,trytond-sale-opportunity)
       ("trytond-sale-shipment-cost" ,trytond-sale-shipment-cost)
       ("trytond-stock" ,trytond-stock)
       ("trytond-stock-shipment-cost" ,trytond-stock-shipment-cost)))
    (propagated-inputs
     (list trytond trytond-company trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-incoterm")
    (synopsis "Tryton module for incoterms")
    (description "The @emph{Incoterm} Tryton module is used to manage the
Incoterms on sales, purchases and shipments.  The module contains the Incoterm
versions of 2010 and 2020.")
    (license license:gpl3+)))

(define-public trytond-ldap-authentication
  (package
    (name "trytond-ldap-authentication")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_ldap_authentication" version))
       (sha256
        (base32 "0c3g2y8zqh17wwg9w3bk9q1gwm4hq7h8avchmbfawi6cq3g6ch5b"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "ldap_authentication"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-ldap3 trytond))
    (home-page "https://docs.tryton.org/projects/modules-ldap-authentication")
    (synopsis "Tryton module to authenticate users through LDAP")
    (description "The @emph{LDAP Authentication} Tryton module allows
authenticating users via a LDAP server.")
    (license license:gpl3+)))

(define-public trytond-marketing
  (package
    (name "trytond-marketing")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_marketing" version))
       (sha256
        (base32 "1ljv23ldva3cd07k0knncnawwrig8q6lgsxlm392dcqkyb8gvbjg"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "marketing"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond))
    (home-page "https://docs.tryton.org/projects/modules-marketing")
    (synopsis "Tryton module to group marketing features")
    (description "The @emph{Marketing} Tryton module defines the
fundamentals for marketing modules.")
    (license license:gpl3+)))

(define-public trytond-marketing-automation
  (package
    (name "trytond-marketing-automation")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_marketing_automation" version))
       (sha256
        (base32 "17x4pikw2i513wwrfv8g8xim65ksk3dwijahk1qhf3yqpa506kp2"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "marketing_automation"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-party" ,trytond-party)))
    (propagated-inputs
     (list trytond trytond-marketing trytond-web-shortener))
    (home-page "https://docs.tryton.org/projects/modules-marketing-automation")
    (synopsis "Tryton module to plan, coordinate and manage marketing
campaigns")
    (description "The @emph{Marketing Automation} Tryton module allows
marketing actions to be automated.  It is based on scenarios and activities
that are executed on selected records.")
    (license license:gpl3+)))

(define-public trytond-marketing-email
  (package
    (name "trytond-marketing-email")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_marketing_email" version))
       (sha256
        (base32 "1z38c3lw8chqbm23y0wfsnp268kq2f9azly4ix6imis74zdjnzkl"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "marketing_email"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-marketing trytond-party trytond-web-shortener
           trytond-web-user))
    (home-page "https://docs.tryton.org/projects/modules-marketing-email")
    (synopsis "Tryton module to manage marketing mailing lists")
    (description "This package provides a Tryton module for managing marketing
mailing lists.")
    (license license:gpl3+)))

(define-public trytond-notification-email
  (package
    (name "trytond-notification-email")
    (version "6.2.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_notification_email" version))
       (sha256
        (base32 "1i0h7spdnf3gryzbzjm8khc0jxzj6g6ljsjgsd28h39kqpdxyffz"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "notification_email"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-commission" ,trytond-commission)
       ("trytond-company" ,trytond-company)
       ("trytond-party" ,trytond-party)
       ("trytond-web-user" ,trytond-web-user)))
    (propagated-inputs
     (list trytond))
    (home-page "https://docs.tryton.org/projects/modules-notification-email")
    (synopsis "Tryton module for sending email notifications")
    (description "The @emph{Notification Email} Tryton module allows defining
email templates which will be sent to a list of recipients when a trigger is
fired on a record event.  Extra reports from the same record can be attached
to the email.")
    (license license:gpl3+)))

(define-public trytond-party
  (package
    (name "trytond-party")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_party" version))
       (sha256
        (base32 "1g62kzdqr4rq6k8zswil4anwhd22d8nzz0i852fmkdsb97yqg4id"))))
    (build-system python-build-system)
    ;; Doctest 'scenario_party_phone_number.rst' fails.
    (arguments (tryton-arguments "party" "--no-doctest"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-stdnum trytond trytond-country))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for parties and addresses")
    (description
     "This package provides a Tryton module for (counter)parties and
addresses.")
    (license license:gpl3+)))

(define-public python-trytond-party
  (deprecated-package "python-trytond-party" trytond-party))

(define-public trytond-party-avatar
  (package
    (name "trytond-party-avatar")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_party_avatar" version))
       (sha256
        (base32 "00gjjvslvcvfkdb0293n9yd9pmsnlbjvcnxrjg99vxkrn6dcwxzh"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "party_avatar"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-company" ,trytond-company)))
    (propagated-inputs
     (list trytond trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-party-avatar")
    (synopsis "Tryton module that adds avatars to parties")
    (description "The @emph{Party Avatar} Tryton module adds an avatar to each
party.")
    (license license:gpl3+)))

(define-public trytond-party-relationship
  (package
    (name "trytond-party-relationship")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_party_relationship" version))
       (sha256
        (base32 "0vhm7zl29z8al4ay4n6gw3zazq07dsdhjc54il7sg3z9kz21xv6k"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "party_relationship"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-party-relationship")
    (synopsis "Party Relationship module for Tryton")
    (description "The @emph{Party Relationship} Tryton module allows defining
different types of relations between parties.")
    (license license:gpl3+)))

(define-public trytond-party-siret
  (package
    (name "trytond-party-siret")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_party_siret" version))
       (sha256
        (base32 "0ab5g3rs2k73wk01ykzh1s4pgrnypdv4l75lr3pn8hyxw9q4b5vk"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "party_siret"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-party-siret")
    (synopsis "Tryton module to add SIRET/SIREN on parties")
    (description "The @emph{Party SIRET} Tryton module adds the French company
identification numbers SIREN and SIRET on party and address.")
    (license license:gpl3+)))

(define-public trytond-product
  (package
    (name "trytond-product")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_product" version))
       (sha256
        (base32 "1cq270ng0rav7hzxip3fswbvhs6wkjadl2j8kmiy30qa43abmpwr"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "product"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-stdnum trytond trytond-company))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module with products")
    (description
     "This package provides a Tryton module that defines two concepts: Product
Template and Product.")
    (license license:gpl3+)))

(define-public python-trytond-product
  (deprecated-package "python-trytond-product" trytond-product))

(define-public trytond-product-attribute
  (package
    (name "trytond-product-attribute")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_product_attribute" version))
       (sha256
        (base32 "10656g9na098ndjhy4iv1iv0020jin7yw38bb79zxynck39vld29"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "product_attribute"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-product))
    (home-page "https://docs.tryton.org/projects/modules-product-attribute")
    (synopsis "Tryton module with product attributes")
    (description "The @emph{Product Attribute} Tryton module defines the
models `Attribute` and `Attribute Set` for products.")
    (license license:gpl3+)))

(define-public trytond-product-classification
  (package
    (name "trytond-product-classification")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_product_classification" version))
       (sha256
        (base32 "1a5rdvscp3hb7jddciqmpzb095yzmyvsj5jc06jiilvynrawwzsh"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "product_classification"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-product))
    (home-page
     "https://docs.tryton.org/projects/modules-product-classification")
    (synopsis "Tryton module to implement product classification")
    (description "The @emph{Product Classification} Tryton module defines the
tools for other modules to create classifications of products.  It adds a
reference field classification to the product template.")
    (license license:gpl3+)))

(define-public trytond-product-classification-taxonomic
  (package
    (name "trytond-product-classification-taxonomic")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_product_classification_taxonomic" version))
       (sha256
        (base32 "1933kqhab8ky2mman13mmg06rdmlbak3sjgm5qbk615x5fzbl4s4"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "product_classification_taxonomic"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-product-classification))
    (home-page
     "https://docs.tryton.org/projects/modules-product-classification-taxonomic")
    (synopsis "Tryton module to implement product classification taxonomic")
    (description "The @emph{Product Classification Taxonomic} Tryton module
adds the taxonomic classification to the products.")
    (license license:gpl3+)))

(define-public trytond-product-cost-fifo
  (package
    (name "trytond-product-cost-fifo")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_product_cost_fifo" version))
       (sha256
        (base32 "1lqd960z7dmy3000fhhqqbmq7c4lk2l2dqw383sd62ka5j57kpf4"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "product_cost_fifo"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-product trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-product-cost-fifo")
    (synopsis "Tryton module to add FIFO cost method")
    (description "The @emph{Product Cost FIFO} Tryton module add a
first-in-first-out option in the `Cost Method` field of the product form.")
    (license license:gpl3+)))

(define-public trytond-product-cost-history
  (package
    (name "trytond-product-cost-history")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_product_cost_history" version))
       (sha256
        (base32 "16gnqa04fv7525ax12xfmh4phk4fvm577j3c80cahxqpvsp2a0q6"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "product_cost_history"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-product trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-product-cost-history")
    (synopsis "Tryton module to historize product cost")
    (description "The @emph{Product Cost History} Tryton module adds a `Cost
History` relate on the product form, showing the cost price evolution of the
product.  The history is based on the cost price stored on the incoming stock
moves for goods and assets and based on the history table for service.  When a
historic cost price is needed, the value is taken from this history for goods
and assets.")
    (license license:gpl3+)))

(define-public trytond-product-cost-warehouse
  (package
    (name "trytond-product-cost-warehouse")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_product_cost_warehouse" version))
       (sha256
        (base32 "0anz5071j1yzg9xp00qqcc3a4wb3zvl6605bzici76558zj7fl38"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "product_cost_warehouse"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-account-invoice-stock" ,trytond-account-invoice-stock)
       ("trytond-account-stock-continental" ,trytond-account-stock-continental)
       ("trytond-product-cost-fifo" ,trytond-product-cost-fifo)
       ("trytond-product-cost-history" ,trytond-product-cost-history)))
    (propagated-inputs
     (list trytond trytond-company trytond-product trytond-stock))
    (home-page
     "https://docs.tryton.org/projects/modules-product-cost-warehouse")
    (synopsis "Tryton module to compute product cost per warehouse")
    (description "The @emph{Product Cost Warehouse} Trython module allows the
cost price of products to be calculated separately for each warehouse.")
    (license license:gpl3+)))

(define-public trytond-product-image
  (package
    (name "trytond-product-image")
    (version "6.2.1")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "trytond_product_image" version))
              (sha256
               (base32 "1xdqgc4y1sghnp5q25facdz3mnaxf8fysqlpbq3zrghsvi136mvd"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "trytond_product_image"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs (list python-pillow trytond trytond-product))
    (home-page "https://docs.tryton.org/projects/modules-product-image")
    (synopsis "Tryton module that adds images to products")
    (description "The @emph{Product Image} Tryton module adds images to each
product and variant.")
    (license license:gpl3+)))

(define-public trytond-product-image-attribute
  (package
    (name "trytond-product-image-attribute")
    (version "6.2.0")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "trytond_product_image_attribute" version))
              (sha256
               (base32 "1ywyh158325v461qkka5svp4gygsfkkrxd6yl9dgfgypd483qjs8"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "trytond_product_image_attribute"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs (list trytond trytond-product
                             trytond-product-attribute
                             trytond-product-image))
    (home-page "https://docs.tryton.org/projects/modules-product-image-attribute")
    (synopsis "Tryton module to select variant images based on attributes")
    (description "The @emph{Product Image Attribute} Tryton module adds
attributes to product images.")
    (license license:gpl3+)))

(define-public trytond-product-kit
  (package
    (name "trytond-product-kit")
    (version "6.2.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_product_kit" version))
       (sha256
        (base32 "1s41jng93cmf4pahz59jmza1k6nj6pb532k0mn2xnr0pgnh26w9m"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "product_kit"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-account-invoice" ,trytond-account-invoice)
       ("trytond-account-invoice-stock" ,trytond-account-invoice-stock)
       ("trytond-company" ,trytond-company)
       ("trytond-purchase" ,trytond-purchase)
       ("trytond-sale" ,trytond-sale)
       ("trytond-stock" ,trytond-stock)))
    (propagated-inputs
     (list trytond trytond-product))
    (home-page "https://docs.tryton.org/projects/modules-product-kit")
    (synopsis "Tryton module to manage product kits and components")
    (description "The @emph{Product Kit} Tryton Module adds kits and
components to products.  This enables a defined set of products to be sold or
purchased using a single line.")
    (license license:gpl3+)))

(define-public trytond-product-measurements
  (package
    (name "trytond-product-measurements")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_product_measurements" version))
       (sha256
        (base32 "111q382lv3yg76r7jxfhnvr35kgi2fhiyxyj07immvwm5k3z0vi1"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "product_measurements"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-product))
    (home-page "https://docs.tryton.org/projects/modules-product-measurements")
    (synopsis "Tryton module to add measurements to product")
    (description "The @emph{Product Measurements} Tryton module adds this
following measurements to Product:")
    (license license:gpl3+)))

(define-public trytond-product-price-list
  (package
    (name "trytond-product-price-list")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_product_price_list" version))
       (sha256
        (base32 "0x85317skmqkq12i9qqyjiny37rn2dccx7rk7lan87jj2cam70q4"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "product_price_list"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-simpleeval trytond trytond-company trytond-product))
    (home-page "https://docs.tryton.org/projects/modules-product-price-list")
    (synopsis "Tryton module with price list")
    (description "The @emph{Product Price List} Tryton module provides formula
to compute prices per product or category.")
    (license license:gpl3+)))

(define-public trytond-product-price-list-dates
  (package
    (name "trytond-product-price-list-dates")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_product_price_list_dates" version))
       (sha256
        (base32 "0312s99fqfjwyn5lp3b8qd7j0ac0208jbalgxxazfks1h2g22nj5"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "product_price_list_dates"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-sale-price-list" ,trytond-sale-price-list)))
    (propagated-inputs
     (list trytond trytond-product-price-list))
    (home-page
     "https://docs.tryton.org/projects/modules-product-price-list-dates")
    (synopsis "Tryton module to add dates on price list")
    (description "The @emph{Product Price List Dates} Tryton module adds start
date and end date conditions to the price list lines.")
    (license license:gpl3+)))

(define-public trytond-product-price-list-parent
  (package
    (name "trytond-product-price-list-parent")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_product_price_list_parent" version))
       (sha256
        (base32 "0w5fmr2p56p44yq33qgjxp5b8r7bpyixwpdp6xgbrd36ig9wcg3z"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "product_price_list_parent"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-product-price-list))
    (home-page
     "https://docs.tryton.org/projects/modules-product-price-list-parent")
    (synopsis "Tryton module to use price from another price list")
    (description "The @emph{Product Price List Parent} Tryton module adds a
parent to the price list and the keyword `parent_unit_price` for the formula
which contains the unit price computed by the parent price list.")
    (license license:gpl3+)))

(define-public trytond-production
  (package
    (name "trytond-production")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_production" version))
       (sha256
        (base32 "1sjrpyh4cxllmcxh085nfkq4hhdaz2mcgs1x9hwcsk9scqbi8fkw"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "production"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-company trytond-product trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-production")
    (synopsis "Tryton module for production")
    (description "The @emph{Production} Tryton module defines basics
for production management: Bill of material and production order.")
    (license license:gpl3+)))

(define-public trytond-production-outsourcing
  (package
    (name "trytond-production-outsourcing")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_production_outsourcing" version))
       (sha256
        (base32 "0ms50p42jr23v2fgm3kplacr11czx16dljmxvvn4qgxlacsf0dz0"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "production_outsourcing"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-product trytond-production
           trytond-production-routing trytond-purchase))
    (home-page
     "https://docs.tryton.org/projects/modules-production-outsourcing")
    (synopsis "Tryton module to outsource production")
    (description "The @emph{Production Outsourcing} Tryton module allows
outsourcing production orders per routing.  When such outsourced production is
set to @code{waiting}, a purchase order is created and its cost is added to
the production.")
    (license license:gpl3+)))

(define-public trytond-production-routing
  (package
    (name "trytond-production-routing")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_production_routing" version))
       (sha256
        (base32 "1a6cw0yc60ijd8bnrk84rzx4swqi294g3dsapp03hapn9rgdjbpj"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "production_routing"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-stock-supply-production" ,trytond-stock-supply-production)))
    (propagated-inputs
     (list trytond trytond-production))
    (home-page "https://docs.tryton.org/projects/modules-production-routing")
    (synopsis "Tryton module for production routing")
    (description "The @emph{Production Routing} Tryton module defines the
routings for production: Routing, Step and Operation.")
    (license license:gpl3+)))

(define-public trytond-production-split
  (package
    (name "trytond-production-split")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_production_split" version))
       (sha256
        (base32 "1fcsbvmcjxriq4yllxv2h7i2p07caqgka39f04l7pvz4w9ha4s96"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "production_split"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-production))
    (home-page "https://docs.tryton.org/projects/modules-production-split")
    (synopsis "Tryton module to split production")
    (description "The @emph{Production Split} Tryton module adds on the
production a wizard that allows splitting it.  The production is split into
productions of Quantity.  If a count is set, it will be split only this number
of times.  On occasion there can be a production with the remaining
quantity.")
    (license license:gpl3+)))

(define-public trytond-production-work
  (package
    (name "trytond-production-work")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_production_work" version))
       (sha256
        (base32 "1bff8rfdrlx14ahjnmq3lw7z816qnk22cjk9wwmwkcpl99faw3bd"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "production_work"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-company
           trytond-product
           trytond-production
           trytond-production-routing
           trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-production-work")
    (synopsis "Tryton module for production work")
    (description "The @emph{Production Work} Tryton module allows managing a
work order for each production.  It also adds in the production cost for the
work cost.")
    (license license:gpl3+)))

(define-public trytond-production-work-timesheet
  (package
    (name "trytond-production-work-timesheet")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_production_work_timesheet" version))
       (sha256
        (base32 "19d9sasviayn4vkbwgxmgqbn2fd61qqh4sk35vzlmkbwycrbczhi"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "production_work_timesheet"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-production-routing trytond-production-work
           trytond-timesheet))
    (home-page
     "https://docs.tryton.org/projects/modules-production-work-timesheet")
    (synopsis "Tryton module for timesheet on production work")
    (description "The @emph{Production Work Timesheet} Tryton module allows
entering a timesheet for production works.")
    (license license:gpl3+)))

(define-public trytond-project
  (package
    (name "trytond-project")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_project" version))
       (sha256
        (base32 "0rr1ar7ah753afqi16yklirwv3ikmcv4xhnbv5vixna1kqhg8n43"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "project"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-company trytond-company-work-time
           trytond-party trytond-timesheet))
    (home-page "https://docs.tryton.org/projects/modules-project")
    (synopsis "Tryton module with projects")
    (description "The @emph{Project} Tryton module provides the concepts of
project and task and the basis for simple project management.")
    (license license:gpl3+)))

(define-public trytond-project-invoice
  (package
    (name "trytond-project-invoice")
    (version "6.2.3")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_project_invoice" version))
       (sha256
        (base32 "1hdyds6k2k0hjk8za8xa64qvqx9pnyv1a6g7mq80ag8hscx2s282"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "project_invoice"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-account
           trytond-account-invoice
           trytond-account-product
           trytond-product
           trytond-project
           trytond-project-revenue
           trytond-timesheet))
    (home-page "https://docs.tryton.org/projects/modules-project-invoice")
    (synopsis "Tryton module to invoice projects")
    (description "The @emph{Project Invoice} Tryton module adds invoice
methods on projects.  The methods are:
@itemize
@item Manual: Tryton doesn’t create any invoice.
@item On Effort: The invoices are created based on the Effort hours
      for all children works with 100% progress.
@item On Progress: The invoices are create proportionally to the Progress
      of the Effort hours of each children work.
@item On Timesheet: The invoices are created based on the timesheets
      encoded on all children works.
@end itemize")
    (license license:gpl3+)))

(define-public trytond-project-plan
  (package
    (name "trytond-project-plan")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_project_plan" version))
       (sha256
        (base32 "1rijwxx1sypgv3fapw7sv0i6xbci2b6h3ij42aq693yvn0wm46q4"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "project_plan"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-company trytond-project trytond-timesheet))
    (home-page "https://docs.tryton.org/projects/modules-project-plan")
    (synopsis "Tryton module to add planning capabilities on projects")
    (description "The @emph{Project Plan} Tryton module adds planning features
on top of the Project module.")
    (license license:gpl3+)))

(define-public trytond-project-revenue
  (package
    (name "trytond-project-revenue")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_project_revenue" version))
       (sha256
        (base32 "0hpqwjpd6d0a291yssa8f0x89xxqvdzq8a3f10csibsq7bssqzki"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "project_revenue"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-purchase" ,trytond-purchase)))
    (propagated-inputs
     (list trytond
           trytond-company
           trytond-product
           trytond-project
           trytond-timesheet
           trytond-timesheet-cost))
    (home-page "https://docs.tryton.org/projects/modules-project-revenue")
    (synopsis "Tryton module to add revenue on project")
    (description "The @emph{Project Revenue} Tryton module computes revenue
and cost per task and project.  The revenue uses the list price of the
product.  If the product's unit of measure is time based, the revenue is
computed as the product of the price and the hours of effort otherwise the
price is considered as fixed.  The cost is computed by summing the cost of all
the linked time sheets and the linked purchase lines.")
    (license license:gpl3+)))

(define-public trytond-purchase
  (package
    (name "trytond-purchase")
    (version "6.2.3")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_purchase" version))
       (sha256
        (base32 "1lni31dhi1yrz0ga1l2268fyv564gsqiy1rjal8l765v40121q0p"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "purchase"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-account
           trytond-account-invoice
           trytond-account-invoice-stock
           trytond-account-product
           trytond-company
           trytond-currency
           trytond-party
           trytond-product
           trytond-stock))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for purchase")
    (description
     "This package provides a Tryton module that defines the Purchase model.")
    (license license:gpl3+)))

(define-public python-trytond-purchase
  (deprecated-package "python-trytond-purchase" trytond-purchase))

(define-public trytond-purchase-amendment
  (package
    (name "trytond-purchase-amendment")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_purchase_amendment" version))
       (sha256
        (base32 "0zprgfxpif2bbjbv8b4aci7s5si9sp3rjizr7nf31mvsjnwx7i06"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "purchase_amendment"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account-invoice trytond-purchase
           trytond-purchase-history trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-purchase-amendment")
    (synopsis "Tryton module to amend purchases")
    (description "The @emph{Purchase Amendment} Tryton module allows you to
change purchases that are being processed and keep track of the changes.  An
amendment is composed of action lines which can:

@itemize
@item recompute taxes (if the supplier tax rules or product taxes have
      changed),
@item change the payment term,
@item change the party and the address,
@item change the warehouse, or
@item change a purchase line: (product, quantity and unit of measure,
      unit price or description).
@end itemize")
    (license license:gpl3+)))

(define-public trytond-purchase-history
  (package
    (name "trytond-purchase-history")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_purchase_history" version))
       (sha256
        (base32 "0b72q0b41jfaahccdnya9amp5x4w90mlx4b32wdby96xvfi485ar"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "purchase_history"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-purchase))
    (home-page "https://docs.tryton.org/projects/modules-purchase-history")
    (synopsis "Tryton module to historize purchases")
    (description "The @emph{Purchase History} Tryton module activates the
historization of the purchase and adds a revision counter which increases each
time the purchase is reset to draft.")
    (license license:gpl3+)))

(define-public trytond-purchase-invoice-line-standalone
  (package
    (name "trytond-purchase-invoice-line-standalone")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_purchase_invoice_line_standalone" version))
       (sha256
        (base32 "169y69an6i796m8bmp8sanfn0qh7bcws8nangp96q07dsv51wrvb"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "purchase_invoice_line_standalone"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account-invoice-line-standalone
           trytond-purchase))
    (home-page
     "https://docs.tryton.org/projects/modules-purchase-invoice-line-standalone")
    (synopsis "Tryton module for standalone invoice line from purchase")
    (description "The @emph{Purchase Invoice Line Standalone} Tryton module
makes purchase to generate invoice lines instead of invoices.")
    (license license:gpl3+)))

(define-public trytond-purchase-price-list
  (package
    (name "trytond-purchase-price-list")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_purchase_price_list" version))
       (sha256
        (base32 "0xqry794l9vy5v5ck0qqy9yli57av4zzmpv1g8f9hkg7lm9ypg0v"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "purchase_price_list"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-account
           trytond-company
           trytond-party
           trytond-product-price-list
           trytond-purchase))
    (home-page "https://docs.tryton.org/projects/modules-purchase-price-list")
    (synopsis "Tryton module to add price list on purchase")
    (description "The @emph{Purchase Price List} Tryton Module allows price
lists to be defined for suppliers.")
    (license license:gpl3+)))

(define-public trytond-purchase-request
  (package
    (name "trytond-purchase-request")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_purchase_request" version))
       (sha256
        (base32 "0as8lb6bgjigpg926fjfyfy25758m45ihl1xish5vlfcxmccpyn3"))))
    (build-system python-build-system)
    ;; Doctest 'scenario_purchase_request.rst' fails.
    (arguments (tryton-arguments "purchase_request" "--no-doctest"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-product trytond-purchase))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for purchase requests")
    (description
     "This package provides a Tryton module that introduces the concept of
Purchase Requests which are central points to collect purchase requests
generated by other process from Tryton.")
    (license license:gpl3+)))

(define-public python-trytond-purchase-request
  (deprecated-package
   "python-trytond-purchase-request" trytond-purchase-request))

(define-public trytond-purchase-request-quotation
  (package
    (name "trytond-purchase-request-quotation")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_purchase_request_quotation" version))
       (sha256
        (base32 "08kcp88lfn8aa92cd07x5i5xbjznqy0x9lr34f07ky0i26nrnn72"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "purchase_request_quotation"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-purchase-requisition" ,trytond-purchase-requisition)))
    (propagated-inputs
     (list trytond
           trytond-company
           trytond-currency
           trytond-party
           trytond-product
           trytond-purchase-request))
    (home-page
     "https://docs.tryton.org/projects/modules-purchase-request-quotation")
    (synopsis "Tryton module for purchase request quotation")
    (description "The @emph{Purchase Request Quotation} Tryton module allows
users to ask quotations from selected purchase requests to different
suppliers.  Each request will collect quotation information from the
supplier.")
    (license license:gpl3+)))

(define-public trytond-purchase-requisition
  (package
    (name "trytond-purchase-requisition")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_purchase_requisition" version))
       (sha256
        (base32 "0wm4xrxklwd5bbdzlwr5ca4h0zm6jx9pm08mspk15nbvf23qz5n3"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "purchase_requisition"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-company
           trytond-currency
           trytond-party
           trytond-product
           trytond-purchase
           trytond-purchase-request))
    (home-page "https://docs.tryton.org/projects/modules-purchase-requisition")
    (synopsis "Tryton module to enter requests for product
supply (requisition)")
    (description "The @emph{Purchase Requisition} Tryton module allows users
to create their requests for product supply (purchase requisitions).  Those
requisitions will be approved or rejected by the approval group, whoich
typically is the purchasing department.  On approval, purchase requests will
be created.")
    (license license:gpl3+)))

(define-public trytond-purchase-secondary-unit
  (package
    (name "trytond-purchase-secondary-unit")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_purchase_secondary_unit" version))
       (sha256
        (base32 "04fnrim6dimrd63rqbqginlklpih7sb4x3zai5idxjn6hc1l398y"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "purchase_secondary_unit"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-account-invoice-secondary-unit"
        ,trytond-account-invoice-secondary-unit)
       ("trytond-stock-secondary-unit" ,trytond-stock-secondary-unit)))
    (propagated-inputs
     (list trytond trytond-account-invoice trytond-product
           trytond-purchase trytond-stock))
    (home-page
     "https://docs.tryton.org/projects/modules-purchase-secondary-unit")
    (synopsis "Tryton module to add a secondary unit on purchase line")
    (description "The @emph{Purchase Secondary Unit} Tryton module adds a
secondary unit of measure on purchase lines.

The secondary quantity and unit price are kept synchronized with the quantity
and unit price.  The secondary unit is defined on the product supplier or on
the product with its factor against the purchase unit.")
    (license license:gpl3+)))

(define-public trytond-purchase-shipment-cost
  (package
    (name "trytond-purchase-shipment-cost")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_purchase_shipment_cost" version))
       (sha256
        (base32 "1xpkqicv32vrhi89wpn073bc58x6xl189yv0f7h1i9m9q613w9ps"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "purchase_shipment_cost"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-account-invoice-stock" ,trytond-account-invoice-stock)
       ("trytond-account-stock-anglo-saxon" ,trytond-account-stock-anglo-saxon)
       ("trytond-account-stock-continental" ,trytond-account-stock-continental)
       ("trytond-purchase" ,trytond-purchase)))
    (propagated-inputs
     (list trytond trytond-carrier trytond-currency trytond-product
           trytond-stock))
    (home-page
     "https://docs.tryton.org/projects/modules-purchase-shipment-cost")
    (synopsis "Tryton module for purchase shipment costs")
    (description "The @emph{Purchase Shipment Cost} Tryton module adds
shipment costs to Supplier Shipment.")
    (license license:gpl3+)))

(define-public trytond-sale
  (package
    (name "trytond-sale")
    (version "6.2.4")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale" version))
       (sha256
        (base32 "124cx2h93dw61rnavc2q7isjy9008qc379g82myihq9gh4z6rbpr"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-account
           trytond-account-invoice
           trytond-account-invoice-stock
           trytond-account-product
           trytond-company
           trytond-country
           trytond-currency
           trytond-party
           trytond-product
           trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-sale")
    (synopsis "Tryton module for sale")
    (description "The @emph{Sale} Tryton module helps organise and manage
sales made by the company.  It adds the concept of a sale to Tryton and allows
it to be tracked through its states from draft to done.  It also oversees the
creation of customer shipments and invoices for the sales, and allows reports
to be generated that contain aggregated sales figures.")
    (license license:gpl3+)))

(define-public trytond-sale-advance-payment
  (package
    (name "trytond-sale-advance-payment")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_advance_payment" version))
       (sha256
        (base32 "00rlg4jax212qha2w6acris7knj3b17a0rrlm7xyw0bp2vfzgb69"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_advance_payment"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-sale-supply" ,trytond-sale-supply)))
    (propagated-inputs
     (list python-simpleeval trytond trytond-account
           trytond-account-invoice trytond-sale))
    (home-page
     "https://docs.tryton.org/projects/modules-sale-advance-payment")
    (synopsis "Tryton module for sale advance payment")
    (description "The @emph{Sale Advance Payment} Tryton module adds support
for advance payment management on the sale.")
    (license license:gpl3+)))

(define-public trytond-sale-amendment
  (package
    (name "trytond-sale-amendment")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_amendment" version))
       (sha256
        (base32 "0mrnqlgihkvn4z2p1k90c9cha8kqa28ss1ycjzsalxmngnw27hfg"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_amendment"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account-invoice trytond-sale
           trytond-sale-history trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-sale-amendment")
    (synopsis "Tryton module to amend sales")
    (description "The @emph{Sale Amendment} Tryton module allows you to change
sales that are being processed and keep track of the changes.  An amendment is
composed of action lines which can:")
    (license license:gpl3+)))

(define-public trytond-sale-complaint
  (package
    (name "trytond-sale-complaint")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_complaint" version))
       (sha256
        (base32 "172650xyn2k1ay6jd4vy6f71s9rfv8qalfx9j8jz0i4cn320z272"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_complaint"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account-invoice trytond-company trytond-party
           trytond-sale))
    (home-page "https://docs.tryton.org/projects/modules-sale-complaint")
    (synopsis "Tryton module for sale complaints")
    (description "The @emph{Sale Complaint} Tryton module defines the
@code{Complaint} model.")
    (license license:gpl3+)))

(define-public trytond-sale-credit-limit
  (package
    (name "trytond-sale-credit-limit")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_credit_limit" version))
       (sha256
        (base32 "0rx3zi0m4cbpbmjlzkii08424yz68y31nqqkgj6rl9swaqins67h"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_credit_limit"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-account-credit-limit
           trytond-account-invoice
           trytond-company
           trytond-currency
           trytond-sale))
    (home-page "https://docs.tryton.org/projects/modules-sale-credit-limit")
    (synopsis "Tryton module for sale credit limit")
    (description "The @emph{Sale Credit Limit} Tryton module adds confirmed
sale but not yet invoiced to the credit amount of the party and check the
credit limit of the party when confirming a sale.")
    (license license:gpl3+)))

(define-public trytond-sale-discount
  (package
    (name "trytond-sale-discount")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_discount" version))
       (sha256
        (base32 "1kbfbd5rmvaaf5wwvb1akxf7zij1bqpzx2s0dahjxcihxwwra2ib"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_discount"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-product trytond-sale))
    (home-page "https://docs.tryton.org/projects/modules-sale-discount")
    (synopsis "Tryton module that manages discount on sale")
    (description "The @emph{Sale Discount} Tryton module adds discount on sale
line.")
    (license license:gpl3+)))

(define-public trytond-sale-extra
  (package
    (name "trytond-sale-extra")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_extra" version))
       (sha256
        (base32 "0j9ya68p6bfyr2ixh1dqfqnmfa4mn5ayf9hn5pfm2z7nih8bys3r"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_extra"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-company
           trytond-product
           trytond-product-price-list
           trytond-sale
           trytond-sale-price-list))
    (home-page "https://docs.tryton.org/projects/modules-sale-extra")
    (synopsis "Tryton module for sale extra")
    (description "The @emph{Sale Extra} Tryton module allows adding an extra line
on sale based on criteria.")
    (license license:gpl3+)))

(define-public trytond-sale-gift-card
  (package
    (name "trytond-sale-gift-card")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_gift_card" version))
       (sha256
        (base32 "0r395qj178f39lip8mkwhn9lakkh3700hlpcsd208d8wqqqmbf1n"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_gift_card"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-sale-point" ,trytond-sale-point)))
    (propagated-inputs
     (list trytond
           trytond-account
           trytond-account-invoice
           trytond-company
           trytond-product
           trytond-sale
           trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-sale-gift-card")
    (synopsis "Tryton module to manage gift cards")
    (description "The @emph{Sale Gift Card} Tryton module manages the selling
and redeeming of gift cards.")
    (license license:gpl3+)))

(define-public trytond-sale-history
  (package
    (name "trytond-sale-history")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_history" version))
       (sha256
        (base32 "0snjdbhq5mf8j7z6i6yqk3kjl3mpjsdzwnh5bzcnax2n4zrscvxq"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_history"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-sale))
    (home-page "https://docs.tryton.org/projects/modules-sale-history")
    (synopsis "Tryton module to historize sales")
    (description "The @emph{Sale History} Tryton module activates the
historization of the sale and adds a revision counter which increases each
time the sale is reset to draft.")
    (license license:gpl3+)))

(define-public trytond-sale-invoice-grouping
  (package
    (name "trytond-sale-invoice-grouping")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_invoice_grouping" version))
       (sha256
        (base32 "1c70s1lnxzhg6yqv7vjxyqvxp4myh26i9hnnf1k045d6hwf80hvf"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_invoice_grouping"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account-invoice trytond-party trytond-sale))
    (home-page
     "https://docs.tryton.org/projects/modules-sale-invoice-grouping")
    (synopsis "Tryton module to group sale invoices")
    (description "The @emph{Sale Invoice Grouping} Tryton module adds an
option to define how invoice lines generated from sales will be grouped.")
    (license license:gpl3+)))

(define-public trytond-sale-opportunity
  (package
    (name "trytond-sale-opportunity")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_opportunity" version))
       (sha256
        (base32 "05zliwc39zandn7amjzf1n7fqxq7yrwrx5b418ikh09pfz4alq21"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_opportunity"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-account
           trytond-account-invoice
           trytond-company
           trytond-currency
           trytond-party
           trytond-product
           trytond-sale
           trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-sale-opportunity")
    (synopsis "Tryton module with leads and opportunities")
    (description "The @emph{Sale Opportunity} Tryton module defines the
lead/opportunity model.")
    (license license:gpl3+)))

(define-public trytond-sale-payment
  (package
    (name "trytond-sale-payment")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_payment" version))
       (sha256
        (base32 "02zq3smfj55n70kqgipi2q869lp7hlfm0qbw74qx7pina28pipf4"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_payment"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-account-payment-clearing" ,trytond-account-payment-clearing)))
    (propagated-inputs
     (list trytond trytond-account-invoice trytond-account-payment
           trytond-sale))
    (home-page "https://docs.tryton.org/projects/modules-sale-payment")
    (synopsis "Tryton module that manage payments on sale")
    (description "The @emph{Sale Payment} Tryton module extends Sale to allow
payments prior to the creation of any invoice.")
    (license license:gpl3+)))

(define-public trytond-sale-point
  (package
    (name "trytond-sale-point")
    (version "6.2.2")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "trytond_sale_point" version))
              (sha256
               (base32 "0brysadw75rm80yk66wq68gqkyb28zk65sw530fyacx9ma0sq0pj"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "trytond_sale_point"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs (list python-sql
                             trytond
                             trytond-account
                             trytond-account-product
                             trytond-company
                             trytond-party
                             trytond-product
                             trytond-sale
                             trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-sale-point")
    (synopsis "Tryton module for Point of Sales")
    (description "The @emph{Sale Point} Tryton module allows retail sales to
be handled and recorded.")
    (license license:gpl3+)))

(define-public trytond-sale-price-list
  (package
    (name "trytond-sale-price-list")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_price_list" version))
       (sha256
        (base32 "037h107wl3p3ig9w8db2878x80gzdf4dsa9wjrrcxdaz7yp7iwhn"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_price_list"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-company trytond-party
           trytond-product-price-list trytond-sale))
    (home-page "https://docs.tryton.org/projects/modules-sale-price-list")
    (synopsis "Tryton module to add price list on sale")
    (description "The @emph{Sale Price List} Tryton module adds support for
price list on sale.  A price list can be set per party or as default.")
    (license license:gpl3+)))

(define-public trytond-sale-product-customer
  (package
    (name "trytond-sale-product-customer")
    (version "6.2.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_product_customer" version))
       (sha256
        (base32 "01nyhimg00z33zzlxyg8incpfbgcqa7svmzzv5n0x2dafnx5n7wl"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_product_customer"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-sale-amendment" ,trytond-sale-amendment)))
    (propagated-inputs
     (list trytond trytond-product trytond-sale))
    (home-page
     "https://docs.tryton.org/projects/modules-sale-product-customer")
    (synopsis "Tryton module to manage customer product on sale")
    (description "The @emph{Sale Product_Customer} Tryton module defines
customer's names and codes for products or variants.")
    (license license:gpl3+)))

(define-public trytond-sale-promotion
  (package
    (name "trytond-sale-promotion")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_promotion" version))
       (sha256
        (base32 "1nd4f5j25v3g25hr0xr6kqzv0rqavnwkc5wyn8r0if1y9b2scwnc"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_promotion"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-simpleeval
           trytond
           trytond-company
           trytond-product
           trytond-product-price-list
           trytond-sale
           trytond-sale-price-list))
    (home-page "https://docs.tryton.org/projects/modules-sale-promotion")
    (synopsis "Tryton module for sale promotion")
    (description "The @emph{Sale Promotion} module allows applying promotions
on a sale based on criteria.")
    (license license:gpl3+)))

(define-public trytond-sale-promotion-coupon
  (package
    (name "trytond-sale-promotion-coupon")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_promotion_coupon" version))
       (sha256
        (base32 "18086y4xszb5iq6v5ibq3kylzc3b8zbyn6pn6pm61mdbdpqav7mg"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_promotion_coupon"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-sale trytond-sale-promotion))
    (home-page
     "https://docs.tryton.org/projects/modules-sale-promotion-coupon")
    (synopsis "Tryton module for sale promotion coupon")
    (description "The @emph{Sale Promotion Coupon} Tryton module adds coupon
to the promotions.")
    (license license:gpl3+)))

(define-public trytond-sale-secondary-unit
  (package
    (name "trytond-sale-secondary-unit")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_secondary_unit" version))
       (sha256
        (base32 "0as7vc8wp2i3402h5r90zg6170y3av41a6k5ivdfbaxlhsjq8lxa"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_secondary_unit"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-account-invoice-secondary-unit"
        ,trytond-account-invoice-secondary-unit)
       ("trytond-sale-product-customer" ,trytond-sale-product-customer)
       ("trytond-stock-secondary-unit" ,trytond-stock-secondary-unit)))
    (propagated-inputs
     (list trytond trytond-account-invoice trytond-product trytond-sale
           trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-sale-secondary-unit")
    (synopsis "Tryton module to add a secondary unit on sale line")
    (description "The @emph{Sale Secondary Unit} Tryton module adds a
secondary unit of measure on sale lines.  The secondary quantity and unit
price are kept synchronized with the quantity and unit price.  The secondary
unit is defined on the product with its factor against the sale unit.")
    (license license:gpl3+)))

(define-public trytond-sale-shipment-cost
  (package
    (name "trytond-sale-shipment-cost")
    (version "6.2.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_shipment_cost" version))
       (sha256
        (base32 "1r6jcsfxa2q448ks5s23apbj3b35rc5596qk7f3hzwiw6nm168k5"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_shipment_cost"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-sale-promotion" ,trytond-sale-promotion)
       ("trytond-stock-shipment-cost" ,trytond-stock-shipment-cost)))
    (propagated-inputs
     (list trytond
           trytond-account-invoice
           trytond-carrier
           trytond-currency
           trytond-product
           trytond-sale
           trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-sale-shipment-cost")
    (synopsis "Tryton module for sale shipment cost")
    (description "The @emph{Sale Shipment Cost} Tryton module adds shipment
cost for sale.")
    (license license:gpl3+)))

(define-public trytond-sale-shipment-grouping
  (package
    (name "trytond-sale-shipment-grouping")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_shipment_grouping" version))
       (sha256
        (base32 "0v8inxsgdhmkiaj0l3c2gjzbs96qbbxmbw67f14mx9axjvcvkkwy"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_shipment_grouping"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-party trytond-sale trytond-stock))
    (home-page
     "https://docs.tryton.org/projects/modules-sale-shipment-grouping")
    (synopsis "Tryton module to group sale stock moves")
    (description "The @emph{Sale Shipment Grouping} module adds an option to
define how stock moves generated from sales will be grouped.")
    (license license:gpl3+)))

(define-public trytond-sale-shipment-tolerance
  (package
    (name "trytond-sale-shipment-tolerance")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_shipment_tolerance" version))
       (sha256
        (base32 "1vggdhnfg05dad2gmyi49ydhrq3sjqva4shn9zygj8fyjpkppx2y"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_shipment_tolerance"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-sale trytond-stock))
    (home-page
     "https://docs.tryton.org/projects/modules-sale-shipment-tolerance")
    (synopsis "Tryton module to define tolerance for sale shipment")
    (description "The @emph{Sale Shipment Tolerance} module adds under and
over shipment tolerance on the sale.  If the quantity of a sale line is under
shipped but inside the tolerance percentage, then the line will be considered
as fully shipped and no back-order will be created.  If the quantity of a sale
line is over shipped more than the tolerance percentage, then a warning is
raised.")
    (license license:gpl3+)))

(define-public trytond-sale-stock-quantity
  (package
    (name "trytond-sale-stock-quantity")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_stock_quantity" version))
       (sha256
        (base32 "0bn06a752rp16ki5xa0dr3in5xj1hry6020qgz6mji8kxl24v7sv"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_stock_quantity"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-stock-supply" ,trytond-stock-supply)))
    (propagated-inputs
     (list trytond trytond-product trytond-sale trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-sale-stock-quantity")
    (synopsis "Tryton module to add stock warning on sale")
    (description "The @emph{Sale Stock Quantity} Tryton module checks the
stock quantity of the products when quoting a sale.  The check will warn the
user if the forecast quantity at the sale date (and further dates until next
supply) is lower than the quantity sold by considering other sales and the
stock forecasts.")
    (license license:gpl3+)))

(define-public trytond-sale-subscription
  (package
    (name "trytond-sale-subscription")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_subscription" version))
       (sha256
        (base32 "095zdy6031lqffm3yddhsrv93dl2dgqjpbskp539knvd72bdaqdd"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_subscription"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-account
           trytond-account-invoice
           trytond-company
           trytond-currency
           trytond-product
           trytond-sale))
    (home-page "https://docs.tryton.org/projects/modules-sale-subscription")
    (synopsis "Tryton module for subscription")
    (description "The @emph{Sale Subscription} module defines subscription,
services and recurrence rule models.")
    (license license:gpl3+)))

(define-public trytond-sale-subscription-asset
  (package
    (name "trytond-sale-subscription-asset")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_subscription_asset" version))
       (sha256
        (base32 "0bkksk3l3ydxmqglsrrqgwgrak6iwc740vmj0dpw93h4f127haiv"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_subscription_asset"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-sale-subscription trytond-stock-lot))
    (home-page
     "https://docs.tryton.org/projects/modules-sale-subscription-asset")
    (synopsis "Tryton module to handle asset in the sale subscriptions")
    (description "The @emph{Sale Subscription Asset} Tryton module adds the
notion of asset to the sale subscription module.")
    (license license:gpl3+)))

(define-public trytond-sale-supply
  (package
    (name "trytond-sale-supply")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_supply" version))
       (sha256
        (base32 "05ik819spy8jmc5k10mki6kxdjxdqrr4x0g3rgvvlnmadn5igykf"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_supply"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-purchase trytond-purchase-request trytond-sale
           trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-sale-supply")
    (synopsis "Tryton module for sale supply")
    (description "The @emph{Sale Supply} Tryton module adds a \"supply on sale
option\" to purchasable products.  If checked, it will generate a purchase
request for each sale line of this product regardless of the stock levels.
Once the purchased products are received they are assigned on the customer
shipments.  If the purchase is cancelled the sale goes back to the default
supply method.")
    (license license:gpl3+)))

(define-public trytond-sale-supply-drop-shipment
  (package
    (name "trytond-sale-supply-drop-shipment")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_supply_drop_shipment" version))
       (sha256
        (base32 "1i3a8amm3nacc7wis3amr4z9pl47sjzy7gds5qv1xg3fl1awm4ic"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_supply_drop_shipment"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-company
           trytond-product
           trytond-purchase
           trytond-purchase-request
           trytond-sale
           trytond-sale-supply
           trytond-stock))
    (home-page
     "https://docs.tryton.org/projects/modules-sale-supply-drop-shipment")
    (synopsis "Tryton module for sale supply drop shipment")
    (description "The @emph{Sale Supply Drop Shipment} Tryton module adds a
drop shipment option on product supplier if \"supply on request\" is checked.
When checked, the purchase request and the linked purchase have the address of
customer as Delivery Address; at the confirmation of the purchase a drop
shipment is created and linked to both the purchase and the sale.")
    (license license:gpl3+)))

(define-public trytond-sale-supply-production
  (package
    (name "trytond-sale-supply-production")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_sale_supply_production" version))
       (sha256
        (base32 "08ky3mqprlqyksw91mqlb7mjkfpdrgzgnc862wm2q28s0aydn3dv"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "sale_supply_production"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-production trytond-sale-supply))
    (home-page
     "https://docs.tryton.org/projects/modules-sale-supply-production")
    (synopsis "Tryton module to supply sales from production")
    (description "The @emph{Sale Supply Production} Tryton module adds a
\"supply on sale\" option to producible products.  If checked, it will
generate a production request for each sale line of this product regardless of
the stock levels.  Once the products are produced they are assigned to the
customer shipments.  If the production request is cancelled, the sale goes
back to the default supply method.")
    (license license:gpl3+)))

(define-public trytond-stock
  (package
    (name "trytond-stock")
    (version "6.2.7")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock" version))
       (sha256
        (base32 "02klx6qk2vrwiynxcdjnpqx593wr1wjg9sygh5zjzrqqwmjb16yi"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-simpleeval
           trytond
           trytond-company
           trytond-currency
           trytond-party
           trytond-product))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for stock and inventory")
    (description
     "This package provides a Tryton module that defines the fundamentals for
all stock management situations: Locations where products are stored, moves
between these locations, shipments for product arrivals and departures and
inventory to control and update stock levels.")
    (license license:gpl3+)))

(define-public python-trytond-stock
  (deprecated-package "python-trytond-stock" trytond-stock))

(define-public trytond-stock-assign-manual
  (package
    (name "trytond-stock-assign-manual")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_assign_manual" version))
       (sha256
        (base32 "0jn5rbbgmr7jnddrbmy49r2vpfbbfsrgx1bkgjkg687d922lwnrh"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_assign_manual"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-production" ,trytond-production)))
    (propagated-inputs
     (list trytond trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-stock-assign-manual")
    (synopsis "Tryton module to assign manually stock move")
    (description "The @emph{Stock Assign Manual} Tryton module adds a wizard
on shipments and production that allows you to decide from which precise
location to pick products.")
    (license license:gpl3+)))

(define-public trytond-stock-consignment
  (package
    (name "trytond-stock-consignment")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_consignment" version))
       (sha256
        (base32 "0c26gvqmh98hj7zp1kx3q30wdwnvy8j101m9kmsi21j9n2nw7maj"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_consignment"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-stock-supply" ,trytond-stock-supply)))
    (propagated-inputs
     (list trytond
           trytond-account-invoice
           trytond-account-invoice-line-standalone
           trytond-account-invoice-stock
           trytond-product
           trytond-purchase
           trytond-sale
           trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-stock-consignment")
    (synopsis "Tryton module to manage consignment stock")
    (description "The @emph{Stock Consignment} Tryton module allows managing
consignment stock from supplier or at customer warehouse.")
    (license license:gpl3+)))

(define-public trytond-stock-forecast
  (package
    (name "trytond-stock-forecast")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_forecast" version))
       (sha256
        (base32 "19w4q71rm4j0rlsdp6d2ykyjcdkrvq5mjlprsdk6890dmnxm6czx"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_forecast"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-company trytond-product trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-stock-forecast")
    (synopsis "Tryton module with stock forecasts")
    (description "The @emph{Stock Forecast} Tryton module provide a simple way
to create stock moves toward customers with a date in the future.  This allows
other stock mechanisms to anticipate customer demand.")
    (license license:gpl3+)))

(define-public trytond-stock-inventory-location
  (package
    (name "trytond-stock-inventory-location")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_inventory_location" version))
       (sha256
        (base32 "1x35rq6hzxb9wzsflvlsbl1fjgqcp6byrj4rk20fvgbhnv02s4x0"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_inventory_location"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-company trytond-product trytond-stock))
    (home-page
     "https://docs.tryton.org/projects/modules-stock-inventory-location")
    (synopsis "Tryton module to create inventories by locations")
    (description "The @emph{Stock Inventory Location} Tryton module adds a new
wizard \"Create Inventories\" under the \"Inventories\" sub-menu.")
    (license license:gpl3+)))

(define-public trytond-stock-location-move
  (package
    (name "trytond-stock-location-move")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_location_move" version))
       (sha256
        (base32 "07f0xq26wc0vpxf94655gsya3nxsa2xpi6v1c74q5a2qan4gkv9k"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_location_move"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-stock-supply" ,trytond-stock-supply)))
    (propagated-inputs
     (list trytond trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-stock-location-move")
    (synopsis "Tryton module to move storage locations")
    (description "The @emph{Stock Location} move Tryton module allows
defining some Locations as movable
(like palette).")
    (license license:gpl3+)))

(define-public trytond-stock-location-sequence
  (package
    (name "trytond-stock-location-sequence")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_location_sequence" version))
       (sha256
        (base32 "0ab2jf36mmbkg0hrhwrmpjh5m9kpl60mz1gdkb2zhv629z9bxr13"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_location_sequence"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-stock))
    (home-page
     "https://docs.tryton.org/projects/modules-stock-location-sequence")
    (synopsis "Tryton module to add sequence on location")
    (description "The @emph{Stock Location Sequence} Tryton module adds
ordering to location.")
    (license license:gpl3+)))

(define-public trytond-stock-lot
  (package
    (name "trytond-stock-lot")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_lot" version))
       (sha256
        (base32 "0z0ligvgvm2py794sg2ay5r47pm30m890lmfp2jvdr3vjbq3f1a3"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_lot"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-product trytond-stock))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for lot of products")
    (description
     "This package provides a Tryton module that defines lot of products.")
    (license license:gpl3+)))

(define-public python-trytond-stock-lot
  (deprecated-package "python-trytond-stock-lot" trytond-stock-lot))

(define-public trytond-stock-lot-sled
  (package
    (name "trytond-stock-lot-sled")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_lot_sled" version))
       (sha256
        (base32 "14bx84snw6kd896h6gdd825qrg2p7nmm341xl8qvrpn34jq3p2p1"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_lot_sled"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-product trytond-stock trytond-stock-lot))
    (home-page "https://docs.tryton.org/projects/modules-stock-lot-sled")
    (synopsis "Tryton module for shelf life expiration date of product lots")
    (description "The @emph{Stock Lot Sled} Tryton module adds the \"Shelf
Live Expiration Date\" anf \"Expiration Date\" on \"lot of products\".  When
the shelf life of a lot expires in less than the configured shelf life delay,
it is no more used to compute the forecast quantity of the stock.")
    (license license:gpl3+)))

(define-public trytond-stock-lot-unit
  (package
    (name "trytond-stock-lot-unit")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_lot_unit" version))
       (sha256
        (base32 "1m6vbz57y0yrjv4z447gggqgcwd6dzk0hrycv5zvbq4h1kscrh6z"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_lot_unit"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-production" ,trytond-production)))
    (propagated-inputs
     (list trytond trytond-product trytond-stock trytond-stock-lot))
    (home-page "https://docs.tryton.org/projects/modules-stock-lot-unit")
    (synopsis "Tryton module to define unit on stock lot")
    (description "The @emph{Stock Lot Unit} Tryton module allows defining a
unit and quantity on stock lot.")
    (license license:gpl3+)))

(define-public trytond-stock-package
  (package
    (name "trytond-stock-package")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_package" version))
       (sha256
        (base32 "1jy7qz62h29rf10mjr9d9pm6g53ira26m77iccs0cwv3qlrv87rg"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_package"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-company trytond-product trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-stock-package")
    (synopsis "Tryton module for stock packaging")
    (description "The @emph{Stock Package} Tryton module allows storing
packaging information about customer and supplier return shipments.")
    (license license:gpl3+)))

(define-public trytond-stock-package-shipping
  (package
    (name "trytond-stock-package-shipping")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_package_shipping" version))
       (sha256
        (base32 "0j902bvkmfhn353z6dgfbik7jh5yps13jz4dq785rqj2ia5az9iq"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_package_shipping"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-carrier
           trytond-product
           trytond-product-measurements
           trytond-stock
           trytond-stock-package
           trytond-stock-shipment-cost
           trytond-stock-shipment-measurements))
    (home-page
     "https://docs.tryton.org/projects/modules-stock-package-shipping")
    (synopsis "Tryton base module for interacting with shipping services")
    (description "This Tryton module is the Fundamental module required to
interact with shipping service providers.")
    (license license:gpl3+)))

(define-public trytond-stock-package-shipping-dpd
  (package
    (name "trytond-stock-package-shipping-dpd")
    (version "6.2.3")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_package_shipping_dpd" version))
       (sha256
        (base32 "0q7g5qg9j32kn51yigiahd939k2x9gfsnb8k6kinyc9vhq3anbkx"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_package_shipping_dpd"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-pypdf2 trytond trytond-party trytond-product trytond-stock
           trytond-stock-package trytond-stock-package-shipping
           trytond-stock-shipment-measurements python-zeep))
    (home-page
     "https://docs.tryton.org/projects/modules-stock-package-shipping-dpd")
    (synopsis "DPD connector for the Tryton application platform")
    (description "The @emph{Stock Package Shipping DPD} Tryton module allows
you to generate the DPD label using the DPD webservices.  DPD has many
different web services, the module supports:")
    (license license:gpl3+)))

(define-public trytond-stock-package-shipping-mygls
  (package
    (name "trytond-stock-package-shipping-mygls")
    (version "6.2.1")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "trytond_stock_package_shipping_mygls" version))
              (sha256
               (base32 "0pwq720mqv473s5aqib89z5bjdl127l8nqw91prxsna82bm16kv2"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "trytond_stock_package_shipping_mygls"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs (list python-pypdf2
                             trytond
                             trytond-carrier
                             trytond-stock
                             trytond-stock-package
                             trytond-stock-package-shipping
                             python-zeep))
    (home-page "https://docs.tryton.org/projects/modules-stock-package-shipping-mygls")
    (synopsis "MyGLS connector for the Tryton application platform")
    (description "The @emph{Stock Package Shipping MyGLS} Tryton module allows
package labels to be generated for shipments using MyGLS webservices.")
    (license license:gpl3+)))

(define-public trytond-stock-package-shipping-sendcloud
  (package
    (name "trytond-stock-package-shipping-sendcloud")
    (version "6.2.1")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "trytond_stock_package_shipping_sendcloud" version))
              (sha256
               (base32 "1hvlyrdz1nv1l06qrdj1np8yfyip8hhw0l7wbin1rab63hbxa8rf"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "trytond_stock_package_shipping_sendcloud"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs (list python-requests
                             trytond
                             trytond-company
                             trytond-party
                             trytond-product
                             trytond-stock
                             trytond-stock-package
                             trytond-stock-package-shipping
                             trytond-stock-shipment-measurements))
    (home-page
     "https://docs.tryton.org/projects/modules-stock-package-shipping-sendcloud")
    (synopsis "Sendcloud connector for the Tryton application platform")
    (description "The @emph{Stock Package Shipping Sendcloud} Tryton module
allows package labels to be generated for shipments made by any of Sendcloud’s
supported carriers.")
    (license license:gpl3+)))

(define-public trytond-stock-package-shipping-ups
  (package
    (name "trytond-stock-package-shipping-ups")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_package_shipping_ups" version))
       (sha256
        (base32 "198i6fdb9ghcsd7z1cb1f3m261dl9w9hxmzzvs7h51f2lbw07n58"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_package_shipping_ups"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list python-requests
           trytond
           trytond-party
           trytond-product
           trytond-stock
           trytond-stock-package
           trytond-stock-package-shipping
           trytond-stock-shipment-measurements))
    (home-page
     "https://docs.tryton.org/projects/modules-stock-package-shipping-ups")
    (synopsis "UPS connector for the Tryton application plateform")
    (description "The @emph{Stock Package Shipping UPS} Tryton module allows
you to generate the UPS labels per package using the UPS webservices.")
    (license license:gpl3+)))

(define-public trytond-stock-product-location
  (package
    (name "trytond-stock-product-location")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_product_location" version))
       (sha256
        (base32 "18r7j40zdbva8rcxyhianjwb7m30db7qf85709kivvbvbk93rabh"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_product_location"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-production" ,trytond-production)))
    (propagated-inputs
     (list trytond trytond-product trytond-stock))
    (home-page
     "https://docs.tryton.org/projects/modules-stock-product-location")
    (synopsis "Tryton module to add default location on product")
    (description "The @emph{Stock Product Location} Tryton module adds on the
product form a list of preferred location by warehouse.  This list is used
when a supplier shipment is received: the auto-generated Inventory Moves will
use as default destination the preferred locations associated to the current
warehouse.")
    (license license:gpl3+)))

(define-public trytond-stock-quantity-early-planning
  (package
    (name "trytond-stock-quantity-early-planning")
    (version "6.2.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_quantity_early_planning" version))
       (sha256
        (base32 "04fj6h21kl4ab8vl1w9vhnvsxgjg6qd1gxcf1i6r7pfsbhjz8gfj"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_quantity_early_planning"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-production" ,trytond-production)))
    (propagated-inputs
     (list trytond trytond-company trytond-stock))
    (home-page
     "https://docs.tryton.org/projects/modules-stock-quantity-early-planning")
    (synopsis "Tryton module to plan earlier shipments and productions")
    (description "The @emph{Stock Quantity Early Planning} Tryton module helps
reducing stock level by proposing to consume earlier.")
    (license license:gpl3+)))

(define-public trytond-stock-quantity-issue
  (package
    (name "trytond-stock-quantity-issue")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_quantity_issue" version))
       (sha256
        (base32 "0ig2lix5qw8ql1gax8dymwc7advmf9x3xc8djhw5sgb8v0bvknrv"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_quantity_issue"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-production" ,trytond-production)))
    (propagated-inputs
     (list trytond trytond-company trytond-product trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-stock-quantity-issue")
    (synopsis "Tryton module to manage quantity issue with stock")
    (description "The @emph{Stock Quantity Issue} Tryton module helps to solve
stock quantity issues.")
    (license license:gpl3+)))

(define-public trytond-stock-secondary-unit
  (package
    (name "trytond-stock-secondary-unit")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_secondary_unit" version))
       (sha256
        (base32 "0ihhgf4xs5rrf12v9mfj4rpsxjrqfl7schp3r66cdmrm0ccnrj29"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_secondary_unit"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-product trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-stock-secondary-unit")
    (synopsis "Tryton module to add a secondary unit on stock move")
    (description "The @emph{Stock Secondary Unit} Tryton module adds a
secondary unit of measure on the stock move.")
    (license license:gpl3+)))

(define-public trytond-stock-shipment-cost
  (package
    (name "trytond-stock-shipment-cost")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_shipment_cost" version))
       (sha256
        (base32 "0abl4lw0mz7c1chv5c5r3341cqcfz49nw00g9y12kxbxib17h3fc"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_shipment_cost"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-carrier trytond-product trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-stock-shipment-cost")
    (synopsis "Tryton module for stock shipment cost")
    (description "The @emph{Stock Shipment Cost} Tryton Module adds a shipment
cost on the outgoing moves which is calculated from the carrier purchase
price.  This cost is added to the product margin reports.")
    (license license:gpl3+)))

(define-public trytond-stock-shipment-measurements
  (package
    (name "trytond-stock-shipment-measurements")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_shipment_measurements" version))
       (sha256
        (base32 "0a2p3c1780waa779kx24vpknjr9g6z8097ika9kl047xzdnw4n00"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_shipment_measurements"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-stock-package" ,trytond-stock-package)))
    (propagated-inputs
     (list trytond trytond-product trytond-product-measurements
           trytond-stock))
    (home-page
     "https://docs.tryton.org/projects/modules-stock-shipment-measurements")
    (synopsis "Tryton module to add measurements to shipment")
    (description "The @emph{Stock Shipment Measurements} Tryton module adds
weight and volume on shipments and packages.  They are computed using the
measurement and the quantity of their moves.")
    (license license:gpl3+)))

(define-public trytond-stock-split
  (package
    (name "trytond-stock-split")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_split" version))
       (sha256
        (base32 "1gqbkncdg084cxfsq7vc4ikvdajd2akbl2ryi3awh5xs7phrpabf"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_split"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-stock))
    (home-page "https://docs.tryton.org/projects/modules-stock-split")
    (synopsis "Tryton module to split stock move")
    (description "The @emph{Stock Split} Tryton module adds on the stock move
a wizard that allows splitting them.  The move is split into moves of Quantity.
If Counts is set, it will be split only this number of times.  On occasion
there can be a move with the remaining quantity.")
    (license license:gpl3+)))

(define-public trytond-stock-supply
  (package
    (name "trytond-stock-supply")
    (version "6.2.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_supply" version))
       (sha256
        (base32 "1kb6rnb1xk8hnqr9znfpgh8m66590zqbar62xr7094bwaym2ymaa"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_supply"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond
           trytond-account
           trytond-party
           trytond-product
           trytond-purchase
           trytond-purchase-request
           trytond-stock))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for stock supply")
    (description
     "This package provides a Tryton module that adds automatic supply
mechanisms and introduces the concepts of order point.")
    (license license:gpl3+)))

(define-public python-trytond-stock-supply
  (deprecated-package "python-trytond-stock-supply" trytond-stock-supply))

(define-public trytond-stock-supply-day
  (package
    (name "trytond-stock-supply-day")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_supply_day" version))
       (sha256
        (base32 "112xzrzw2k4badync2qd9aanvni43nh86qhrdh754f311km5gh7q"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_supply_day"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-purchase))
    (home-page "https://docs.tryton.org/projects/modules-stock-supply-day")
    (synopsis "Tryton module to add supply weekdays")
    (description "The @emph{Stock Supply Day} Tryton module adds a Week Days
list on the Product Supplier form.  This allows restricting the supply week
days for each supplier on each product.  If no days are defined for a supplier
a supplying may happens at any day of the week.")
    (license license:gpl3+)))

(define-public trytond-stock-supply-forecast
  (package
    (name "trytond-stock-supply-forecast")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_supply_forecast" version))
       (sha256
        (base32 "0b7d8csjcn74086wgm6cydirsl1ygrd9hysd7l4kmd3jz8bb8dzs"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_supply_forecast"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-stock-forecast trytond-stock-supply))
    (home-page
     "https://docs.tryton.org/projects/modules-stock-supply-forecast")
    (synopsis "Tryton module to add forecast to supply computation")
    (description "The @emph{Stock Supply Forecast} Tryton module takes
forecast into account to compute purchase requests.")
    (license license:gpl3+)))

(define-public trytond-stock-supply-production
  (package
    (name "trytond-stock-supply-production")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_supply_production" version))
       (sha256
        (base32 "03cs9g9yfw885ia03x2lxkpjnh919ynizimvvx1jay62i3adk7a2"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_supply_production"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-product trytond-production trytond-stock
           trytond-stock-supply))
    (home-page
     "https://docs.tryton.org/projects/modules-stock-supply-production")
    (synopsis "Tryton module for stock supply of production")
    (description "The @emph{Stock Supply Production} module adds automatic
supply mechanisms via production request.")
    (license license:gpl3+)))

(define-public trytond-timesheet
  (package
    (name "trytond-timesheet")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_timesheet" version))
       (sha256
        (base32 "0lbdb0743mj33vrzrb3fq93d3ksj3395d7q0ivbplp1nn3hrh6sq"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "timesheet"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-company trytond-company-work-time))
    (home-page "https://docs.tryton.org/projects/modules-timesheet")
    (synopsis "Tryton module with timesheets")
    (description "The @emph{Timesheet} Tryton module allows tracking the time
spent by employees on various works.  This module also comes with several
reports that show the time spent by employees on works following various time
periods.")
    (license license:gpl3+)))

(define-public trytond-timesheet-cost
  (package
    (name "trytond-timesheet-cost")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_timesheet_cost" version))
       (sha256
        (base32 "1b1xi7fa371kdsci0naskspvznswb8z8yay7nrzzi8rv622g0cjw"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "timesheet_cost"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-company trytond-party trytond-timesheet))
    (home-page "https://docs.tryton.org/projects/modules-timesheet-cost")
    (synopsis "Tryton module to add cost on timesheet")
    (description "The @emph{Timesheet Cost} Tryton module adds cost price per
employee.")
    (license license:gpl3+)))

(define-public trytond-user-role
  (package
    (name "trytond-user-role")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_user_role" version))
       (sha256
        (base32 "0kx6vqmhny8xjzm2wsy0kf14ybgcdig1cjhyir9b0v11fbavhbw7"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "user_role"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond))
    (home-page "https://docs.tryton.org/projects/modules-user-role")
    (synopsis "Tryton module to manage roles on users")
    (description "This package provides a Tryton module for assigning roles to
user instead of groups.  A Role is defined by a set of groups.  When a role is
added to a user, it overrides the existing groups.  A role can be added to a
user for a period of time only.")
    (license license:gpl3+)))

(define-public trytond-web-shop
  (package
    (name "trytond-web-shop")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_web_shop" version))
       (sha256
        (base32 "182mawahm74lkns2cpy9lrczhllpa8p8np1d7k9agv9kypaqq582"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "web_shop"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-product-attribute" ,trytond-product-attribute)
       ("trytond-product-image" ,trytond-product-image)))
    (propagated-inputs
     (list trytond
           trytond-account
           trytond-company
           trytond-currency
           trytond-product
           trytond-sale
           trytond-stock
           trytond-web-user))
    (home-page "https://docs.tryton.org/projects/modules-web-shop")
    (synopsis "Tryton module that provides a common base for webshops")
    (description "The @emph{Web Shop} Tryton module facilitates storing
configuration of an online web shop.")
    (license license:gpl3+)))

(define-public trytond-web-shop-shopify
  (package
    (name "trytond-web-shop-shopify")
    (version "6.2.2")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "trytond_web_shop_shopify" version))
              (sha256
               (base32 "1nd2wnzr6cibqcsidk0k98iy4vs7dy7crhld60wkbza8pgc23hc4"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "trytond_web_shop_shopify"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs (list python-dateutil
                             python-pyactiveresource
                             python-shopifyapi
                             python-sql
                             trytond
                             trytond-account-payment
                             trytond-currency
                             trytond-party
                             trytond-product
                             trytond-product-attribute
                             trytond-sale
                             trytond-sale-payment
                             trytond-stock
                             trytond-web-shop))
    (home-page "https://docs.tryton.org/projects/modules-web-shop-shopify")
    (synopsis "Integrate Tryton with Shopify")
    (description "The @emph{Web Shop Shopify} Tryton module provides a way to
manage @emph{Shopify} stores.  It uploads products, variants and collections
to Shopify, and downloads orders, transactions and creates fulfilments.")
    (license license:gpl3+)))

(define-public trytond-web-shop-vue-storefront
  (package
    (name "trytond-web-shop-vue-storefront")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_web_shop_vue_storefront" version))
       (sha256
        (base32 "18rc77crfdckzxcz5wryqk0iqccm3mx2a6b956274643sa8kbhvs"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "web_shop_vue_storefront"))
    (native-inputs
     `(,@(%standard-trytond-native-inputs)
       ("trytond-carrier" ,trytond-carrier)
       ("trytond-product-attribute" ,trytond-product-attribute)
       ("trytond-product-image" ,trytond-product-image)
       ("trytond-sale-promotion-coupon" ,trytond-sale-promotion-coupon)
       ("trytond-sale-shipment-cost" ,trytond-sale-shipment-cost)
       ("trytond-stock-shipment-cost" ,trytond-stock-shipment-cost)))
    (propagated-inputs
     (list python-elasticsearch
           python-stdnum
           trytond
           trytond-party
           trytond-product
           trytond-sale
           trytond-web-shop
           trytond-web-user))
    (home-page
     "https://docs.tryton.org/projects/modules-web-shop-vue-storefront")
    (synopsis "Tryton module to integrate with Vue Storefront")
    (description "This Tryton module provides the back-end to integrate with
Vue Storefront 1.x.")
    (license license:gpl3+)))

(define-public trytond-web-shop-vue-storefront-stripe
  (package
    (name "trytond-web-shop-vue-storefront-stripe")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_web_shop_vue_storefront_stripe" version))
       (sha256
        (base32 "0qzcflcrkd35da9vb9gl9mnxg7dis1sz9kp9hb6hbnmyjbhdz17k"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "web_shop_vue_storefront_stripe"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-account-payment-stripe trytond-sale-payment
           trytond-web-shop trytond-web-shop-vue-storefront))
    (home-page
     "https://docs.tryton.org/projects/modules-web-shop-vue-storefront-stripe")
    (synopsis "Tryton module to support Stripe payment with Vue Storefront")
    (description "The @emph{Web Shop Vue Storefront Stripe} Tryton module
provides support of Stripe payment for Vue Storefront integration.")
    (license license:gpl3+)))

(define-public trytond-web-shortener
  (package
    (name "trytond-web-shortener")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_web_shortener" version))
       (sha256
        (base32 "0mjcp97f5dh6lzgw4yhd7k01jlmaga1jvsc07as1snz9y7r06kpk"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "web_shortener"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond))
    (home-page "https://docs.tryton.org/projects/modules-web-shortener")
    (synopsis "Tryton module to plug a URL to an action")
    (description "The @emph{Web Shortener} Tryton module allows URLs to be
shortened.  It also counts the number of times the URL is accessed and
optionally triggers action.")
    (license license:gpl3+)))

(define-public trytond-web-user
  (package
    (name "trytond-web-user")
    (version "6.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_web_user" version))
       (sha256
        (base32 "04b3mb4kxibz073746c90i9k4gsc3vnnk47fcn4wqj2b2wq6smng"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "web_user"))
    (native-inputs (%standard-trytond-native-inputs))
    (propagated-inputs
     (list trytond trytond-party))
    (home-page "https://docs.tryton.org/projects/modules-web-user")
    (synopsis "Tryton module to manage Web users")
    (description "The @emph{Web User} Tryton module provides facilities to
manage external user accessing from the web.")
    (license license:gpl3+)))
