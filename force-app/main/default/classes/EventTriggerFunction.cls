/*
 * Author: Varun Subhash
 * Date: 09-Apr-2024
 * Description: Class to handle the business logic on Event Trigger.
 *
 * Modification Log:
 * ------------------------------------------------------------------------------------
 * Developer      Date          Description
 * ------------------------------------------------------------------------------------
 * Varun Subhash  09-Apr-2024   Initial version
 * ------------------------------------------------------------------------------------
 */

public with sharing class EventTriggerFunction {

    // Define the Pattern as a static final variable for reuse
    private static final Pattern ACCOUNT_NAME_PATTERN = Pattern.compile('\\((.*?)\\)');
    
    /**
     * @description - Updates the WhatId field of Event records with the corresponding AccountId based on the event subject and location.
     * return - Null
     * @param - The list of Event records to be processed.
     **/
     
    public static void updateRelatedAccount(List<Event> events) {
        //  Filter events and store in a list
        List<Event> eligibleEvents = filterEvents(events);

        // Fetch account names 
        Set<String> accountNames = extractAccountNames(eligibleEvents);

        // Query for accounts and get their IDs
        Map<String, Id> accountNameToIdMap = getAccountIdsFromNames(accountNames);

        //  Update the WhatId field 
        for (Event eventRecord : eligibleEvents) {
            String accountName = extractAccountName(eventRecord.Subject);
            if (accountName != null && accountNameToIdMap.containsKey(accountName)) {
                eventRecord.WhatId = accountNameToIdMap.get(accountName);
            }
        }
    }

    /**
     * @description - Filters events based on eligibility criteria.
     * @param events - The list of Event records to be filtered.
     * @return - The list of filtered Event records.
     **/
     
    private static List<Event> filterEvents(List<Event> events) {
        List<Event> filteredEvents = new List<Event>();
        for (Event eventRecord : events) {
            if (eventRecord.WhatId == null && String.isNotBlank(eventRecord.Location) && eventRecord.Location.contains('book.youcanbook.me')) {
                filteredEvents.add(eventRecord);
            }
        }
        return filteredEvents;
    }

    /**
     * @description - Extracts account names from a list of events.
     * @param - The list of Event records.
     * @return - A set of unique account names extracted from the event subjects.
     **/
     
    private static Set<String> extractAccountNames(List<Event> events) {
        Set<String> accountNames = new Set<String>();
        for (Event eventRecord : events) {
            String accountName = extractAccountName(eventRecord.Subject);
            if (accountName != null) {
                accountNames.add(accountName);
            }
        }
        return accountNames;
    }

    /**
     * @description - Retrieves the AccountIds for the given set of account names.
     * @param  - The set of account names to fetch AccountIds for.
     * @return - A map containing the account names and their corresponding AccountIds.
     **/
     
    private static Map<String, Id> getAccountIdsFromNames(Set<String> accountNames) {
        Map<String, Id> accountNameToIdMap = new Map<String, Id>();
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name IN :accountNames];
        for (Account acc : accounts) {
            accountNameToIdMap.put(acc.Name, acc.Id);
        }
        return accountNameToIdMap;
    }

    /**
     * @description - Extracts the account name from the event subject using a regular expression.
     * @param -  The event subject string.
     * @return - String Account Name
     **/
     
    private static String extractAccountName(String subject) {
        Matcher matcher = ACCOUNT_NAME_PATTERN.matcher(subject);
        if (matcher.find()) {
            return matcher.group(1);
        }
        return null;
    }
}