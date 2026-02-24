@isTest 
public class QuoteTriggerHandlerTest {
	@isTest  static void TestMethod1() {
        Account acc = new Account (       
        Name ='Foo',
        NumberOfEmployees = 2500,
        Service_Country__c = 'DE');
        insert acc;
         Id recTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.CloseDate = Date.today().addDays(5);
        opp.StageName = 'offer';
        opp.AccountId = acc.id;
        opp.RecordTypeId = recTypeId;
        insert opp;

		Pricebook2 pb = new Pricebook2(Name = 'Standard Price Book 2009', Description = 'Price Book 2009 Products', IsActive = true );
			insert pb;
		Product2 prod = new Product2(Name = 'SLA: Bronze', IsActive = true);
			insert prod;
		PricebookEntry pbe=new PricebookEntry(unitprice=0.01,Product2Id=prod.Id, Pricebook2Id=Test.getStandardPricebookId(), IsActive= true); 
			 insert pbe;   
        
        User u = [SELECT Id,name FROM User WHERE name LIKE '%Theresa Lehmann%' and IsActive = true limit 1];
       // System.runAs(u) {
            Quote q= new Quote ();
            q.Name= 'Testq';
        	q.OpportunityId= Opp.id;
        	q.BillingStreet= '123';
        	q.BillingCity= 'City';
        	q.BillingPostalCode= '12345';
        	q.Pricebook2Id= pb.id;
        	insert q;
            
            q.Status = 'sent';
        	update q;
        //}
        
	}
    
    @isTest  static void TestMethod2() {
        Account acc = new Account (       
        Name ='Foo',
        NumberOfEmployees = 2500,
        Service_Country__c = 'DE');
        insert acc;
         Id recTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.CloseDate = Date.today().addDays(5);
        opp.StageName = 'offer';
        opp.AccountId = acc.id;
        opp.RecordTypeId = recTypeId;
        insert opp;
        
        contact con = new contact();
        con.FirstName = 'test';
        con.LastName = 'test';
        con.AccountId = acc.id;
        con.Email= 'gagan.madaan@heyjobs.de';
        insert con;

		Pricebook2 pb = new Pricebook2(Name = 'Standard Price Book 2009', Description = 'Price Book 2009 Products', IsActive = true );
			insert pb;
		Product2 prod = new Product2(Name = 'SLA: Bronze', IsActive = true);
			insert prod;
		PricebookEntry pbe=new PricebookEntry(unitprice=0.01,Product2Id=prod.Id, Pricebook2Id=Test.getStandardPricebookId(), IsActive= true); 
			 insert pbe;   
        
        User u = [SELECT Id,name FROM User WHERE name LIKE '%Theresa Lehmann%' and IsActive = true limit 1];
       // System.runAs(u) {
            Quote q= new Quote ();
            q.Name= 'Testq';
        	q.OpportunityId= Opp.id;
        	q.BillingStreet= '123';
        	q.BillingCity= 'City';
        	q.BillingPostalCode= '12345';
        	q.Pricebook2Id= pb.id;
        	q.ContactId = con.id;
        q.Automatic_Quote_E_Mail__c = true;
        	insert q;
            
        	q.Status = 'sent';
        	update q;
        //}
        
	}
}