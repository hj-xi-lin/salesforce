@isTest
public class ConvertLeadTest {
    
    Static Lead lead = new Lead(
        LastName = 'test',
        Email = 'test.test@test.com',
        Category_1__c = 'Service Provider',
        Category_2__c = 'Health',
        Category_3__c = 'Hospitals',
        HeyJobs_Category__c = 'Healthcare',
        Demo_Date__c = Date.today(),
        LeadSource = 'Outbound',
        Status = 'Not researched yet',
        City = 'Berlin',
        Country = 'Deutschland',
        Service_Country__c ='DE',
        Street= 'test',
        PostalCode = '10666',
        NumberOfEmployees = 50,
        urlCareerPage__c = 'test@test.com',
        Company = 'test'
        
    );
        
        
    
    
    static testMethod void testLeadCon() {   
        
        insert lead;
        ApexPages.StandardController sc = new ApexPages.StandardController(lead);
        ConvertLead testCTRL = new ConvertLead(sc);
        testCTRL.save();
        
    }
}