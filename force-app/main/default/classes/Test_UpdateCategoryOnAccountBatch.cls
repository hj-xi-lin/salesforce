@isTest
public class Test_UpdateCategoryOnAccountBatch {
    @isTest static void test1() {
        List<Account> accList = new List<Account>();
        
        List<string> cat3forIT = new list<string>{'Auditors','Computer Games','Call Center','Lawyer','Engineering','Estates','IT Consulting','Job Promotion','Translation','Management Consultant','Headhunter','Research Centers','Software Manufacturer','Temporary Employment Agencies','Tester','Training'};
        for(integer i = 0; i < 16; i++) {
            Account acc = new Account();
            acc.Name = 'TestIT'+i;
            acc.Category_1__c = 'Service Provider';
            acc.Category_2__c = 'Consultant & IT';
            accList.add(acc); 
        }
        
        List<string> cat3forFin = new list<string>{'Banks','Bausparkasse','Collection','Consumer Organizations','Development Banks','Sparkasse','Financial Funds','Insurance','Insurance Broker','Leasing','Payment Processor','Private Banks','Professional Association','Trustee','Investors'};
        for(integer i = 0; i < 15; i++) {
            Account acc = new Account();
            acc.Name = 'TestFin'+i;
            acc.Category_1__c = 'Service Provider';
            acc.Category_2__c = 'Finance & Insurance';
            acc.Category_3__c = cat3forFin[i];
            accList.add(acc); 
        }
        
        List<string> cat3forIndustry = new list<string>{'Basic Chemicals','Contract Manufacturers','Generics','Household Chemistry','Packaging Industry','Paint Manufacturers','Paper Mills','Pharmaceutical Industry'};
        for(integer i = 0; i < 8; i++) {
            Account acc = new Account();
            acc.Name = 'TestChem'+i;
            acc.Category_1__c = 'Industry';
            acc.Category_2__c = 'Chemical Industry';
            acc.Category_3__c = cat3forIndustry[i];
            accList.add(acc); 
        }
        
        List<string> cat3forHealth = new list<string>{'Hospitals','Dental Laboratories','Care Services','Health Insurance','Hearing Care','Laboratories','Medical Services','Care Homes','Optician','Pharmacies','Radiology Practices','Rehabilitation clinics'};
        for(integer i = 0; i < 12; i++) {
            Account acc = new Account();
            acc.Name = 'TestHealth'+i;
            acc.Category_1__c = 'Service Provider';
            acc.Category_2__c = 'Health';
            acc.Category_3__c = cat3forHealth[i];
            accList.add(acc); 
        }
        
        List<string> cat3forFood = new list<string>{'Bakery','Butcher','Cash-and-Carry','Confiserie','Delicacy','Discounter','Liquor Stores','Health Food Store','Bio-Stores','Supermarkets','Wine Merchant',''};
        for(integer i = 0; i < 11; i++) {
            Account acc = new Account();
            acc.Name = 'TestFood'+i;
            acc.Category_1__c = 'Retail';
            acc.Category_2__c = 'Food Stores';
            acc.Category_3__c = cat3forFood[i];
            accList.add(acc); 
        }
        
        List<string> cat3forAir = new list<string>{'Airlines','Caterer','Car Rental'};
        for(integer i = 0; i < 3; i++) {
            Account acc = new Account();
            acc.Name = 'TestAir'+i;
            acc.Category_1__c = 'Service Provider';
            acc.Category_2__c = 'Gastronomy & Tourism';
            acc.Category_3__c = cat3forAir[i];
            accList.add(acc); 
        }
        
        Account acc = new Account();
        acc.Name = 'Test';
        acc.Category_1__c = 'Service Provider';
        acc.Category_2__c = 'Leisure & Entertainment';
        acc.Category_3__c = 'Hockey Teams';
        accList.add(acc);
        
        Account acc2 = new Account();
        acc2.Name = 'Test22';
        acc2.Category_1__c = 'Retail';
        acc2.Category_2__c = 'Food Stores';
        acc2.Category_3__c = 'Delicacy';
        accList.add(acc2);
        
        Account acc3 = new Account();
        acc3.Name = 'Test33';
        acc3.Category_1__c = 'Industry';
        acc3.Category_2__c = 'Wholesale';
        acc3.Category_3__c = 'Builder\'s Merchant';
        accList.add(acc3);
        
        Account acc4 = new Account();
        acc4.Name = 'Test44';
        acc4.Category_1__c = 'Industry';
        acc4.Category_2__c = 'Wholesale';
        acc4.Category_3__c = 'Wholesale Cleaning';
        accList.add(acc4);

        for(Account ac : accList){
            ac.NumberOfEmployees = 2400;
            ac.Service_Country__c ='DE';
        }
        
        insert accList;
        
        Test.startTest();
        String query = 'SELECT Id, Name, Category_3__c, HeyJobs_Category__c, X2020_Reference_Clients__c, RecordType.Name FROM Account WHERE Category_3__c != null';
        Database.executeBatch(new UpdateCategoryOnAccountBatch(query));
        Test.stopTest();
    }
}