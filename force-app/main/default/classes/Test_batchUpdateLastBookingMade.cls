@isTest
public class Test_batchUpdateLastBookingMade {
    
    @isTest
    static void testBatchUpdate(){
        List<Account> accList = new List<Account>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<Contact> contactList = new List<Contact>();
        List<Quote> quoteList = new List<Quote>();
        List<string> categoryList = new list<string>{'Auditors','Computer Games','Call Center'};
        
        for(integer i = 0; i < categoryList.size(); i++) {
            Account acc = new Account();
            acc.Name = 'TestIT'+i;
            acc.Category_1__c = 'Service Provider';
            acc.Category_2__c = 'Consultant & IT';
            acc.Category_3__c = categoryList[i];
            acc.NumberOfEmployees = 15000;
            acc.Service_Country__c = 'DE';
            acc.Stage_ACM__c = 'Lost';
            acc.Test_Account__c = true;
            accList.add(acc); 
        }
        insert accList;
        
        for(integer i = 0; i < accList.size(); i++){
            Contact con = new Contact();
            con.FirstName = 'Test';
            con.LastName = 'Customer'+i;
            con.Email = con.LastName + '@dev.com';
            con.Salutation = 'Herr';
            con.AccountId = accList[i].Id;
            contactList.add(con);
        }
        insert contactList;
        
        for(integer i = 0; i < accList.size(); i++){
            accList[i].Contact_Email__c = contactList[i].Email;
            accList[i].Contact_Last_Name__c = contactList[i].LastName;
            accList[i].txtContactsSalutation__c = contactList[i].Salutation;
        }
        update accList;
        
        for(integer i = 0; i < accList.size(); i++){
            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.RecordTypeId = '0121v000000z2JFAAY';
            opp.AccountId = accList[i].Id;
            opp.CloseDate = Date.today() - 1;
            opp.StageName = 'Offer';
            oppList.add(opp);
        }
        insert oppList;
        
        Pricebook2 pb = new Pricebook2(
            Name = 'Standard Price Book 2009', 
            Description = 'Price Book 2009 Products', 
            IsActive = true );
        insert pb;
        
        Product2 prod = new Product2(
            Name = 'SLA: Bronze', 
            IsActive = true);
        insert prod;
        
        PricebookEntry pbe = new PricebookEntry(
            unitprice=10,
            Product2Id=prod.Id, 
            Pricebook2Id=Test.getStandardPricebookId(), 
            IsActive= true); 
        insert pbe; 
        
        for(integer i = 0; i < oppList.size(); i++){
            Quote qt = new Quote();
            qt.Name = 'Test Quote';
            qt.OpportunityId = oppList[i].Id;
            qt.Service_Period__c = '6 Months';
            qt.Pricebook2Id= pb.id;
            qt.Status = 'Sent';
            quoteList.add(qt);
        }
        insert quoteList;
        
        for(Quote qt : quoteList){
            qt.Status = 'Accepted';
        }
        update quoteList;
        
        for(Opportunity opp : oppList){
            opp.Amount = 1320;
            opp.StageName = 'Closed Won';
            opp.Allow_Closed_Won__c = true;
            opp.dateTimestampClosedWonLost__c = Date.today()-1;
        }
        update oppList;
        
        for(Opportunity opp : oppList){
            System.debug('Opp Status >>'+opp.StageName);
        }
        
        for(Opportunity opp : oppList){
            opp.dateTimestampClosedWonLost__c = Date.today()-1;
        }
        update oppList;
        
        Test.startTest();
        Database.executeBatch(new batchUpdateLastBookingMade());
        Test.stopTest();
        
    }

}