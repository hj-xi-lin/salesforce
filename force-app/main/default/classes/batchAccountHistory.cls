/*
 *      @author 		Lisa Müller
 *      @date   		2025-03-03
 *      @description   	batch class to migrate latest modified note into account documentation record
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */

public class batchAccountHistory implements Database.Batchable<SObject>, Database.Stateful {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        
        // Query accounts with Helper Field = 'Pending'
        return Database.getQueryLocator([
            SELECT Id, Active_Account_Documentation__c, A_B_Test_Marker_Account__c, Test_Account__c
            FROM Account
            WHERE A_B_Test_Marker_Account__c = 'Pending' 
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Account> scope) {
        
        // Map to hold ContentDocumentId to AccountId (LinkedEntityId) mapping
        Map<Id, Id> contentDocToAccountMap = new Map<Id, Id>();
        // Map to hold AccountId and corresponding latest ContentNote
        Map<Id, ContentNote> accountNoteMap = new Map<Id, ContentNote>();
        

        // Collect Account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : scope) {
            accountIds.add(acc.Id);
        }
        System.debug('Account IDs: ' + accountIds);

        // Query ContentDocumentLinks to get ContentDocumentIds associated with Accounts
        List<ContentDocumentLink> docLinks = [
            SELECT ContentDocumentId, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId IN :accountIds
        ];
        System.debug('ContentDocumentLinks: ' + docLinks);
        
        // Collect ContentDocumentIds and create the map with AccountId
        Set<Id> contentDocIds = new Set<Id>();
        for (ContentDocumentLink link : docLinks) {
            contentDocIds.add(link.ContentDocumentId);
            contentDocToAccountMap.put(link.ContentDocumentId, link.LinkedEntityId);
        }
        System.debug('ContentDocument IDs: ' + contentDocIds);

        // Query ContentNotes using ContentDocumentIds
        List<ContentNote> notes = [
            SELECT Id, Content, LastModifiedDate 
            FROM ContentNote 
            WHERE Id IN :contentDocIds
            AND LastModifiedDate = LAST_N_DAYS:730
            AND Title != 'Onboarding Comment'
            AND (NOT Title LIKE '%Onboarding Note%')
            ORDER BY LastModifiedDate DESC
        ];
        System.debug('ContentNotes: ' + notes);

        // Map the latest note to each account
        for (ContentNote note : notes) {
            Id accountId = contentDocToAccountMap.get(note.Id);
            if (accountId != null && !accountNoteMap.containsKey(accountId)) {
                accountNoteMap.put(accountId, note);
            }
        }

        List<Customer_360__c> documentationList = new List<Customer_360__c>();
        // Map to track which account should be updated with which documentation ID
        Map<Id, Id> accountToDocumentationMap = new Map<Id, Id>();

        // Process each account and create Customer_360__c records
        for (Account acc : scope) {
            ContentNote latestNote = accountNoteMap.get(acc.Id);
            if (latestNote != null) {
                Customer_360__c documentation = new Customer_360__c();
                documentation.Account__c = acc.Id;
                documentation.Active_Account_Documentation__c = true;
                documentation.Type__c = 'Account Documentation';
                String noteContent = stripHtmlTags(latestNote.Content.toString());
				String additionalInfo = '\n\n-------------\n' +
                        'This account documentation was automatically created from the last modified Note. Note Last Modified Date: ' + 
                        latestNote.LastModifiedDate.format();
						documentation.Content__c = noteContent + additionalInfo;
				documentation.Content__c = noteContent + additionalInfo;
                documentationList.add(documentation);
            }else {
                // Update the account's Helper field to indicate no note was found
                acc.A_B_Test_Marker_Account__c = 'Done (no Note)';
            }
        }

        // Insert new Customer_360__c records
        if (!documentationList.isEmpty()) {
            Database.insert(documentationList, false);
            // Map the inserted documentation records to their accounts
            for (Customer_360__c doc : documentationList) {
                accountToDocumentationMap.put(doc.Account__c, doc.Id);
            }
        }

      	// Update accounts
        for (Account acc : scope) {
            if (accountToDocumentationMap.containsKey(acc.Id)) {
                acc.Active_Account_Documentation__c = accountToDocumentationMap.get(acc.Id);
                acc.A_B_Test_Marker_Account__c = 'Done';
            }
        }
        Database.update(scope, false);
    }

    public void finish(Database.BatchableContext BC) {
    }


public static String stripHtmlTags(String html) {
    
        if (html == null) return '';
        
        // Convert <li> tags to bullet points
        String plainText = html.replaceAll('<li\\s*/?>', '\n- ');
        
        // Convert <br> and <p> tags to newlines
        plainText = plainText.replaceAll('<br\\s*/?>|<p\\s*/?>', '\n');
        
        // Remove all other HTML tags
        plainText = plainText.replaceAll('<[^>]+>', '');
        
        return plainText.trim(); // Remove leading/trailing whitespace
}

}