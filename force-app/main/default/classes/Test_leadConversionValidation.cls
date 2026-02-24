@isTest
public class Test_leadConversionValidation {
    @isTest static void testOne() {        
        Lead ld = new Lead(
            LastName = 'test',
            Email = 'test.test@test.com',
            Category_1__c = 'Service Provider',
            Category_2__c = 'Health',
            Category_3__c = 'Hospitals',
            Demo_Date__c = Date.today(),
            HeyJobs_Category__c = 'Agency',
            LeadSource = 'Outbound',
            Status = 'Not researched yet',
            City = 'Berlin',
            Country = 'Deutschland',
            Street= 'test',
            PostalCode = '10666',
            NumberOfEmployees = 50,
            urlCareerPage__c = 'test@test.com',
            Company = 'test',
            Service_Country__c = 'AT'
        );
        insert ld;
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Service_Country__c = 'AT';
        insert acc;
        
        contact con = new contact();
        con.lastname = 'Test Con';
        con.AccountId = acc.id;
        insert con;
        
        Id recTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.CloseDate = Date.today().addDays(5);
        opp.StageName = 'Scheduling';
        opp.AccountId = acc.id;
        opp.RecordTypeId = recTypeId;
        insert opp;
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        
        Test.startTest();
        Database.LeadConvert lc = new database.LeadConvert();  
        lc.setLeadId(ld.Id);
        lc.setAccountId(acc.id);
        lc.setContactId(con.id);
        lc.setOpportunityId(opp.id);  
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);  
        Test.stopTest();
        system.assertEquals(true, lcr.isSuccess());
    }
}