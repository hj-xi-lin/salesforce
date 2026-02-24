@isTest
public class Test_selfserviceLeadConversion {

    @isTest static void testConvertLead() {        
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Service_Country__c = 'AT';
        insert acc;
        
        List<Lead> leadList = new List<Lead>();
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
            Service_Country__c = 'AT',
            Timestamp_SSSU_lead__c = Date.today(),
            Timestamp_SSSU_HS_Workflow_completed__c = System.now(),
            Conversion_Trigger__c = false
        );
        leadList.add(ld);
        
        Lead ld1 = new Lead(
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
            Timestamp_SSSU_lead__c = Date.today(),
            Timestamp_SSSU_HS_Workflow_completed__c = System.now(),
            Conversion_Trigger__c = false,
            Existing_Account_Name__c = acc.Id
        );
        leadList.add(ld1);
        insert leadList;
        
        Test.startTest();
         // Create a mock response for the HTTP callout
        HttpMock mock = new HttpMock();
        mock.setMock('{"response": "test"}', 200);
        
        // Set the mock response to the mock HTTP callout
        Test.setMock(HttpCalloutMock.class, mock);
        
        List<Lead> testLead = new List<Lead>([SELECT Id, Conversion_Trigger__c, Existing_Account_Name__c FROM Lead WHERE Timestamp_SSSU_lead__c = TODAY]);
        List<Account> testAccount = new List<Account>([SELECT Id FROM Account LIMIT 1]);
        
        for(Lead tld : testLead){
            tld.Existing_Account_Name__c = testAccount[0].Id;
        	tld.Conversion_Trigger__c = true;
        }
        update testLead;
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
    
    @isTest static void test_processLeadConversionOutput(){
        
        List<Lead> leadList = new List<Lead>();
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
            Service_Country__c = 'AT',
            Timestamp_SSSU_lead__c = Date.today(),
            Timestamp_SSSU_HS_Workflow_completed__c = System.now(),
            Conversion_Trigger__c = false
        );
        leadList.add(ld);
        insert leadList;
        
        Test.startTest();
        //List<Database.LeadConvertResult> lcr = Database.convertLead(leadList);
        //selfserviceLeadConversion.processLeadConversionOutput(lcr);
        //Create a mock response for the HTTP callout
        HttpMock mock = new HttpMock();
        mock.setMock('{"response": "test"}', 200);
        
        // Set the mock response to the mock HTTP callout
        Test.setMock(HttpCalloutMock.class, mock);
        selfserviceLeadConversion.convertLead(leadList);
        Test.stopTest();
        
    }
    
    @isTest static void test_initiateCustomLeadConversion(){
        
        List<Lead> leadList = new List<Lead>();
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
            Service_Country__c = 'AT',
            Timestamp_SSSU_lead__c = Date.today(),
            Timestamp_SSSU_HS_Workflow_completed__c = System.now(),
            Conversion_Trigger__c = false
        );
        leadList.add(ld);
        insert leadList;
        
        Map<Id,Lead> oldLeadMap = new Map<Id, Lead>();
        for(Lead lead1 : leadList){
            oldLeadMap.put(lead1.Id, lead1);
        }
        
        Test.startTest();
        //Create a mock response for the HTTP callout
        HttpMock mock = new HttpMock();
        mock.setMock('{"response": "test"}', 200);
        
        // Set the mock response to the mock HTTP callout
        Test.setMock(HttpCalloutMock.class, mock);
        leadList[0].Conversion_Trigger__c = True;
        update leadList;
        selfserviceLeadConversion.initiateCustomLeadConversion(leadList,oldLeadMap);
        Test.stopTest();
        
    }
}