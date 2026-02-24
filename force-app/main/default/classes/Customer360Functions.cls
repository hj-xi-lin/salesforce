/*
*      	@author 		Lisa Müller
*      	@date   		Apr-2025
*      	@description  	Logic to handle the creation of Customer 360 Helper Records (RO-2473)
*
*      	Modification Log:
*      	------------------------------------------------------------------------------------
*      	Developer		Date                Description
*		Lisa Müller		2025-05-06			Optimizing format for calls and events
*		Lisa Müller		2025-05-21			Reworking the logic due to changed scope of Account Summary (RO-2531)
*      	------------------------------------------------------------------------------------			
*/

public class Customer360Functions {

    // Define the character limit for Content_max_limit__c field
    private static final Integer CONTENT_MAX_LIMIT = 131072; // Correct limit
  	
    /**
    @Methodname     : createHelperRecords
    @Param          : List<Account>
    @Return         : NULL
    @Description    : To check if Customer 360 records should be created and call appropriate methods
	**/
    public static void createHelperRecords(List<Account> newAccountList, List<Account> oldAccountList) {
        Map<Id, Account> oldAccountMap = new Map<Id, Account>();

        for (Account acc : oldAccountList) {
            oldAccountMap.put(acc.Id, acc);
        }

        List<Account> accountsToProcess = new List<Account>();

        // Check if AI_Summary_Helper__c is updated accordingly
		String triggeringValue = System.Label.AccountSummaryTriggeringValue;
        for (Account acc : newAccountList) {
            if (acc.AI_Summary_Helper__c == triggeringValue && oldAccountMap.get(acc.Id).AI_Summary_Helper__c != triggeringValue) {
                accountsToProcess.add(acc);
            }
        }
		        
        
        if (!accountsToProcess.isEmpty()) {
            // Fetch metadata settings
            Account_Summary_Setting__mdt callsSetting = Account_Summary_Setting__mdt.getInstance('Calls');
            Account_Summary_Setting__mdt eventsSetting = Account_Summary_Setting__mdt.getInstance('Events');
            Account_Summary_Setting__mdt oppsSetting = Account_Summary_Setting__mdt.getInstance('Opps');
            
            // Process all accounts that meet the criteria
            createCallsRecord(accountsToProcess, callsSetting);
            createEventsRecord(accountsToProcess, eventsSetting);
            createOpportunitiesRecord(accountsToProcess, oppsSetting);
            
            // Update AI_Summary_Helper__c field to "Generate Summary"
            String updatingValue = System.Label.AccountSummaryUpdatingValue;
            List<Account> accountsToUpdate = new List<Account>();
            for (Account acc : accountsToProcess) {
                Account accountToUpdate = new Account();
                accountToUpdate.Id = acc.Id;
                accountToUpdate.AI_Summary_Helper__c = updatingValue;
                accountsToUpdate.add(accountToUpdate);
            }
    
            // Perform the DML update
            if (!accountsToUpdate.isEmpty()) {
                Database.SaveResult[] updateResults = Database.update(accountsToUpdate, false);
            
                for (Database.SaveResult sr : updateResults) {
                    if (!sr.isSuccess()) {
                        for (Database.Error err : sr.getErrors()) {
                            Logger.finest('Failed to update Account with ID: ' + sr.getId() + 
                                '. The error occurred: ' + err.getStatusCode() + ' - ' + err.getMessage());
                        }
                    }
                }
			}
			Logger.saveLog();
            
        }
    }

     /**
    @Methodname     : createCallsRecord
    @Param          : List of Accounts, Account_Summary_Setting__mdt
    @Return         : NULL
    @Description    : To combine calls within defined limit into a Customer 360 'Calls' record
	**/
    private static void createCallsRecord(List<Account> accounts, Account_Summary_Setting__mdt callSetting) {
            
        // Define date range filters
        Integer pastMonths = (callSetting != null && callSetting.Past_Months_Limit__c != null) ? callSetting.Past_Months_Limit__c.intValue() : 0;
        Date callStartDateLimit = Date.today().addMonths(-pastMonths);
        Date callEndDateLimit = Date.today();
        
        Datetime callStartDateTimeFilter = Datetime.newInstance(callStartDateLimit.year(), callStartDateLimit.month(), callStartDateLimit.day(), 0, 0, 0);
       	Datetime callEndDateTimeFilter = Datetime.newInstance(callEndDateLimit.year(), callEndDateLimit.month(), callEndDateLimit.day(), 23, 59, 59);
        
        // Collect all account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Account account : accounts) {
            accountIds.add(account.Id);
        }

        // Query calls related to the account with filters
        List<Task> calls = [SELECT Id, CreatedDate, WhoId, Description, AccountId
                            FROM Task
                            WHERE (CallType = 'Inbound' OR CallType = 'Outbound')
                            AND AccountId IN :accountIds
                            AND (Related_To_ID__c LIKE '001%' OR Related_To_ID__c LIKE '006%' OR Name_ID__c LIKE '003%')
                            AND CreatedDate >= :callStartDateTimeFilter AND CreatedDate <= :callEndDateTimeFilter
                            ORDER BY CreatedDate ASC];
        
        // Filter calls with non-empty descriptions (Description cannot be used in the query directly)
        Map<Id, List<Task>> accountToFilteredCalls = new Map<Id, List<Task>>();
        for (Task call : calls) {
            if (String.isNotBlank(call.Description)) {
                if (!accountToFilteredCalls.containsKey(call.AccountId)) {
                    accountToFilteredCalls.put(call.AccountId, new List<Task>());
                }
                accountToFilteredCalls.get(call.AccountId).add(call);
            }
        }
        
        // Collect WhoIds for contact querying
        Set<Id> contactIds = new Set<Id>();
        for (Task call : calls) {
            if (call.WhoId != null && call.WhoId.getSObjectType() == Contact.sObjectType) {
                contactIds.add(call.WhoId);
            }
        }

        // Query Contacts
        Map<Id, Contact> contactsMap = new Map<Id, Contact>([SELECT Id, Name FROM Contact WHERE Id IN :contactIds]);

        // Query Customer_360__c records
        List<Customer_360__c> existingCustomer360Records = [SELECT Id, Account__c, Content_max_limit__c 
                                                            FROM Customer_360__c 
                                                            WHERE Account__c IN :accountIds AND Type__c = 'Calls'];
        Map<Id, Customer_360__c> existingCustomer360Map = new Map<Id, Customer_360__c>();
        for (Customer_360__c record : existingCustomer360Records) {
            existingCustomer360Map.put(record.Account__c, record);
        }
        
        // Loop accounts and prepare Customer_360__c records
    	List<Customer_360__c> recordsToInsert = new List<Customer_360__c>();
    	List<Customer_360__c> recordsToUpdate = new List<Customer_360__c>();
        
        for (Account account : accounts) {
            List<Task> filteredCalls = accountToFilteredCalls.get(account.Id);
            
          	// Process calls and format strings
            String formattedContent = '';
            if (filteredCalls != null && !filteredCalls.isEmpty()) {
                for (Task call : filteredCalls) {
                    String contactName = contactsMap.containsKey(call.WhoId) ? contactsMap.get(call.WhoId).Name : 'no contact related';
    
                    String description = call.Description;
                    String sanitizedDescription;
                    
                    if (String.isNotBlank(description)) {
                        Integer aiSummaryIndex = description.indexOf('AI summary:');
                        if (aiSummaryIndex > -1) {
                            // Split into pre-summary and AI summary
                            String preSummary = description.substring(0, aiSummaryIndex);
                            String aiSummary = description.substring(aiSummaryIndex);
                    
                            // Sanitize the description by removing newlines, excessive spaces, and trimming
                            preSummary = preSummary
                                .replaceAll('\\s*\\n+\\s*', ' ') // Replace newlines with a single space
                        		.replaceAll('\\s+', ' ')        // Replace multiple spaces with a single space
                        		.trim();                         // Trim leading and trailing spaces
                    
                            // Combine sanitized preSummary and untouched AI summary
                            sanitizedDescription = preSummary + '\n' + aiSummary;
                        } else {
                            // No AI summary, sanitize the whole description
                            sanitizedDescription = description
                                .replaceAll('\\s*\\n+\\s*', ' ') // Replace newlines with a single space
                        		.replaceAll('\\s+', ' ')        // Replace multiple spaces with a single space
                        		.trim();                         // Trim leading and trailing spaces
                    	}
                    }
    				
                    Datetime createdDateTime = call.CreatedDate;
                    String formattedCall = 'Record ID: ' + call.Id + ' | Date: ' + createdDateTime.format('yyyy-MM-dd') + ' | Time: ' +  createdDateTime.format('HH:mm:ss') + ' | Contact: ' + contactName + ' | Description: ' + sanitizedDescription;
                    formattedContent += formattedCall + '\n';
                }
            } else {
                formattedContent = 'none\n';
            }
    
            // Prepare the warning message
            String warningMessage = '\nNote: This list is truncated due to character limits.';
            if (formattedContent.length() + warningMessage.length() > CONTENT_MAX_LIMIT) {
                formattedContent = formattedContent.substring(0, CONTENT_MAX_LIMIT - warningMessage.length()) + warningMessage;
            }
    		
            // Check if an existing Customer_360__c record exists
            if (existingCustomer360Map.containsKey(account.Id)) {
                Customer_360__c existingRecord = existingCustomer360Map.get(account.Id);
                existingRecord.Content_max_limit__c = formattedContent;
                existingRecord.Timestamp_Content_Generated__c = Datetime.now();
				recordsToUpdate.add(existingRecord);            
            } else {
                Customer_360__c newRecord = new Customer_360__c();
                newRecord.Account__c = account.Id;
                newRecord.Type__c = 'Calls';
                newRecord.Content_max_limit__c = formattedContent;
                newRecord.Timestamp_Content_Generated__c = Datetime.now();
                recordsToInsert.add(newRecord);
        	}
    	}
        
        // Perform separate DML operations
        if (!recordsToInsert.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(recordsToInsert, false);
            for (Database.SaveResult sr : insertResults) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        Logger.finest('Failed to insert record. The error occurred: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }
        
        if (!recordsToUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(recordsToUpdate, false);
			for (Database.SaveResult sr : updateResults) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        Logger.finest('Failed to update record with ID: ' + sr.getId() + '. The error occurred: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }
        Logger.saveLog();
     
    }
    
    
  	/**
    @Methodname     : createEventsRecord
    @Param          : List of Accounts, Account_Summary_Setting__mdt
    @Return         : NULL
    @Description    : To combine events within defined limit into a Customer 360 'Events' record
	**/
    private static void createEventsRecord(List<Account> accounts, Account_Summary_Setting__mdt eventSetting) {
            
        // Define date range filters
        Integer pastMonths = (eventSetting != null && eventSetting.Past_Months_Limit__c != null) ? eventSetting.Past_Months_Limit__c.intValue() : 0;
        Date eventStartDateLimit = Date.today().addMonths(-pastMonths);
        Date eventEndDateLimit = Date.today();
        
        Datetime eventStartDateTimeFilter = Datetime.newInstance(eventStartDateLimit.year(), eventStartDateLimit.month(), eventStartDateLimit.day(), 0, 0, 0);
        Datetime eventStartDateTimeCutting = eventStartDateTimeFilter;
       	Datetime eventEndDateTimeFilter = Datetime.newInstance(eventEndDateLimit.year(), eventEndDateLimit.month(), eventEndDateLimit.day(), 23, 59, 59);

        // Collect all account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Account account : accounts) {
            accountIds.add(account.Id);
        }
        
        // Query events related to the account with filters
        List<Event> events = [SELECT Id, ActivityDateTime, WhoId, Description, AccountId
                            FROM Event
                            WHERE AccountId IN :accountIds
                            AND (Related_To_ID__c LIKE '001%' OR Related_To_ID__c LIKE '006%' OR Name_ID__c LIKE '003%')
                            AND ActivityDateTime >= :eventStartDateTimeFilter AND ActivityDateTime <= :eventEndDateTimeFilter
                            ORDER BY CreatedDate ASC];
        
        // Filter events with non-empty descriptions (Description cannot be used in the query directly)
        Map<Id, List<Event>> accountToFilteredEvents = new Map<Id, List<Event>>();
        for (Event event : events) {
            if (String.isNotBlank(event.Description)) {
                if (!accountToFilteredEvents.containsKey(event.AccountId)) {
                    accountToFilteredEvents.put(event.AccountId, new List<Event>());
                }
                accountToFilteredEvents.get(event.AccountId).add(event);
            }
        }
        
        // Collect all WhoIds from events for contact querying
        Set<Id> contactIds = new Set<Id>();
        for (Event event : events) {
            if (event.WhoId != null && event.WhoId.getSObjectType() == Contact.sObjectType) {
                contactIds.add(event.WhoId);
            }
        }

        // Query Contacts
        Map<Id, Contact> contactsMap = new Map<Id, Contact>([SELECT Id, Name FROM Contact WHERE Id IN :contactIds]);

		// Query Event Relations to get all attendees for events
        List<EventRelation> allEventRelations = [SELECT EventId, RelationId, Relation.Name FROM EventRelation WHERE EventId IN :events];
        Map<Id, List<EventRelation>> eventRelationsMap = new Map<Id, List<EventRelation>>();
        for (EventRelation relation : allEventRelations) {
            if (relation.RelationId.getSObjectType() == Contact.sObjectType) {
                if (!eventRelationsMap.containsKey(relation.EventId)) {
                    eventRelationsMap.put(relation.EventId, new List<EventRelation>());
                }
                eventRelationsMap.get(relation.EventId).add(relation);
            }
        }
        
        // Query Customer_360__c records
        List<Customer_360__c> existingCustomer360Records = [SELECT Id, Account__c, Content_max_limit__c 
                                                            FROM Customer_360__c 
                                                            WHERE Account__c IN :accountIds AND Type__c = 'Events'];
        Map<Id, Customer_360__c> existingCustomer360Map = new Map<Id, Customer_360__c>();
        for (Customer_360__c record : existingCustomer360Records) {
            existingCustomer360Map.put(record.Account__c, record);
        }
        
        // Loop accounts and prepare Customer_360__c records
        List<Customer_360__c> recordsToInsert = new List<Customer_360__c>();
    	List<Customer_360__c> recordsToUpdate = new List<Customer_360__c>();

        for (Account account : accounts) {
        	List<Event> filteredEvents = accountToFilteredEvents.get(account.Id);
            
            // Process events and format strings
            String formattedContent = '';
			if (filteredEvents != null && !filteredEvents.isEmpty()) {                
                for (Event event : filteredEvents) {
                    String contactNames = '';
                    if (eventRelationsMap.containsKey(event.Id)) {
                        for (EventRelation relation : eventRelationsMap.get(event.Id)) {
                            contactNames += relation.Relation.Name + ', ';
                        }
                        contactNames = contactNames.endsWith(', ') ? contactNames.substring(0, contactNames.length() - 2) : contactNames;
                    }
                    
                    String description = event.Description;
                    String sanitizedDescription;
                    
                    if (String.isNotBlank(description)) {
                        Integer aiSummaryIndex = description.indexOf('AI summary:');
                        if (aiSummaryIndex > -1) {
                            // Split into pre-summary and AI summary
                            String preSummary = description.substring(0, aiSummaryIndex);
                            String aiSummary = description.substring(aiSummaryIndex);
                    
                            // Sanitize the description by removing newlines, excessive spaces, and trimming
                            preSummary = preSummary
                                .replaceAll('\\s*\\n+\\s*', ' ') // Replace multiple newlines or blank lines with a single space
                                .replaceAll('\\s+', ' ')        // Replace multiple spaces with a single space
                                .replaceAll('https?:\\/\\/\\S+', '') // Remove URLs (e.g., meeting links)
                                .replaceAll('\\b(?:Besprechungs-ID|Kennung|Telefonkonferenz-ID|Meeting ID|Passcode|PIN):?\\s*\\S+', '') // Remove meeting IDs and codes
                                .replaceAll('\\+?\\d+[-\\d,\\s]+#?', '') // Remove phone numbers (e.g., +49 69 667781666,,852044774#)
                                .replaceAll('\\b(?:Jetzt an der Besprechung teilnehmen|Suchen einer lokalen Rufnummer|Für Organisatoren|Meeting options|Benötigen Sie Hilfe)\\b.*', '') // Remove Teams/Meeting-specific phrases
                                .replaceAll('_{10,}', '') // Remove long underscores or separators
                                .replaceAll('[^\\w\\s.,!?äöüÄÖÜß-]', '') // Remove special characters (except punctuation and German characters)
                                .trim(); // Trim leading and trailing spaces
                    
                            // Combine sanitized preSummary and untouched AI summary
                            sanitizedDescription = preSummary + '\n' + aiSummary;
                        } else {
                            // No AI summary, sanitize the whole description
                            sanitizedDescription = description
                                .replaceAll('\\s*\\n+\\s*', ' ') // Replace multiple newlines or blank lines with a single space
                                .replaceAll('\\s+', ' ')        // Replace multiple spaces with a single space
                                .replaceAll('https?:\\/\\/\\S+', '') // Remove URLs (e.g., meeting links)
                                .replaceAll('\\b(?:Besprechungs-ID|Kennung|Telefonkonferenz-ID|Meeting ID|Passcode|PIN):?\\s*\\S+', '') // Remove meeting IDs and codes
                                .replaceAll('\\+?\\d+[-\\d,\\s]+#?', '') // Remove phone numbers (e.g., +49 69 667781666,,852044774#)
                                .replaceAll('\\b(?:Jetzt an der Besprechung teilnehmen|Suchen einer lokalen Rufnummer|Für Organisatoren|Meeting options|Benötigen Sie Hilfe)\\b.*', '') // Remove Teams/Meeting-specific phrases
                                .replaceAll('_{10,}', '') // Remove long underscores or separators
                                .replaceAll('[^\\w\\s.,!?äöüÄÖÜß-]', '') // Remove special characters (except punctuation and German characters)
                                .trim(); // Trim leading and trailing spaces
                    	}
                    }
                    
                // Create event row
                Datetime createdDateTime = event.ActivityDateTime;
                String formattedEvent = 'Record ID: ' + event.Id + ' | Date: ' + createdDateTime.format('yyyy-MM-dd') + ' | Time: ' + createdDateTime.format('HH:mm:ss') + ' | Contacts: ' + (String.isBlank(contactNames) ? 'no contacts related' : contactNames) + ' | Description: ' + sanitizedDescription;
                formattedContent += formattedEvent + '\n';
                }           
            } else {
                formattedContent = 'none\n';
            }
            
            // Prepare the warning message
            String warningMessage = '\nNote: This list is truncated due to character limits.';
            
            // Trim the content if it exceeds the character limit
            if (formattedContent.length() + warningMessage.length() > CONTENT_MAX_LIMIT) {
                formattedContent = formattedContent.substring(0, CONTENT_MAX_LIMIT - warningMessage.length()) + warningMessage;
            }
                    
            // Check if an existing Customer_360__c record exists
            if (existingCustomer360Map.containsKey(account.Id)) {
                Customer_360__c existingRecord = existingCustomer360Map.get(account.Id);
                existingRecord.Content_max_limit__c = formattedContent;
                existingRecord.Timestamp_Content_Generated__c = Datetime.now();
                recordsToUpdate.add(existingRecord);
            } else {
                Customer_360__c newRecord = new Customer_360__c();
                newRecord.Account__c = account.Id;
                newRecord.Type__c = 'Events';
                newRecord.Content_max_limit__c = formattedContent;
                newRecord.Timestamp_Content_Generated__c = Datetime.now();
                recordsToInsert.add(newRecord);
            } 
        }
        
        // Perform separate DML operations
        if (!recordsToInsert.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(recordsToInsert, false);
            for (Database.SaveResult sr : insertResults) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        Logger.finest('Failed to insert record. The error occurred: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }
        
        if (!recordsToUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(recordsToUpdate, false);
			for (Database.SaveResult sr : updateResults) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        Logger.finest('Failed to update record with ID: ' + sr.getId() + '. The error occurred: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }
        Logger.saveLog();
    }  
  
    
   	/**
    @Methodname     : createOpportunitiesRecord
    @Param          : List of Accounts, Account_Summary_Setting__mdt
    @Return         : NULL
    @Description    : To combine lost opps within defined limit into a Customer 360 'Lost Opps' record
	**/
    private static void createOpportunitiesRecord(List<Account> accounts, Account_Summary_Setting__mdt oppSetting) {
        
        // Define date range filters
        Integer pastMonths = (oppSetting != null && oppSetting.Past_Months_Limit__c != null) ? oppSetting.Past_Months_Limit__c.intValue() : 0;
        Date taskStartDateLimit = Date.today().addMonths(-pastMonths);
        
        // Collect all account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Account account : accounts) {
            accountIds.add(account.Id);
        }

        // Query Closed Lost Opportunities
        List<Opportunity> allLostOpps = [SELECT Id, dateTimestampClosedWonLost__c, plLossReason__c, Loss_Reason_Detail__c, AccountId 
                                      FROM Opportunity 
                                      WHERE StageName = 'Closed Lost' AND AccountId = :accountIds 
                                      AND dateTimestampClosedWonLost__c >= :taskStartDateLimit];
        
        // Group Opps by AccountId
        Map<Id, List<Opportunity>> accountToOpps = new Map<Id, List<Opportunity>>();
        for (Opportunity opp : allLostOpps){
            if (!accountToOpps.containsKey(opp.AccountId)){
                accountToOpps.put(opp.AccountId, new List<Opportunity>());
            }
            accountToOpps.get(opp.AccountId).add(opp);
        }

        // Query Customer_360__c records
        List<Customer_360__c> existingCustomer360Records = [SELECT Id, Account__c, Content_max_limit__c 
                                                            FROM Customer_360__c 
                                                            WHERE Account__c IN :accountIds AND Type__c = 'Lost Opps'];
        Map<Id, Customer_360__c> existingCustomer360Map = new Map<Id, Customer_360__c>();
        for (Customer_360__c record : existingCustomer360Records) {
            existingCustomer360Map.put(record.Account__c, record);
        }
        
        // Loop accounts and prepare Customer_360__c records
        List<Customer_360__c> recordsToInsert = new List<Customer_360__c>();
    	List<Customer_360__c> recordsToUpdate = new List<Customer_360__c>();

        for (Account account : accounts){
            List<Opportunity> lostOpps = accountToOpps.get(account.Id);
            // Format the opportunities into a string
            String formattedOpps = '';
            if (lostOpps != null && !lostOpps.isEmpty()) {
                for (Opportunity opp : lostOpps) {
                    formattedOpps += 'Record ID: ' + opp.ID + ' | Close Date: ' + opp.dateTimestampClosedWonLost__c.format() + ' | Loss Reason: ' + opp.plLossReason__c + ' | Loss Reason Details: ' + opp.Loss_Reason_Detail__c + '\n';
                }
            } else {
                formattedOpps += 'none\n';
            }
            
            // Check if an existing Customer_360__c record exists
            if (existingCustomer360Map.containsKey(account.Id)){
                Customer_360__c existingRecord = existingCustomer360Map.get(account.Id);
                existingRecord.Content_max_limit__c = formattedOpps;
                existingRecord.Timestamp_Content_Generated__c = Datetime.now();
            	recordsToUpdate.add(existingRecord);
            } else {
                Customer_360__c newRecord = new Customer_360__c();
            	newRecord.Account__c = account.Id;
                newRecord.Type__c = 'Lost Opps';
                newRecord.Content_max_limit__c = formattedOpps;
                newRecord.Timestamp_Content_Generated__c = Datetime.now();
            	recordsToInsert.add(newRecord);
            }
        }
        
       	// Perform separate DML operations
        if (!recordsToInsert.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(recordsToInsert, false);
            for (Database.SaveResult sr : insertResults) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        Logger.finest('Failed to insert record. The error occurred: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }
        
        if (!recordsToUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(recordsToUpdate, false);
			for (Database.SaveResult sr : updateResults) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        Logger.finest('Failed to update record with ID: ' + sr.getId() + '. The error occurred: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }
        Logger.saveLog();
                
    }
}