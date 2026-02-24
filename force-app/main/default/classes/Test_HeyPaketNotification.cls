@IsTest
private class Test_HeyPaketNotification {
    @IsTest
    static void testSendMessage() {
        Test.startTest();
        List<Quote> lstQuote = new List<Quote>();
        
        Account objAccount = new Account(Name ='TEST Acc for Quote',
                                         Service_Country__c = 'DE',
                                         NumberOfEmployees = 2500);
        insert objAccount;
        
        List<HeyPaketNotification.HeyPaketMessageInput> inputList = new List<HeyPaketNotification.HeyPaketMessageInput>();
        HeyPaketNotification.HeyPaketMessageInput input = new HeyPaketNotification.HeyPaketMessageInput();
        input.accountId = objAccount.Id;
        input.paketType = System.Label.HeyPaket_Essential;
        input.activationType = System.Label.HeyPaket_Renewal;
        inputList.add(input);
        
        HeyPaketNotification.generateHeyPaketeMessage(inputList);
        Test.stopTest();
    }
}