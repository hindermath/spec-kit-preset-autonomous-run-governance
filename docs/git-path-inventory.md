# Git-Dateiinventar / Git path inventory

Documentation Impact: **UpdateRequired**. Owner: Thorsten Hindermann.

## Deutsch

Der Delivery-Validator muss die tatsächlichen Git-Dateinamen prüfen. Zeilenweise
Ausgabe kann Namen mit Tabs, Zeilenumbrüchen oder Nicht-ASCII-Zeichen gequotet
liefern. Ein solcher Ausgabetext ist kein Dateipfad. Die bisherige
Worktree-Prüfung konnte dadurch eine vorhandene Datei überspringen und trotz
unerlaubter nachgestellter Leerzeichen `Pass` melden. Dies bestand bereits im
veröffentlichten v0.4.7; es ist keine erst in v0.4.9 eingeführte Regression.

Die Quellenkorrektur liest geänderte und ungetrackte Namen mit `-z` als Bytes.
Erst nach der NUL-Trennung wird der jeweilige Name für das Dateisystem dekodiert.
Auch die Staged-Statusliste verwendet diesen Weg, damit Textmodus keine
Wagenrückläufe in Dateinamen verändert. Unvollständige Inventare werden abgelehnt.
Inhaltsregeln, historische Rohhash-Ausnahmen und Dateimodus-Prüfungen bleiben
verbindlich; ungewöhnliche Namen sind keine Ausnahme von der Inhaltsprüfung.

Die bestehenden Bash-/PowerShell-Regressionen prüfen gewöhnliche, Leerzeichen-
und Unicode-Namen auf allen Plattformen. POSIX-Systeme prüfen zusätzlich Tab,
LF, CR und Anführungszeichen; Windows verbietet diese Zeichen in Dateinamen.
Für jeden Namen werden fehlerhafte Inhalte im Worktree, Index und in ausdrücklich
benannten ungetrackten Dateien abgelehnt. Gültige Dateien müssen im Prüfbericht
unter ihrem exakten Namen erscheinen.

Kanonische Quellen: `scripts/autonomous-evidence-core.py` und
`tests/test-autonomous-evidence-integrity.ps1`. Leserpfad: README → dieser
Nachweis → Delivery-Validator. Zielgruppe: Preset-Maintainer und Nutzende des
Delivery-Gates. Textorientierte Ausgabe und gleichwertiges Englisch bleiben
erhalten. Distribution: nur Preset-Quelle; keine Installation, kein Home-Sync
oder Rollout. Die veröffentlichten Tags bleiben unverändert. Neu bewerten bei
Git-Inventar-, Pfad-, Encoding- oder Plattformänderungen. Eine Patch-Veröffentlichung
und erneute Consumer-Prüfung bleiben getrennte Schritte.

## English

The delivery validator must check actual Git paths. Line-oriented output may
quote names containing tabs, newlines or non-ASCII characters. Such display
text is not a filesystem path. The previous Worktree check could skip a real
file and report `Pass` despite forbidden trailing whitespace. This already
existed in released v0.4.7; it was not introduced in v0.4.9.

The source correction reads changed and untracked names as NUL-delimited bytes,
decoding each filesystem name only after splitting. The staged status inventory
uses the same path to preserve carriage returns otherwise translated by text
mode. Incomplete inventories fail closed. Content rules, exact historical raw
hash allowances and file-mode checks remain enforced.

Existing Bash/PowerShell regressions test ordinary, space and Unicode names on
all platforms. POSIX also tests tab, LF, CR and quote characters, which Windows
forbids in filenames. Bad content is rejected in Worktree, Staged and explicitly
intended untracked files. Valid reports must preserve each exact name.

Canonical sources and reader navigation are listed above. Audiences are preset
maintainers and delivery-gate users. Text-oriented output and equivalent
languages are retained. Distribution is preset source only: no installation,
Home sync or rollout. Published tags stay unchanged. Re-evaluate on Git inventory,
path, encoding or platform changes. Patch publication and consumer verification
remain separate steps.
