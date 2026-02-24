@isTest
private class BatchPopulateRechtsformTest {

    @TestSetup
    static void setup() {
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name = 'Mustermann GmbH'));
        accounts.add(new Account(Name = 'Deutsche Bank AG'));
        accounts.add(new Account(Name = 'Zalando SE'));
        accounts.add(new Account(Name = 'Schmidt & Co. KG'));
        accounts.add(new Account(Name = 'Bäckerei Müller e.K.'));
        accounts.add(new Account(Name = 'Test Company Ltd.'));
        accounts.add(new Account(Name = 'Random Name Without Legal Form'));
        accounts.add(new Account(Name = 'Sportverein Adler e.V.'));
        accounts.add(new Account(Name = 'Meine UG (haftungsbeschränkt)'));
        accounts.add(new Account(Name = 'Henkel KGaA'));
        accounts.add(new Account(Name = 'Volksbank Mitte eG'));
        accounts.add(new Account(Name = 'Caritas gGmbH'));
        accounts.add(new Account(Name = 'Arzt Praxis PartG'));
        accounts.add(new Account(Name = 'Tech Inc.'));
        accounts.add(new Account(Name = 'Raiffeisen B.V.'));
        accounts.add(new Account(Name = 'Meier OHG'));
        accounts.add(new Account(Name = 'Weber GbR'));
        accounts.add(new Account(Name = 'Stiftung Warentest'));
        insert accounts;
    }

    @isTest
    static void testBatchRun() {
        Test.startTest();
        BatchPopulateRechtsform batch = new BatchPopulateRechtsform();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify results
        Map<String, String> expected = new Map<String, String>{
            'Mustermann GmbH' => 'GmbH',
            'Deutsche Bank AG' => 'AG',
            'Zalando SE' => 'Societas Europaea (SE)',
            'Schmidt & Co. KG' => 'GmbH & Co. KG',
            'Bäckerei Müller e.K.' => 'Einzelkaufmann (e.K.)',
            'Test Company Ltd.' => 'Limited (Ltd.)',
            'Sportverein Adler e.V.' => 'e.V. (Verein)',
            'Meine UG (haftungsbeschränkt)' => 'UG (haftungsbeschränkt)',
            'Henkel KGaA' => 'KGaA',
            'Volksbank Mitte eG' => 'eG (Genossenschaft)',
            'Caritas gGmbH' => 'gGmbH',
            'Arzt Praxis PartG' => 'Partnerschaftsgesellschaft (PartG)',
            'Tech Inc.' => 'Incorporated (Inc.)',
            'Raiffeisen B.V.' => 'B.V.',
            'Meier OHG' => 'OHG',
            'Weber GbR' => 'GbR',
            'Stiftung Warentest' => 'Stiftung'
        };

        List<Account> results = [SELECT Name, Rechtsform__c FROM Account];
        for (Account acc : results) {
            if (expected.containsKey(acc.Name)) {
                System.assertEquals(expected.get(acc.Name), acc.Rechtsform__c,
                    'Rechtsform mismatch for: ' + acc.Name);
            } else if (acc.Name == 'Random Name Without Legal Form') {
                System.assertEquals(null, acc.Rechtsform__c,
                    'Should be null for account without legal form');
            }
        }
    }

    @isTest
    static void testBatchOverwrite() {
        // Set a value first
        Account acc = [SELECT Id, Name, Rechtsform__c FROM Account WHERE Name = 'Mustermann GmbH' LIMIT 1];
        acc.Rechtsform__c = 'Sonstige';
        update acc;

        Test.startTest();
        // Run with overwrite = true
        BatchPopulateRechtsform batch = new BatchPopulateRechtsform(true);
        Database.executeBatch(batch, 200);
        Test.stopTest();

        acc = [SELECT Rechtsform__c FROM Account WHERE Name = 'Mustermann GmbH' LIMIT 1];
        System.assertEquals('GmbH', acc.Rechtsform__c, 'Should overwrite existing value');
    }

    @isTest
    static void testDetectRechtsformDirectly() {
        BatchPopulateRechtsform batch = new BatchPopulateRechtsform();

        // Compound forms
        System.assertEquals('GmbH & Co. KG', batch.detectRechtsform('Meier GmbH & Co. KG'));
        System.assertEquals('GmbH & Co. KG', batch.detectRechtsform('Fischer GmbH & Co KG'));

        // KGaA before AG
        System.assertEquals('KGaA', batch.detectRechtsform('Henkel KGaA'));

        // gGmbH before GmbH
        System.assertEquals('gGmbH', batch.detectRechtsform('Caritas gGmbH'));

        // Null for unrecognized
        System.assertEquals(null, batch.detectRechtsform('Just a random name'));
        System.assertEquals(null, batch.detectRechtsform(null));
        System.assertEquals(null, batch.detectRechtsform(''));
    }
}