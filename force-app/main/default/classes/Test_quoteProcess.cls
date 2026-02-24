@isTest(SeeAllData=true)
public class Test_quoteProcess {

    @IsTest
    static void test_createQuoteLineItems(){
        Test.startTest();
        List<Quote> lstQuote = new List<Quote>();

        Account objAccount = new Account(Name ='TEST Acc for Quote',
                                            Service_Country__c = 'DE',
                                            NumberOfEmployees = 2500,
                                        	Competitor_1_current_future__c = 'None');
        insert objAccount;
        
        
        Product2 objProduct = new Product2(Name = 'Test product1', family = 'Cafe');                                           
        insert objProduct;
        
        // Insert Pricebook
        PriceBook2 customPriceBook = new PriceBook2();
        customPriceBook.Name='Custom Pricebook';
        customPriceBook.IsActive=true;
        insert customPriceBook;
        
        // Query Standard and Custom Price Books
        Pricebook2 customPriceBookRec=[select Id from Pricebook2 where id=:customPriceBook.Id];
        //Id stdPriceBookRecId = Test.getStandardPricebookId();
        Id stdPriceBookRecId = [Select Id,name,isstandard from Pricebook2 Where IsStandard=true].Id;
        
        // Create Standard PriceBookEntry
        PriceBookEntry stdPriceBookEntry = new PriceBookEntry();
        stdPriceBookEntry.Product2Id=objProduct.Id;
        stdPriceBookEntry.Pricebook2Id=stdPriceBookRecId;
        stdPriceBookEntry.UnitPrice=2000;
        stdPriceBookEntry.IsActive=true;
        insert stdPriceBookEntry;
        
        //Create custom PriceBookEntry
        PriceBookEntry objPBE = new PriceBookEntry(UnitPrice = 300, PriceBook2Id = customPriceBookRec.Id,
                                                        Product2Id = objProduct.Id, IsActive = true);
        insert objPBE;
        
        Opportunity objOpp = new Opportunity(Name = 'Test Opp', AccountId = objAccount.Id, StageName = 'Offer', CloseDate = Date.today()+1);
        insert objOpp;
        
        for(Integer i=0; i< 10 ; i++){
            lstQuote.add(new Quote(OpportunityId = objOpp.Id, Name = 'Test Quote' + i, Pricebook2Id = customPriceBookRec.Id, Status = 'Draft'));
        }
        insert lstQuote;
        List<quoteProcess.InputVariables> inputList = new List<quoteProcess.InputVariables>();
        quoteProcess.InputVariables inputVariable = new quoteProcess.InputVariables();
        inputVariable.quoteId = lstQuote[0].Id;
        inputList.add(inputVariable);
      
        
        quoteProcess.createQuoteLineItems(inputList);
        Test.stopTest();
    }
}