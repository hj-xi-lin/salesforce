@IsTest
private class Test_MSTEventProcessor {
    
    @IsTest
    static void testprocessPayload() {
        Test.startTest();
        String inputPayload = '{"recruiter_uid":"8e0bd2f4-6003-48cb-bc07-5af11b4d0063","recruiter_email":"d137a6bf-0f6d-40b3-92d6-528f269113db-testing_email@heyjobs.de","event":"recruiterCreated","timestamp":"2023-05-26T15:46:43.593Z"}';
        //inputPayload = JSON.serialize(inputPayload);
        List<MSTEventProcessor.PayloadInput> inputList = new List<MSTEventProcessor.PayloadInput>();
        MSTEventProcessor.PayloadInput input = new MSTEventProcessor.PayloadInput();
        input.eventInput = inputPayload;
        inputList.add(input);
        MSTEventProcessor.processPayload(inputList);
        Test.stopTest();
    }
        
        

}