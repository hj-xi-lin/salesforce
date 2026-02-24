public class quoteStageChangeController {
    @AuraEnabled
    public static boolean getOwner(string quoteID){
        boolean openModal = false;
        quote quoteRecord = [select id,Owner.profileId,Automatic_Quote_E_Mail__c,Contact.email,Offer_Sent__c from quote where id =: quoteID];
        system.debug('quoteRecord::'+quoteRecord);
         if(!Test.isRunningTest()){
       		 string name = [select id,name from profile where id=: quoteRecord.owner.profileId].name;
             
            if(name.contains('Enterprise') && quoteRecord.Automatic_Quote_E_Mail__c && quoteRecord.Contact.email != null && !quoteRecord.Offer_Sent__c){
                openModal = true;
            }
         }
        return openModal;
    }
    
    @AuraEnabled
    public static void sendDocumentsToEmail(string quoteID){
        
        quote quoteRecord = [select id,name,Contactid,Contact.email,Accountid,OpportunityId from quote where id =: quoteID];
        system.debug('quoteRecord::'+quoteRecord);
        
        opportunity oppRecord = [select id,name,Owner.Email from Opportunity where id =: quoteRecord.OpportunityId];
        system.debug('oppRecord::'+oppRecord);
        
        Set<String> contentDocumentIds = new Set<String>(); 
        List<ContentDocumentLink> cdls = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :quoteID]; 
        for (ContentDocumentLink doc : cdls) { 
            contentDocumentIds.add(doc.ContentDocumentId); 
        } 
        // Get Email Template 
        Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'QuoteSendEmail'].Id; 
        // New email message 
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(templateId, null, quoteRecord.Accountid); 
        // Set Email Properties 
        mail.toAddresses = new String[]{quoteRecord.Contact.email}; 
        mail.ccaddresses = new string[]{oppRecord.Owner.Email};
        mail.setTargetObjectId(quoteRecord.contactId); 
        mail.setWhatId(quoteRecord.AccountId); 
        mail.setTreatTargetObjectAsRecipient(false); 
        mail.setTreatBodiesAsTemplate(true); 
        
        List<ContentVersion> contentVersionFile = [SELECT VersionData, Title, FileType FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds AND IsLatest = true]; 
        List<Messaging.EmailFileAttachment> emailFileAttachments = new List<Messaging.EmailFileAttachment>(); 
        for (ContentVersion cv : contentVersionFile) { 
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment(); 
            efa.setFileName(cv.Title + '.' + cv.FileType); 
            efa.setBody(cv.VersionData); 
            emailFileAttachments.add(efa); 
        }  
        if (!emailFileAttachments.isEmpty()) {
            mail.setFileAttachments(emailFileAttachments); 
        } 
        system.debug('mail::'+mail);
        // Send Email 
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{mail}; 
            
            	Messaging.SendEmailResult[] results = Messaging.sendEmail(messages); 
              
        if (results[0].success) { 
            System.debug('The email was sent successfully.'+results[0]); 
            Quote qu = new Quote();
            qu.Id = quoteID;
            qu.Offer_Sent__c = true;
            update qu;
        } 
                  
        else{ 
            System.debug('The email failed to send: ' + results[0].errors[0].message); 
        } 
              
    }
    
    @AuraEnabled
    public static void changeStage(string quoteID){
        Quote qu = new Quote();
        qu.Id = quoteID;
        qu.Status = 'Draft';
        update qu;
    }
}