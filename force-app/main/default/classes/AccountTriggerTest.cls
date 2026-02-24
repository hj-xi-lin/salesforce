@isTest
public Class AccountTriggerTest
{    
    Static Account a = new Account(
        Name ='Foo',
        NumberOfEmployees = 2500,
        Service_Country__c = 'DE'
        
    );
    @isTest    
    public static void TestAccount() {
        insert a;
    }
    
    // Gagan
    @isTest static void test_validateUmbrellaCompany() {
        Test.startTest();
        Account acc = new Account();
        acc.Name = 'Test Acc';
        acc.Umbrella_Company__c = true;
        acc.NumberOfEmployees = 2500;
        //acc.Service_Country__c = 'DE';
        insert acc;
        
        /*Id recTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.CloseDate = Date.today().addDays(5);
        opp.StageName = 'Scheduling';
        opp.AccountId = acc.id;
        opp.RecordTypeId = recTypeId;
        insert opp;*/
        Test.stopTest();
    }
}