@isTest
public class Test_EventTriggerHandler {
    @isTest
    static void testUpdateRelatedAccount() {
        

        // Create test Account records
        Account testAccount1 = new Account(Name = 'Test Account 1');
        Account testAccount2 = new Account(Name = 'Test Account 2');
        insert new List<Account>{testAccount1, testAccount2};

        
        List<Event> testEvents = new List<Event>{
            new Event(
                Subject = 'Meeting with (Test Account 1)', 
                Location = 'book.youcanbook.me',
                StartDateTime = DateTime.now().addHours(1),
                EndDateTime = DateTime.now().addHours(2),
                WhatId = null
            ),
            new Event(
                Subject = 'Call with (Test Account 1)', 
                Location = 'book.youcanbook.me',
                StartDateTime = DateTime.now().addHours(1),
                EndDateTime = DateTime.now().addHours(2),
                WhatId = testAccount1.Id
            ),
            new Event(
                Subject = 'Meeting with (Test Account 1)', 
                Location = 'Zoom Meeting',
                StartDateTime = DateTime.now().addHours(1),
                EndDateTime = DateTime.now().addHours(2),
                WhatId = null
            ),
            new Event(
                Subject = 'Meeting', 
                Location = 'book.youcanbook.me',
                StartDateTime = DateTime.now().addHours(1),
                EndDateTime = DateTime.now().addHours(2),
                WhatId = null
            )
        };

        // Insert test events to the database
        insert testEvents;


        Test.startTest();
        EventTriggerFunction.updateRelatedAccount(testEvents); 
        Test.stopTest();

        

        // Re-query the Events from the database to get the latest state
        Map<Id, Event> updatedEvents = new Map<Id, Event>([
            SELECT Id, WhatId
            FROM Event
            WHERE Id IN :testEvents
        ]);

        // Iterate over the original testEvents list to verify the expected outcomes
        for (Event originalEvent : testEvents) {
            Event updatedEvent = updatedEvents.get(originalEvent.Id);

            // Assert that the WhatId was updated for the Event that met the criteria
            if (originalEvent.Subject.contains('Test Account 1') && originalEvent.Location.contains('book.youcanbook.me')) {
                System.assertEquals(testAccount1.Id, updatedEvent.WhatId,
                    'The WhatId for ' + originalEvent.Subject + ' should be updated to the test Account\'s Id.');
            }
            // Assert that the WhatId was not updated for the Events that did not meet the criteria
            else {
                System.assertEquals(null, updatedEvent.WhatId,
                    'The WhatId for ' + originalEvent.Subject + ' should remain null as it does not meet the update criteria.');
            }
        }
    }
}