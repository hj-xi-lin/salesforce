/**
 * Batch Apex to populate Rechtsform__c on Account based on Account Name pattern matching.
 *
 * Usage:
 *   Database.executeBatch(new BatchPopulateRechtsform(), 200);
 *
 * To re-run for all accounts (overwrite existing values):
 *   Database.executeBatch(new BatchPopulateRechtsform(true), 200);
 */
global class BatchPopulateRechtsform implements Database.Batchable<SObject>, Database.Stateful {

    private Boolean overwriteExisting;
    global Integer recordsProcessed = 0;
    global Integer recordsUpdated = 0;

    global BatchPopulateRechtsform() {
        this.overwriteExisting = false;
    }

    global BatchPopulateRechtsform(Boolean overwriteExisting) {
        this.overwriteExisting = overwriteExisting;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (overwriteExisting) {
            return Database.getQueryLocator([
                SELECT Id, Name, Rechtsform__c FROM Account
            ]);
        } else {
            return Database.getQueryLocator([
                SELECT Id, Name, Rechtsform__c FROM Account WHERE Rechtsform__c = null
            ]);
        }
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Account> toUpdate = new List<Account>();

        for (Account acc : scope) {
            recordsProcessed++;
            String rechtsform = detectRechtsform(acc.Name);
            if (rechtsform != null) {
                acc.Rechtsform__c = rechtsform;
                toUpdate.add(acc);
            }
        }

        if (!toUpdate.isEmpty()) {
            recordsUpdated += toUpdate.size();
            update toUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('BatchPopulateRechtsform finished.');
        System.debug('Records processed: ' + recordsProcessed);
        System.debug('Records updated: ' + recordsUpdated);
    }

    /**
     * Detect the Rechtsform from the Account name.
     * Order matters: more specific / compound forms are checked first.
     */
    @TestVisible
    private String detectRechtsform(String name) {
        if (String.isBlank(name)) {
            return null;
        }

        // Normalize: trim and prepare for matching
        String n = name.trim();
        // Uppercase version for case-insensitive short-abbreviation checks
        String upper = n.toUpperCase();

        // ──────────────────────────────────────
        // 1. Compound forms (most specific first)
        // ──────────────────────────────────────
        if (n.containsIgnoreCase('GmbH & Co. KG')
            || n.containsIgnoreCase('GmbH & Co KG')
            || n.containsIgnoreCase('GmbH &Co. KG')
            || n.containsIgnoreCase('GmbH& Co. KG')
            || n.containsIgnoreCase('GmbH+Co. KG')
            || n.containsIgnoreCase('GmbH u. Co. KG')) {
            return 'GmbH & Co. KG';
        }

        // Also catch "& Co. KG" without explicit GmbH prefix (e.g. "AG & Co. KG")
        if (n.containsIgnoreCase('& Co. KG') || n.containsIgnoreCase('& Co KG')) {
            return 'GmbH & Co. KG';
        }

        // ──────────────────────────────────────
        // 2. German forms - specific abbreviations
        // ──────────────────────────────────────

        // KGaA (before AG and KG)
        if (n.containsIgnoreCase('KGaA') || upper.contains('KGAA')) {
            return 'KGaA';
        }

        // gGmbH (gemeinnuetzige GmbH, before GmbH)
        if (n.contains('gGmbH') || n.contains('GGMBH') || n.contains('ggmbh')
            || n.containsIgnoreCase('gemeinnützige GmbH')
            || n.containsIgnoreCase('gemeinnuetzige GmbH')) {
            return 'gGmbH';
        }

        // GmbH (catches most variations)
        if (n.containsIgnoreCase('GmbH') || n.containsIgnoreCase('mbH')) {
            return 'GmbH';
        }

        // UG (haftungsbeschraenkt)
        if (n.containsIgnoreCase('UG (haftungsbeschränkt)')
            || n.containsIgnoreCase('UG (haftungsbeschraenkt)')
            || n.containsIgnoreCase('UG(haftungsbeschränkt)')
            || endsWithWord(upper, 'UG')
            || containsWord(upper, 'UG')) {
            return 'UG (haftungsbeschränkt)';
        }

        // e.K. / Einzelkaufmann
        if (n.contains('e.K.') || n.contains('e. K.')
            || n.containsIgnoreCase('e.Kfm')
            || n.containsIgnoreCase('e.Kfr')
            || endsWithWord(n, 'eK')
            || containsWord(n, 'eK')) {
            return 'Einzelkaufmann (e.K.)';
        }

        // OHG
        if (n.containsIgnoreCase('OHG')) {
            return 'OHG';
        }

        // e.V. / Verein
        if (n.contains('e.V.') || n.contains('e. V.')
            || n.contains('e.V')
            || endsWithWord(n, 'eV')
            || containsWord(n, 'eV')) {
            return 'e.V. (Verein)';
        }

        // eG / Genossenschaft
        if (n.contains(' eG ') || n.endsWith(' eG')
            || n.contains(' e.G.') || n.contains(' e. G.')
            || n.containsIgnoreCase('Genossenschaft')
            || n.endsWith(' eG.')) {
            return 'eG (Genossenschaft)';
        }

        // GbR
        if (n.containsIgnoreCase('GbR')) {
            return 'GbR';
        }

        // PartG / Partnerschaftsgesellschaft
        if (n.containsIgnoreCase('PartG') || n.containsIgnoreCase('Partnerschaftsgesellschaft')
            || n.containsIgnoreCase('PartmbB') || n.containsIgnoreCase('Part mbB')) {
            return 'Partnerschaftsgesellschaft (PartG)';
        }

        // EWIV
        if (upper.contains('EWIV')) {
            return 'EWIV';
        }

        // Stiftung
        if (n.containsIgnoreCase('Stiftung')) {
            return 'Stiftung';
        }

        // SE (Societas Europaea) - short, needs word boundary
        if (endsWithWord(upper, 'SE') || containsWord(upper, 'SE')) {
            return 'Societas Europaea (SE)';
        }

        // AG - short, needs word boundary
        if (endsWithWord(upper, 'AG') || containsWord(upper, 'AG')) {
            return 'AG';
        }

        // KG - after all compound KG forms
        if (endsWithWord(upper, 'KG') || containsWord(upper, 'KG')) {
            return 'KG';
        }

        // ──────────────────────────────────────
        // 3. International forms
        // ──────────────────────────────────────

        if (n.containsIgnoreCase('Limited') || n.containsIgnoreCase('Ltd.') || n.containsIgnoreCase(' Ltd')
            || n.containsIgnoreCase('Pty Ltd')) {
            return 'Limited (Ltd.)';
        }

        if (n.containsIgnoreCase('Incorporated') || n.containsIgnoreCase('Inc.')) {
            return 'Incorporated (Inc.)';
        }

        if (n.containsIgnoreCase('Corporation') || n.containsIgnoreCase('Corp.') || n.containsIgnoreCase(' Corp')) {
            return 'Corporation (Corp.)';
        }

        if (n.contains('S.A.') || n.contains(' S.A') || n.contains(' SA ')
            || endsWithWord(upper, 'SA')) {
            return 'S.A.';
        }

        if (n.contains('B.V.') || n.contains(' B.V') || n.contains(' BV ')
            || endsWithWord(upper, 'BV')) {
            return 'B.V.';
        }

        if (n.contains('S.r.l') || n.contains('S.R.L') || n.contains('Srl') || n.contains('SRL')) {
            return 'S.r.l.';
        }

        // No match
        return null;
    }

    /**
     * Check if name ends with the given word (preceded by a space).
     */
    private Boolean endsWithWord(String name, String word) {
        return name.endsWith(' ' + word);
    }

    /**
     * Check if name contains the given word surrounded by spaces or followed by punctuation.
     */
    private Boolean containsWord(String name, String word) {
        return name.contains(' ' + word + ' ')
            || name.contains(' ' + word + ',')
            || name.contains(' ' + word + '.')
            || name.contains(' ' + word + '-')
            || name.contains(' ' + word + '(')
            || name.contains(' ' + word + ')')
            || name.contains(' ' + word + '/');
    }
}