@IsTest
public class Test_HeyPaketUtility {
    
    @IsTest
    static void testHeyPaketUtility_Activation(){
        List<Account> accList = new List<Account>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<string> categoryList1 = new list<string>{'Auditors','Computer Games'};
           
        Test.startTest();
        //Accounts for new activation
        for(integer i = 0; i < categoryList1.size(); i++) {
            Account acc = new Account();
            acc.Name = 'TestIT'+i;
            acc.Category_1__c = 'Service Provider';
            acc.Category_2__c = 'Consultant & IT';
            acc.Category_3__c = categoryList1[i];
            acc.NumberOfEmployees = 15000;
            acc.Service_Country__c = 'DE';
            acc.Stage_ACM__c = 'Lost';
            acc.Test_Account__c = true;
            accList.add(acc); 
        }
        insert accList;
        
         //Opportunities for normal activation
        for(integer i = 0; i < accList.size(); i++){
            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.RecordTypeId = '0121v000000z2JFAAY';
            opp.AccountId = accList[i].Id;
            opp.CloseDate = Date.today() + 180;
            opp.StageName = 'Contract Received';
            opp.HeyPaket_Start_Date__c = Date.today();
            opp.HeyPaket_Type__c = 'Essential';
            oppList.add(opp);
        }
        insert oppList;
        
        HeyPaketUtility.heypaketActivation(oppList);
        Test.stopTest();
    }
    
     @isTest
    static void testHeyPaketUtility_RenewalActivation(){
        
        List<Account> renewalAccList = new List<Account>();
        List<Opportunity> renewalOppList = new List<Opportunity>();
        List<Opportunity> newRenewalOppList = new List<Opportunity>();
        List<string> categoryList2 = new list<string>{'Engineering','Estates'};
        
        Test.startTest();
        
        //Accounts for upsell activation
        for(integer i = 0; i < categoryList2.size(); i++) {
            Account acc = new Account();
            acc.Name = 'Upsell '+i+categoryList2[i];
            acc.Category_1__c = 'Service Provider';
            acc.Category_2__c = 'Consultant & IT';
            acc.Category_3__c = categoryList2[i];
            acc.NumberOfEmployees = 15000;
            acc.Service_Country__c = 'DE';
            acc.Test_Account__c = true;
            renewalAccList.add(acc); 
        }
        insert renewalAccList;
        
        //Existing Opportunities that are in Renewed Stage
        for(integer i = 0; i < renewalAccList.size(); i++){
            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.RecordTypeId = '0121v000000z2JFAAY';
            opp.AccountId = renewalAccList[i].Id;
            opp.CloseDate = Date.today() + 180;
            opp.StageName = 'Contract Received';
            opp.HeyPaket_Start_Date__c = Date.today() -180;
            opp.HeyPaket_Type__c = 'Professional';
            opp.HeyPaket_Status__c = 'Renewed';
            renewalOppList.add(opp);
        }
        insert renewalOppList;
        
        for(integer i = 0; i < renewalAccList.size(); i++){
            renewalAccList[i].Active_HeyPaket__c = renewalOppList[i].Id;
        }
        
        update renewalAccList;
        
        //New Opportunities to override the existing Active pakets
        for(integer i = 0; i < renewalAccList.size(); i++){
            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.RecordTypeId = '0121v000000z2JFAAY';
            opp.AccountId = renewalAccList[i].Id;
            opp.CloseDate = Date.today() + 180;
            opp.StageName = 'Contract Received';
            opp.HeyPaket_Start_Date__c = Date.today();
            opp.HeyPaket_Type__c = 'Professional';
            opp.HeyPaket_Status__c = 'Active';
            newRenewalOppList.add(opp);
        }
        insert newRenewalOppList;
        
        HeyPaketUtility.heypaketActivation(newRenewalOppList);
        Test.stopTest(); 
    }
    
    @isTest
    static void testHeyPaketUtility_UpsellActivation(){
        
        List<Account> activeAccList = new List<Account>();
        List<Opportunity> activeOppList = new List<Opportunity>();
        List<Opportunity> newActiveOppList = new List<Opportunity>();
        List<string> categoryList3 = new list<string>{'Translation','Headhunter'};
        
        Test.startTest();
        
        //Accounts for upsell activation
        for(integer i = 0; i < categoryList3.size(); i++) {
            Account acc = new Account();
            acc.Name = 'Upsell '+i+categoryList3[i];
            acc.Category_1__c = 'Service Provider';
            acc.Category_2__c = 'Consultant & IT';
            acc.Category_3__c = categoryList3[i];
            acc.NumberOfEmployees = 15000;
            acc.Service_Country__c = 'DE';
            acc.Test_Account__c = true;
            activeAccList.add(acc); 
        }
        insert activeAccList;
        
        //Existing Opportunities that are in Active Stage
        for(integer i = 0; i < activeAccList.size(); i++){
            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.RecordTypeId = '0121v000000z2JFAAY';
            opp.AccountId = activeAccList[i].Id;
            opp.CloseDate = Date.today() + 180;
            opp.StageName = 'Contract Received';
            opp.HeyPaket_Start_Date__c = Date.today() -180;
            opp.HeyPaket_Type__c = 'Essential';
            opp.HeyPaket_Status__c = 'Active';
            activeOppList.add(opp);
        }
        insert activeOppList;
        
        for(integer i = 0; i < activeAccList.size(); i++){
            activeAccList[i].Active_HeyPaket__c = activeOppList[i].Id;
        }
        
        update activeAccList;
        
        //New Opportunities to override the existing Active pakets
        for(integer i = 0; i < activeAccList.size(); i++){
            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.RecordTypeId = '0121v000000z2JFAAY';
            opp.AccountId = activeAccList[i].Id;
            opp.CloseDate = Date.today() + 180;
            opp.StageName = 'Contract Received';
            opp.HeyPaket_Start_Date__c = Date.today() -180;
            opp.HeyPaket_Type__c = 'Essential';
            opp.HeyPaket_Status__c = 'Active';
            newActiveOppList.add(opp);
        }
        insert newActiveOppList;
        
        HeyPaketUtility.heypaketActivation(newActiveOppList);
        Test.stopTest();
        
    }
    
   
}