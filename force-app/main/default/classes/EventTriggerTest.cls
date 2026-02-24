@isTest
public class EventTriggerTest {

    @isTest
    static void testEventTrigger() {
        // Create test data: Account
        Account testAccount1 = new Account(Name = 'Test Account 1');
        Account testAccount2 = new Account(Name = 'Account 2');
        insert new List<Account>{testAccount1, testAccount2};

        // Test case 1: Event with subject containing account name before opening bracket
        Event testEventWithBracket = new Event(
            Subject = 'Test Account 1 (Internal Discussion)',
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addHours(1)
        );

        // Test case 2: Event with subject not matching any account names
        Event testEventNonMatchingName = new Event(
            Subject = 'Non Matching Account Name (Internal Discussion)',
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addHours(1)
        );

        // Test case 3: Event with subject not containing any brackets with matching account name
        Event testEventNoBracketsMatching = new Event(
            Subject = 'Test Account 1',
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addHours(1)
        );

        // Test case 4: Event with subject not containing any brackets with non-matching account name
        Event testEventNoBracketsNonMatching = new Event(
            Subject = 'Non Matching Account Name',
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addHours(1)
        );

        // Test case 5: Event with subject that has additional text after the account name
        Event testEventExtraText = new Event(
            Subject = 'Test Account 1 - Follow-up Meeting',
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addHours(1)
        );

        // Test case 6: Event with subject that has brackets but no account name before it
        Event testEventBracketsNoName = new Event(
            Subject = ' (Internal Discussion)',
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addHours(1)
        );

        // Test case 7: Event with subject that has account name and brackets but additional text in between
        Event testEventNameWithExtraText = new Event(
            Subject = 'Test Account 1 - Extra Text (Internal Discussion)',
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addHours(1)
        );

        // Insert test data and run the tests
        Test.startTest();
        insert new List<Event>{
            testEventWithBracket,
            testEventNonMatchingName,
            testEventNoBracketsMatching,
            testEventNoBracketsNonMatching,
            testEventExtraText,
            testEventBracketsNoName,
            testEventNameWithExtraText
        };
        Test.stopTest();

        // Verify the results for each test case
        // ... (perform assertions similar to the previous example for each test case)
    }
}