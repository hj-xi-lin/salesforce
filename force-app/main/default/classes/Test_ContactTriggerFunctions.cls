@isTest
public class Test_ContactTriggerFunctions {
    
    @isTest static void testcallingBackendForAccess(){
        
        Test.startTest();
        Account acc = new Account();
        acc.Name = 'Test Acc';
        //acc.Umbrella_Company__c = true;
        acc.NumberOfEmployees = 2500;
        acc.Service_Country__c = 'DE';
        insert acc;
        
        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName = 'Contact';
        con.Email = 'testuser@salesforce.de';
        con.AccountId = acc.Id;
        con.Timestamp_SSSU__c = System.today();
        insert con;
        
        con.Backend_access_enabled__c = true;
        update con;
        
        Test.stopTest();
    }

}