@isTest
public class Test_MQLConversionFunction {

    @isTest static void testConvertLeadOnInsert() {        
        List<Lead> leadList = new List<Lead>();
        Lead ld = new Lead(
            FirstName = 'Andy',
            LastName = 'Cooper',
            Email = 'a.cooper@planetearth.de',
            Category_1__c = 'Service Provider',
            Category_2__c = 'Health',
            Category_3__c = 'Hospitals',
            Demo_Date__c = Date.today(),
            HeyJobs_Category__c = 'Agency',
            LeadSource = 'Outbound',
            Status = 'Not researched yet',
            City = 'Berlin',
            Country = 'Deutschland',
            Street= 'Sponholzstrasse',
            PostalCode = '10612',
            NumberOfEmployees = 80,
            urlCareerPage__c = 'planetearth.de',
            Company = 'Planet Earth',
            Service_Country__c = 'AT',
            MQL_Type_Lead__c = 'Type 1',
            Timestamp_Latest_MQL_Conversion__c = DateTime.now().addDays(-1)
        );
        leadList.add(ld);
        
        Test.startTest();
        insert leadList;        
        Test.stopTest();
    }
    
    @isTest static void testConvertLeadOnUpdate() {        
        List<Lead> leadList = new List<Lead>();
        Lead ld = new Lead(
            FirstName = 'William',
            LastName = 'Samson',
            Email = 'w.samson@samplers.de',
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
            PostalCode = '10066',
            NumberOfEmployees = 70,
            urlCareerPage__c = 'samplers.de',
            Company = 'Samplers',
            Service_Country__c = 'AT',
            MQL_Type_Lead__c = 'Type 3',
            Engagement_Score__c = 50,
            Timestamp_Latest_MQL_Conversion__c = DateTime.now().addDays(-2)
        );
        leadList.add(ld);
        
        Test.startTest();
        insert leadList;
        // Updating the engagement score
        List<Lead> updatedLeadList = new List<Lead>([SELECT Engagement_Score__c FROM Lead WHERE MQL_Type_Lead__c = 'Type 3']);
        for(Lead tld : updatedLeadList){
            tld.Engagement_Score__c = 150;
            tld.Timestamp_Latest_MQL_Conversion__c = DateTime.now();
        }
        update updatedLeadList;
        Test.stopTest();
    }
    
    @isTest static void testTimestampLatestMQLConversion() {
        List<Lead> leadList = new List<Lead>();
        Lead ld = new Lead(
            FirstName = 'Alex',
            LastName = 'Johnson',
            Email = 'a.johnson@innovation.de',
            Category_1__c = 'Service Provider',
            Category_2__c = 'Health',
            Category_3__c = 'Hospitals',
            Demo_Date__c = Date.today(),
            HeyJobs_Category__c = 'Agency',
            LeadSource = 'Outbound',
            Status = 'Not researched yet',
            City = 'Berlin',
            Country = 'Deutschland',
            Street= 'Innovationstrasse',
            PostalCode = '10777',
            NumberOfEmployees = 100,
            urlCareerPage__c = 'innovation.de',
            Company = 'Innovation Inc',
            Service_Country__c = 'AT',
            Timestamp_Latest_MQL_Conversion__c = DateTime.now().addHours(-1)
        );
        leadList.add(ld);
        
        Test.startTest();
        insert leadList;
        Test.stopTest();
    }
}