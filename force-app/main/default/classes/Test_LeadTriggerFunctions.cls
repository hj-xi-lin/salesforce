@isTest
public class Test_LeadTriggerFunctions {
    
    @isTest static void test_domainMatchUpdates() { 
        List<Lead> leadList = new List<Lead>();
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Service_Country__c = 'AT';
        acc.txtEmailDomain__c = 'demonte.com';
        insert acc;
        
        Lead ld = new Lead(
            LastName = 'test',
            Email = 'sample@wagner.com',
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
            Timestamp_SSSU_lead__c = Date.today(),
            Timestamp_SSSU_HS_Workflow_completed__c = System.now(),
            Service_Country__c = 'AT'
        );
        leadList.add(ld);
        
        Lead ld1 = new Lead(
            LastName = 'test',
            Email = 'sample@demonte.com',
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
            Timestamp_SSSU_lead__c = Date.today(),
            Timestamp_SSSU_HS_Workflow_completed__c = System.now(),
            Service_Country__c = 'AT'
        );
        leadList.add(ld1); 
        
        insert leadList;
 
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
        
        
        Test.startTest();
        HttpMock mock = new HttpMock();
        mock.setMock('{"response": "test"}', 200);
        
        // Set the mock response to the mock HTTP callout
        Test.setMock(HttpCalloutMock.class, mock);
        LeadTriggerFunctions.checkEmailDomainMatch(leadList);
        LeadTriggerFunctions.createSSSUDuplicateCase(leadList);
        ld.Timestamp_SSSU_lead__c = Date.Today() -1;
        update ld;
        Test.stopTest();
    }
    
    private class HttpMock implements HttpCalloutMock {
        private String responseBody;
        private Integer responseStatus;
        
        public void setMock(String responseBody, Integer responseStatus) {
            this.responseBody = responseBody;
            this.responseStatus = responseStatus;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setBody(responseBody);
            res.setStatus(String.valueOf(responseStatus));
            return res;
        }
    }
}